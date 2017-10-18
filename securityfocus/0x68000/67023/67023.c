#include <stdio.h>
#include <strings.h>
#include <sys/shm.h>

int main(int argc, char *argv[])
{
  int shm = shmget( IPC_PRIVATE, 0x1337, SHM_R | SHM_W );

  if (shm < 0)
    {
      printf("shmget: failed");
      return 6;
    }

  struct shmid_ds lolz;

  int res = shmctl( shm, IPC_STAT, &lolz );
  if (res < 0)
    {
      printf("shmctl: failed");
      return 1;
    }

  printf( "%p\n", lolz.shm_internal );

}
