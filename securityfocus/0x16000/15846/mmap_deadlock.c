#define _GNU_SOURCE
#define __USE_FILE_OFFSET64
#include <stdio.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#define FILENAME "/tmp/bigfile"

int main(int argc, char **argv)
{
	int fd, fd1, ret;
	char *buf;
	char wbuf[8192];
	unsigned long long offset = 0xffffff000ULL;
	char *p=wbuf;

	fd = open(FILENAME, O_RDWR|O_CREAT|O_LARGEFILE/*|O_TRUNC*/, 0644);
	if (fd < 0) {
		perror(FILENAME);
		return -1;
	}

	ftruncate64(fd, offset + 4096*4);
	buf = mmap64(NULL, 4096*4, PROT_READ|PROT_WRITE, MAP_SHARED, fd, offset);
	if (buf == MAP_FAILED) {
		perror("mmap");
		return -1;
	}

	fd1 = open(FILENAME, O_RDWR|O_DIRECT|O_LARGEFILE, 0644);
	if (fd < 0) {
		perror(FILENAME);
		return -1;
	}

	p = (char *)((unsigned long) p | 4095)+1;


	if (fork()) {
		while(1) {
			/* map in the page */
			buf[10] = 1;
		}
	} else {
		ret = pwrite64(fd1, p, 4096, offset);
		if (ret < 4096) {
			printf("write: %d %p\n", ret, p);
			perror("write");
			return -1;
		}
	}

	return 0;
}


