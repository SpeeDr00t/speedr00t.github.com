mac-cxs-XK:pochd XK$ cat test.c
#include <stdio.h>
#include <unistd.h>

void usage(const char* program)
{
const char* message = " [src_dir] [target_dir]";
fprintf(stderr, "%s%s\n", program, message);
}

int main(int argc, char* argv[]) {
if (argc!=3) {
usage(argv[0]);
return 1;
}

int ret = link(argv[1],argv[2]);

fprintf(stderr,"link(3) return= %d\n", ret);

return ret;
}

mac-cxs-XK:pochd XK$ gcc -o test test.c
mac-cxs-XK:pochd XK$ ls
test test.c
mac-cxs-XK:pochd XK$ mkdir DIR1
mac-cxs-XK:pochd XK$ ./test DIR1 Hardlink1
link(3) return= -1
mac-cxs-XK:pochd XK$ mkdir DIR1/DIR2
mac-cxs-XK:pochd XK$ ./test DIR1/DIR2 Hardlink2
link(3) return= 0
mac-cxs-XK:pochd XK$ cd DIR1
mac-cxs-XK:DIR1 XK$ mkdir DIR2/DIR3
mac-cxs-XK:DIR1 XK$ ../test DIR2/DIR3 Hardlink3
link(3) return= 0
mac-cxs-XK:DIR1 XK$ cd DIR2
mac-cxs-XK:DIR2 XK$ mkdir DIR3/DIR4
mac-cxs-XK:DIR2 XK$ ../../test DIR3/DIR4 Hardlink4
link(3) return= -1
