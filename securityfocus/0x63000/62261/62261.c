#include <windows.h>

#define DLL_EXPORT __declspec(dllexport)

#ifdef __cplusplus
extern "C"
{
#endif

void DLL_EXPORT wgpr_library_get()
{
    WinExec("calc",0);
}

#ifdef __cplusplus
}
#endif

