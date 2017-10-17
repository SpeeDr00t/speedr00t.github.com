#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <locale.h>

#define LEN 500000 

int main() {

char *ptr1 = malloc(LEN + 1);
char *ptr2 = malloc(LEN + 1);
char *wasted = NULL;
int i = 0, ret = 0;

if(!ptr1 || !ptr2) {
    printf("memory allocation failed\n");
    return -1;
}

memset(ptr1, 0x61, LEN);
memset(ptr2, 0x61, LEN); 

ptr1[LEN] = 0;
ptr2[LEN] = 0;

printf("strings allocated\n");

char *ptr = setlocale(LC_ALL, "en_US.UTF-8");
if(!ptr) {
    printf("error setting locale\n");
    return -1;
}

/* malloc() big chunks until we're out of memory */
do {    
wasted = malloc(1000000);
printf("%p\n", wasted);
i++;
} while(wasted);

ret = strcoll(ptr1, ptr2);

if(!ret) {
    printf("strings were lexicographically identical\n");
}

else {
    printf("strings were different\n");
}

return 0;
}