#!/usr/bin/python
import socket
import sys

def Usage():
    print ("Usage:  ./expl.py <serv_ip>      <Username> <password>\n")
    print ("Example:./expl.py 192.168.48.183 anonymous anonymous\n")
if len(sys.argv) <> 4:
        Usage()
        sys.exit(1)
else:
    hostname=sys.argv[1]
    username=sys.argv[2]
    passwd=sys.argv[3]
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        sock.connect((hostname, 21))
    except:
        print ("Connection error!")
        sys.exit(1)
    r=sock.recv(1024)
    sock.send("user %s\r\n" %username)
    r=sock.recv(1024)
    sock.send("pass %s\r\n" %passwd)
    r=sock.recv(1024)
    sock.send("LIST\r\n")
    sock.close()
    sys.exit(0);
