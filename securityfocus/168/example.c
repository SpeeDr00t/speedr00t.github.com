#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <fcntl.h>
#include <unistd.h>

#define PATH "/tmp/123"
#define PATH_TMP "/tmp/123.tmp"
#define SOME_FILE "/etc/passwd"

struct mycmsghdr {
	struct cmsghdr hdr;
	int	fd;
};

extern errno;

void server();
void client();

void main()
{
	switch ( fork()) {
	case -1:
		printf( "fork error %d\n",errno);
		break;
	case 0:
		for (;;) client();
	default:
		server();
	}
}

void server()
{
	struct sockaddr_un addr;
	struct msghdr mymsghdr;
	struct mycmsghdr ancdbuf;
	char 	data[ 1];
	int	sockfd,
		len,
		fd;

	if ( unlink( PATH) == -1)
		printf( "unlink error %d\n",errno);

	if (( sockfd = socket( AF_UNIX,SOCK_DGRAM,0)) == -1)
		printf( "socket error %d\n",errno);

	strcpy( addr.sun_path,PATH);
	addr.sun_len = sizeof( addr.sun_len) + sizeof( addr.sun_family) 
			+ strlen( addr.sun_path); 
	addr.sun_family = AF_UNIX;

	if ( bind( sockfd,(struct sockaddr *) &addr,addr.sun_len) == -1)
		printf( "bind error %d\n",errno);

	for (;;) {

		if (( fd = open( SOME_FILE,O_RDONLY)) == -1) 
			printf( "open file error %d\n",errno);

		len = sizeof( addr.sun_path);

		if ( recvfrom( sockfd,&data,sizeof( data),0,
			(struct sockaddr *) &addr,&len) == -1) 
			printf( "recvfrom error %d\n",errno);

		ancdbuf.hdr.cmsg_len = sizeof( ancdbuf);
		ancdbuf.hdr.cmsg_level = SOL_SOCKET;
		ancdbuf.hdr.cmsg_type = SCM_RIGHTS;
		ancdbuf.fd = fd;

		mymsghdr.msg_name = (caddr_t) &addr;
		mymsghdr.msg_namelen = len;
		mymsghdr.msg_iov = NULL;
		mymsghdr.msg_iovlen = 0;
		mymsghdr.msg_control = (caddr_t) &ancdbuf;
		mymsghdr.msg_controllen = ancdbuf.hdr.cmsg_len;
		mymsghdr.msg_flags = 0;
		
		if ( sendmsg( sockfd,&mymsghdr,0) == -1) 
			printf( "sendmsg error %d\n",errno);

		close( fd);
	}
}

void client()
{
	struct sockaddr_un	addr_s,
				addr_c;
	struct mycmsghdr	ancdbuf;
	struct msghdr		mymsghdr;
	char 	data[ 1];
	int	sockfd,
		len,
		fd;

	if (( sockfd = socket( AF_UNIX,SOCK_DGRAM,0)) == -1) 
		printf( "socket error %d\n",errno);

	if ( unlink( PATH_TMP) == -1)
		printf( "unlink error %d\n",errno);

	strcpy( addr_c.sun_path,PATH_TMP);
	addr_c.sun_len = sizeof( addr_c.sun_len) + sizeof(addr_c.sun_family) 
			  + strlen( addr_c.sun_path);
	addr_c.sun_family = AF_UNIX;

	strcpy( addr_s.sun_path,PATH);
	addr_s.sun_len = sizeof( addr_s.sun_len) + sizeof(addr_s.sun_family)
		           + strlen( addr_s.sun_path);
	addr_s.sun_family = AF_UNIX;

	if ( bind( sockfd,(struct sockaddr*) &addr_c,addr_c.sun_len) == -1)
		printf( "bind error %d\n",errno);

	if ( sendto( sockfd,&data,sizeof( data),0,(struct sockaddr *) &addr_s,
		addr_s.sun_len) == -1) 
		printf( "sendto error %d\n",errno);

	len = addr_s.sun_len;

	ancdbuf.hdr.cmsg_len = sizeof( ancdbuf);
	ancdbuf.hdr.cmsg_level = SOL_SOCKET;
	ancdbuf.hdr.cmsg_type = SCM_RIGHTS;

	mymsghdr.msg_name = NULL;
	mymsghdr.msg_namelen = 0;
	mymsghdr.msg_iov = NULL;
	mymsghdr.msg_iovlen = 0;
	mymsghdr.msg_control = (caddr_t) &ancdbuf;
	mymsghdr.msg_controllen = ancdbuf.hdr.cmsg_len;
	mymsghdr.msg_flags = 0;

	if ( recvmsg( sockfd,&mymsghdr,0) == -1)
		printf( "recvmsg error %d\n",errno);

	fd = ancdbuf.fd;
	
	close(fd);
	close( sockfd);
}
