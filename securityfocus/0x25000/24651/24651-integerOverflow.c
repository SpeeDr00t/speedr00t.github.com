#include "gd.h"

int main() {
    FILE *fp = fopen("./x.xbm", "w+");

    fprintf(fp, "#define width 255\n#define height 1073741824\nstatic unsigned char bla = {\n");

    fseek(fp, 0, SEEK_SET);

    gdImageCreateFromXbm(fp);

}
