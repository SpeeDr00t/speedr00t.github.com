#!/usr/bin/python
 
filename="string.txt"
buffer = "\x41" * 1000
textfile = open(filename , 'w')
textfile.write(buffer)
textfile.close()

