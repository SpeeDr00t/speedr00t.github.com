<?php
$x = '0fffffffe

XXX';
file_put_contents("file:///tmp/test.dat",$x);
$y = file_get_contents('php://filter/read=dechunk/resource=file:///tmp/test.dat');
echo "here";
?>
